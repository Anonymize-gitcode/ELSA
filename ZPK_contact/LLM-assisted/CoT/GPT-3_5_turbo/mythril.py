import os
import re
import json
import openai  # For calling GPT
from collections import Counter
import time

# Configure GPT-3.5 API key
openai.api_key = ('...')  # Replace with your GPT API key

# Read mythril result from specified folder, try to parse as text or JSON
def clean_mythril_output(mythril_content):
    mythril_content = re.sub(r'//.*', '', mythril_content)
    mythril_content = re.sub(r'/\*.*?\*/', '', mythril_content, flags=re.DOTALL)
    mythril_content = re.sub(r'\n\s*\n', '\n', mythril_content)
    return mythril_content

def read_mythril_result(result_file_path):
    result_file_path = os.path.normpath(result_file_path)

    if not os.path.exists(result_file_path):
        print(f"Result file not found: {result_file_path}, treated as empty file.")
        return None

    with open(result_file_path, 'r', encoding='latin-1') as file:
        content = file.read().strip()
        if not content:
            print(f"File {result_file_path} is empty.")
            return None

        try:
            mythril_output = json.loads(content)
            return mythril_output
        except json.JSONDecodeError:
            print(f"File {result_file_path} is not a valid JSON file, returning cleaned text content.")
            return clean_mythril_output(content)

def clean_solidity_comments(solidity_content):
    solidity_content = re.sub(r'//.*', '', solidity_content)
    solidity_content = re.sub(r'/\*.*?\*/', '', solidity_content, flags=re.DOTALL)
    solidity_content = re.sub(r'\n\s*\n', '\n', solidity_content)
    return solidity_content

def find_contract_structure_file(sol_file_name, solc_analysis_dir):
    for root, _, files in os.walk(solc_analysis_dir):
        for file in files:
            txt_file_name = os.path.splitext(file)[0]
            if sol_file_name in txt_file_name and file.endswith(".txt"):
                return os.path.join(root, file)
    return None

def analyze_contract_structure_from_txt(sol_file_name, solc_analysis_dir):
    solc_analysis_path = find_contract_structure_file(sol_file_name, solc_analysis_dir)
    if solc_analysis_path and os.path.exists(solc_analysis_path):
        with open(solc_analysis_path, 'r', encoding='utf-8') as file:
            content = file.read().strip()
            if content:
                return content
            else:
                print(f"File {solc_analysis_path} is empty.")
    else:
        print(f"Contract structure file not found: {solc_analysis_path}")
    return None

# Send full text directly to GPT
def send_full_text_to_gpt(prompt, model="gpt-3.5-turbo"):
    try:
        response = openai.ChatCompletion.create(
            model=model,
            messages=[{"role": "user", "content": prompt}]
        )
        return response['choices'][0]['message']['content'].strip()
    except openai.error.OpenAIError as e:
        print(f"Failed to call GPT API: {e}")
        return None

# Use GPT to analyze common vulnerabilities
def analyze_common_vulnerabilities_with_gpt(mythril_output, solidity_content, structure_hint, sol_file_name):
    swc_codes = set()
    mythril_output_str = json.dumps(mythril_output, indent=2) if isinstance(mythril_output, dict) else mythril_output
    zkp_model_content = read_zkp_analysis_file(sol_file_name)
    key_feature_content = read_key_feature_file(sol_file_name)

    length_threshold = 12000
    print(sol_file_name)
    if len(solidity_content) > length_threshold:
        print(f"Solidity code exceeds {length_threshold} characters, optimizing.")
        file_path = os.path.abspath(os.path.join(os.path.dirname(__file__), f'../../../../datasets/ZPK_contact_compress/{sol_file_name}.sol'))
        print(file_path)
        if os.path.exists(file_path):
            try:
                with open(file_path, 'r', encoding='utf-8') as file:
                    solidity_content_vector = file.read()
                    print(f"Successfully read content of file {sol_file_name}.")
            except Exception as e:
                print(f"Error reading file {sol_file_name}: {e}")
                solidity_content_vector = "Error reading file, analysis cannot continue."
        else:
            print(f"File {sol_file_name} does not exist, cannot read.")
            solidity_content_vector = "Specified Solidity file does not exist, analysis cannot continue."

        solidity_response = solidity_content_vector

    else:
        print(f"Solidity code length does not exceed {length_threshold} characters, no optimization needed.")
        solidity_response = solidity_content

    prompt_for_inspiration = (
        f"Based on the following Solidity file, summarize accurate and effective prompts from the three hints below to inspire GPT analysis. "
        f"Remove vulnerabilities that are not present in the Solidity file.\n"
        f"Return the names of high-risk functions and the problem.\n"
        f"Contract structure hints:\n{structure_hint}\n"
        f"Potential risk hints:\n{key_feature_content}\n"
        f"Analysis hints:\n{zkp_model_content}\n"
        f"Solidity file content:\n{solidity_response}\n\n"
    )

    inspiration_response = send_full_text_to_gpt(prompt_for_inspiration)
    print(inspiration_response)
    if inspiration_response:
        print(re.findall(r'SWC-(\d+): Vulnerability line number: (\d+)', inspiration_response))
    else:
        print("No summary hint obtained.")

    prompt_for_analysis = (
        f"Please analyze vulnerabilities in the following Solidity file, using risk function clues from the inspiration hints. Return the highest risk vulnerability type.\n"
        f"Summarize and confirm existing SWC code vulnerabilities. Do not provide fix suggestions or detection ranges. Ensure the vulnerabilities exist.\n\n"
        f"Detection range: 'SWC-101':'Integer_Overflow_and_Underflow', "
        f"'SWC-105':'Unprotected_Ether_Withdrawal', "
        f"'SWC-107':'Reentrancy', "
        f"'SWC-110':'Assert_Violation', "
        f"'SWC-121':'Missing_Protection_Against_Signature_Replay_Attacks', "
        f"'SWC-124':'Write_to_Arbitrary_Storage_Location', "
        f"'SWC-128':'DoS_with_Block_Gas_Limit_Gas'.\n"
        f"Analysis steps:\n"
        f"1. Check each function and identify potential vulnerabilities, focusing on permission control, arithmetic operations, external calls, etc.\n"
        f"2. Ensure the SWC codes are accurate and indicate the specific function or code segment.\n\n"
        f"Contract structure hints:\n{structure_hint}\n"
        f"Solidity file content:\n{solidity_response}\n\n"
        f"Mythril output:\n{mythril_output_str}\n\n"
        f"Inspiration hints:\n{inspiration_response}\n\n"
        f"Return format:\n"
        f"[SWC code]: Vulnerability line: [specific line], brief description\n"
        f"Example output: SWC-101: Vulnerability line: 52 \n SWC-107: Not found\n"
    )

    gpt_response = send_full_text_to_gpt(prompt_for_analysis)
    print(gpt_response)

    vulnerabilities = []
    if isinstance(gpt_response, str):
        matches = re.findall(r'SWC-(\d+): Vulnerability line number: (\d)', gpt_response)
        for match in matches:
            swc_code = match[0].strip()
            line_number = match[1].strip()
            vulnerabilities.append((swc_code, line_number))
        swc_codes = set(re.findall(r'SWC-\d+', gpt_response))
    else:
        print("GPT response is not a valid string.")

    return set([f"SWC-{code}" for code in swc_codes]), solidity_response

def read_zkp_analysis_file(sol_file_name):
    zkp_model_file_path = os.path.abspath(os.path.join(os.path.dirname(__file__), f'../../../../result/ZKP_LLAMA_filter/{sol_file_name}.sol_zkp_analysis.txt'))
    if os.path.exists(zkp_model_file_path):
        with open(zkp_model_file_path, 'r', encoding='utf-8') as zkp_file:
            return zkp_file.read().strip()
    else:
        print(f"Warning: ZKP model analysis hint file not found: {zkp_model_file_path}")
        return ""

def read_key_feature_file(sol_file_name):
    key_feature_file_path = os.path.abspath(os.path.join(os.path.dirname(__file__), f'../../../../result/key_feature_extract/combine/{sol_file_name}.sol.txt'))
    if os.path.exists(key_feature_file_path):
        with open(key_feature_file_path, 'r', encoding='utf-8') as feature_file:
            return feature_file.read().strip()
    else:
        print(f"Warning: Key feature extraction file not found: {key_feature_file_path}")
        return ""

# Analyze symbolic execution results of smart contracts
def simulate_symbolic_execution_with_gpt(mythril_output, solidity_content, vulnerabilities_found, structure_hint, solidity_response):
    swc_codes = set()
    mythril_output_str = json.dumps(mythril_output, indent=2) if isinstance(mythril_output, dict) else mythril_output
    print(vulnerabilities_found)

    prompt = (
        f"Based on the logic of symbolic execution tools, and combining the following Solidity code and discovered vulnerabilities, return the highest-risk vulnerability type. "
        f"Simulate execution paths of the smart contract under different inputs, inspect potential execution risks, and verify the validity of discovered vulnerabilities. "
        f"Remove vulnerabilities that do not actually exist.\n"
        f"Discovered vulnerabilities: {','.join(vulnerabilities_found)}\n"
        f"Detection range: 'SWC-101':'Integer_Overflow_and_Underflow', "
        f"'SWC-105':'Unprotected_Ether_Withdrawal', "
        f"'SWC-107':'Reentrancy', "
        f"'SWC-110':'Assert_Violation', "
        f"'SWC-121':'Missing_Protection_Against_Signature_Replay_Attacks', "
        f"'SWC-124':'Write_to_Arbitrary_Storage_Location', "
        f"'SWC-128':'DoS_with_Block_Gas_Limit_Gas'.\n"
        f"Return format:\n"
        f"[SWC code]: Vulnerability line: [specific line], brief description\n"
        f"Example output: SWC-101: Vulnerability line: 52 \n SWC-107: Not found\n"
        f"Solidity code:\n{solidity_response}\n"
        f"Contract structure hints:\n{structure_hint}\n"
        f"Please identify any potential vulnerabilities and return the corresponding SWC code list."
    )

    gpt_response = send_full_text_to_gpt(prompt)
    print(gpt_response)

    vulnerabilities = []
    if isinstance(gpt_response, str):
        matches = re.findall(r'SWC-(\d+): Vulnerability line number:: (\d)', gpt_response)
        for match in matches:
            swc_code = match[0].strip()
            line_number = match[1].strip()
            vulnerabilities.append((swc_code, line_number))
        swc_codes = set(re.findall(r'SWC-\d+', gpt_response))
    else:
        print("GPT response is not a valid string.")

    return set([f"SWC-{code}" for code in swc_codes])

def analyze_with_gpt_in_three_rounds(mythril_output, solidity_content, structure_hint, sol_file_name):
    round_results = []
    for _ in range(3):
        vulnerabilities_result, solidity_response = analyze_common_vulnerabilities_with_gpt(mythril_output, solidity_content, structure_hint, sol_file_name)
        execution_result = simulate_symbolic_execution_with_gpt(mythril_output, solidity_content, vulnerabilities_result, sol_file_name, solidity_response)
        combined_result = execution_result
        round_results.append(combined_result)
    return round_results

def analyze_with_gpt_until_intersection(mythril_output, solidity_content, structure_hint, sol_file_name, max_attempts=5):
    attempt = 0
    all_swc_codes = []
    intersection_result = None

    while attempt < max_attempts:
        attempt += 1
        print(f"Analysis round {attempt}")
        current_round_results = analyze_with_gpt_in_three_rounds(mythril_output, solidity_content, structure_hint, sol_file_name)
        for result_set in current_round_results:
            all_swc_codes.extend(result_set)
        current_intersection = set.intersection(*current_round_results)
        if attempt == 1:
            intersection_result = current_intersection
        else:
            intersection_result = intersection_result.intersection(current_intersection)
        if intersection_result:
            return intersection_result

    if all_swc_codes:
        result_counts = Counter(all_swc_codes)
        most_common_result = result_counts.most_common(1)
        return {most_common_result[0][0]}
    else:
        print("No valid results found.")
        return set()

def save_analysis_result(contract_name, swc_codes, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    result_file_path = os.path.join(output_dir, f"{contract_name}_gpt_analysis.txt")

    if os.path.exists(result_file_path):
        print(f"Skipping contract {contract_name}, result file already exists.")
        return

    with open(result_file_path, 'w', encoding='utf-8') as result_file:
        if swc_codes:
            result_file.write(f"Contract {contract_name} detected SWC codes: {', '.join(swc_codes)}\n")
        else:
            result_file.write(f"Contract {contract_name} found no intersection or valid results.\n")

    print(f"Analysis result saved to: {result_file_path}")

def analyze_mythril_results_in_directory(sol_base_dir, mythril_base_dir, solc_analysis_dir, result_dir):
    if not os.path.exists(sol_base_dir):
        print(f"Specified directory does not exist: {sol_base_dir}")
        return

    total_files = 0
    total_time = 0.0

    for root, _, files in os.walk(sol_base_dir):
        for file in files:
            if file.endswith('.sol'):
                total_files += 1
                sol_file_name = os.path.splitext(file)[0]
                sol_file_path = os.path.join(root, file)

                result_file_path = os.path.join(result_dir, f"{sol_file_name}_gpt_analysis.txt")

                if os.path.exists(result_file_path):
                    print(f"Skipping contract {sol_file_name}, result file already exists.")
                    continue

                corresponding_json_path = os.path.join(
                    mythril_base_dir,
                    os.path.relpath(root, sol_base_dir),
                    f"{sol_file_name}.sol.txt"
                )
                corresponding_json_path = os.path.normpath(corresponding_json_path)

                print(f"Analyzing contract: {sol_file_name}")
                print(f"Analyzing file path: {corresponding_json_path}")

                mythril_output = read_mythril_result(corresponding_json_path)

                if mythril_output is None:
                    print(f"Skipping contract {sol_file_name}, could not read mythril result.")
                    continue

                structure_hint = analyze_contract_structure_from_txt(sol_file_name, solc_analysis_dir)
                if structure_hint is None:
                    print(f"Skipping contract {sol_file_name}, structure hint not found.")
                    continue

                start_time = time.time()

                with open(sol_file_path, 'r', encoding='utf-8') as sol_file:
                    solidity_content = clean_solidity_comments(sol_file.read())

                swc_codes = analyze_with_gpt_until_intersection(mythril_output, solidity_content, structure_hint, sol_file_name)

                elapsed_time = time.time() - start_time
                total_time += elapsed_time

                print(f"Contract {sol_file_name} analysis time: {elapsed_time:.2f} seconds")

                save_analysis_result(sol_file_name, swc_codes, result_dir)

    if total_files > 0:
        avg_time_per_file = total_time / total_files
        print(f"Average analysis time per file: {avg_time_per_file:.2f} seconds")
    print(f"Total analysis time for all files: {total_time:.2f} seconds")

def main():
    sol_base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../datasets/ZPK_contact'))
    mythril_base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/mythril_tool_analysis_filter'))
    solc_analysis_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/solc-process'))
    result_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/mythril_CoT_gpt_3_5_turbo'))
    analyze_mythril_results_in_directory(sol_base_dir, mythril_base_dir, solc_analysis_dir, result_dir)

if __name__ == "__main__":
    main()

