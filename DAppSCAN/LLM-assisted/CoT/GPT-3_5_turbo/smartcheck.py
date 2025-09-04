import os
import re
import json
import openai  # Used for GPT calls
from collections import Counter
import time

# Configure GPT-3.5 API key
openai.api_key = ('...')  # Replace with your GPT API key

# Read smartcheck results from the specified folder and try to parse as text or JSON
def clean_smartcheck_output(smartcheck_content):
    smartcheck_content = re.sub(r'//.*', '', smartcheck_content)
    smartcheck_content = re.sub(r'/\*.*?\*/', '', smartcheck_content, flags=re.DOTALL)
    smartcheck_content = re.sub(r'\n\s*\n', '\n', smartcheck_content)
    return smartcheck_content

def read_smartcheck_result(result_file_path):
    result_file_path = os.path.normpath(result_file_path)

    if not os.path.exists(result_file_path):
        print(f"Result file not found: {result_file_path}, treated as empty.")
        return None

    with open(result_file_path, 'r', encoding='latin-1') as file:
        content = file.read().strip()
        if not content:
            print(f"File {result_file_path} is empty.")
            return None

        try:
            smartcheck_output = json.loads(content)
            return smartcheck_output
        except json.JSONDecodeError:
            print(f"File {result_file_path} is not a valid JSON file, returning cleaned text content.")
            return clean_smartcheck_output(content)

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

# Use GPT for common vulnerability analysis
def analyze_common_vulnerabilities_with_gpt(smartcheck_output, solidity_content, structure_hint, sol_file_name):
    swc_codes = set()

    smartcheck_output_str = json.dumps(smartcheck_output, indent=2) if isinstance(smartcheck_output, dict) else smartcheck_output

    zkp_model_content = read_zkp_analysis_file(sol_file_name)
    solidity_response = set()
    key_feature_content = read_key_feature_file(sol_file_name)
    length_threshold = 13000

    if len(solidity_content) > length_threshold:
        print(f"Solidity code exceeds {length_threshold} characters, optimizing.")
        prompt_for_solidity = (
            f"Please optimize the following Solidity code by removing redundant parts while retaining all functions and code segments related to vulnerabilities to ensure vulnerability analysis is not affected:\n"
            f"Optimization requirements:\n"
            f"1. Remove unused variables, functions, and irrelevant code to avoid affecting vulnerability analysis.\n"
            f"2. Retain all functions potentially related to vulnerabilities, especially those flagged by smartcheck or other tools.\n"
            f"3. Ensure that the core functionality of each function is preserved. The optimized code should retain its functionality and vulnerability analysis consistency.\n\n"
            f"Solidity file content:\n{solidity_content}\n\n"
        )
        try:
            solidity_response = send_full_text_to_gpt(prompt_for_solidity)
        except Exception as e:
            print(f"Error calling GPT: {e}")
            solidity_response = "An error occurred during optimization."
    else:
        print(f"Solidity code length does not exceed {length_threshold} characters, no optimization needed.")
        solidity_response = solidity_content

    prompt_for_inspiration = (
        f"Based on the following Solidity file content, summarize accurate and effective heuristic prompts to help GPT analyze potential vulnerabilities and risks. "
        f"Please remove any vulnerability that does not exist in the Solidity file.\n"
        f"Return format:\n"
        f"[SWC code]: Line number of the vulnerability: [specific line], brief description.\n"
        f"Please check each function carefully, especially focus on:\n"
        f"1. Function control flow and state changes,\n"
        f"2. Data operations and calls,\n"
        f"3. Common vulnerabilities such as reentrancy, arithmetic overflow, permission control.\n"
        f"Contract structure hints:\n{structure_hint}\n"
        f"Key feature hints:\n{key_feature_content}\n"
        f"Analysis hints:\n{zkp_model_content}\n"
        f"Solidity file content:\n{solidity_response}\n\n"
    )

    inspiration_response = send_full_text_to_gpt(prompt_for_inspiration)
    print(inspiration_response)
    if inspiration_response:
        print(re.findall(r'SWC-(\d+)', inspiration_response))
    else:
        print("No heuristic summary obtained.")

    prompt_for_analysis = (
        f"Please analyze the vulnerabilities in the contract from the following Solidity file content and smartcheck output, using the heuristic prompts.\n"
        f"Check each function carefully, ensuring to analyze its functionality and potential risks. Return a precise list of SWC codes without any fix suggestions or scope descriptions.\n\n"
        f"Detection includes the following vulnerabilities:\n"
        f"SWC-135: Code With No Effects\n"
        f"SWC-108: State Variable Default Visibility\n"
        f"SWC-129: Unchecked Call Return Value\n"
        f"SWC-123: Requirement Violation\n"
        f"SWC-100: Uninitialized State Variables\n"
        f"SWC-119: Shadowing State Variables\n"
        f"SWC-102: Unencrypted Private Data On-Chain\n"
        f"SWC-103: Ether Transfer to Unknown Address\n"
        f"SWC-128: DoS With Block Gas Limit\n"
        f"SWC-104: Outdated Compiler Version\n"
        f"SWC-126: Insufficient Gas Griefing\n"
        f"SWC-101: Delegatecall to Untrusted Contract\n"
        f"SWC-118: Incorrect Constructor Name\n"
        f"SWC-105: Unchecked Low-Level Calls\n"
        f"SWC-107: DoS with (Unexpected) Revert\n"
        f"SWC-114: Transaction Order Dependence\n"
        f"SWC-120: Authorization through tx.origin\n"
        f"SWC-111: Use of Deprecated Solidity Functions\n"
        f"SWC-116: Block values as a proxy for time\n"
        f"SWC-113: DoS with Block Gas Limit\n"

        f"Analysis process:\n"
        f"1. Check each function, identify potential vulnerabilities, especially those related to permission control, arithmetic operations, and external calls.\n"
        f"2. Ensure accurate SWC codes and specify the vulnerable function or code segment.\n\n"

        f"Solidity file content:\n{solidity_response}\n\n"
        f"smartcheck output:\n{smartcheck_output_str}\n\n"
        f"Heuristic prompts:\n{inspiration_response}\n\n"
    )

    gpt_response = send_full_text_to_gpt(prompt_for_analysis)
    print(gpt_response)
    if gpt_response:
        swc_codes.update(re.findall(r'SWC-(\d+)', gpt_response))
        print(re.findall(r'SWC-(\d+)', gpt_response))
    else:
        print("No vulnerability analysis result obtained.")

    return set([f"SWC-{code}" for code in swc_codes]), solidity_response

# Read ZKP analysis hint file
def read_zkp_analysis_file(sol_file_name):
    zkp_model_file_path = os.path.abspath(os.path.join(os.path.dirname(__file__), f'../../../../result/ZKP_LLAMA_filter/{sol_file_name}.sol_zkp_analysis.txt'))
    if os.path.exists(zkp_model_file_path):
        with open(zkp_model_file_path, 'r', encoding='utf-8') as zkp_file:
            return zkp_file.read().strip()
    else:
        print(f"Warning: ZKP large model analysis hint file not found: {zkp_model_file_path}")
        return ""

# Read key feature extraction results
def read_key_feature_file(sol_file_name):
    key_feature_file_path = os.path.abspath(os.path.join(os.path.dirname(__file__), f'../../../../result/key_feature_extract/combine/{sol_file_name}.sol.txt'))
    if os.path.exists(key_feature_file_path):
        with open(key_feature_file_path, 'r', encoding='utf-8') as feature_file:
            return feature_file.read().strip()
    else:
        print(f"Warning: Key feature extraction file not found: {key_feature_file_path}")
        return ""

# Analyze symbolic execution results of smart contracts
def simulate_symbolic_execution_with_gpt(smartcheck_output, solidity_content, vulnerabilities_found, sol_file_name,solidity_response):
    swc_codes = set()
    smartcheck_output_str = json.dumps(smartcheck_output, indent=2) if isinstance(smartcheck_output, dict) else smartcheck_output

    prompt = (
        f"Based on symbolic execution logic, combined with the following Solidity code and smartcheck output and known vulnerabilities, "
        f"simulate the execution paths of the smart contract under different inputs, check for potential execution risks, and verify the authenticity of discovered vulnerabilities. Remove any false positives.\n"
        f"Check each function carefully. Return a precise list of confirmed SWC codes. Do not provide fix suggestions or detection scopes.\n\n"
        f"Known vulnerabilities: {','.join(vulnerabilities_found)}\n"
        f"Detection includes:\n"
        f"SWC-135: Code With No Effects\n"
        f"SWC-108: State Variable Default Visibility\n"
        f"SWC-129: Unchecked Call Return Value\n"
        f"SWC-123: Requirement Violation\n"
        f"SWC-100: Uninitialized State Variables\n"
        f"SWC-119: Shadowing State Variables\n"
        f"SWC-102: Unencrypted Private Data On-Chain\n"
        f"SWC-103: Ether Transfer to Unknown Address\n"
        f"SWC-128: DoS With Block Gas Limit\n"
        f"SWC-104: Outdated Compiler Version\n"
        f"SWC-126: Insufficient Gas Griefing\n"
        f"SWC-101: Delegatecall to Untrusted Contract\n"
        f"SWC-118: Incorrect Constructor Name\n"
        f"SWC-105: Unchecked Low-Level Calls\n"
        f"SWC-107: DoS with (Unexpected) Revert\n"
        f"SWC-114: Transaction Order Dependence\n"
        f"SWC-120: Authorization through tx.origin\n"
        f"SWC-111: Use of Deprecated Solidity Functions\n"
        f"SWC-116: Block values as a proxy for time\n"
        f"SWC-113: DoS with Block Gas Limit\n"
        f"Solidity file content:\n{solidity_response}\n"
        f"smartcheck output:\n{smartcheck_output_str}\n"
    )

    gpt_response = send_full_text_to_gpt(prompt)
    print(gpt_response)
    if gpt_response:
        swc_codes.update(re.findall(r'SWC-(\d+)', gpt_response))
        print(re.findall(r'SWC-(\d+)', gpt_response))

    return set([f"SWC-{code}" for code in swc_codes])

def analyze_with_gpt_in_three_rounds(smartcheck_output, solidity_content, structure_hint, sol_file_name):
    round_results = []
    for _ in range(3):
        vulnerabilities_result, solidity_response = analyze_common_vulnerabilities_with_gpt(smartcheck_output, solidity_content, structure_hint, sol_file_name)
        execution_result = simulate_symbolic_execution_with_gpt(smartcheck_output, solidity_content, vulnerabilities_result, sol_file_name,solidity_response)
        combined_result = execution_result
        round_results.append(combined_result)
    return round_results

def analyze_with_gpt_until_intersection(smartcheck_output, solidity_content, structure_hint, sol_file_name, max_attempts=5):
    attempt = 0
    all_swc_codes = []
    intersection_result = None

    while attempt < max_attempts:
        attempt += 1
        print(f"Round {attempt} analysis")
        current_round_results = analyze_with_gpt_in_three_rounds(smartcheck_output, solidity_content, structure_hint, sol_file_name)
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
            result_file.write(f"Contract {contract_name} had no intersection and no valid results returned.\n")

    print(f"Analysis result saved to: {result_file_path}")

def analyze_smartcheck_results_in_directory(sol_base_dir, smartcheck_base_dir, solc_analysis_dir, result_dir):
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
                    smartcheck_base_dir,
                    os.path.relpath(root, sol_base_dir),
                    f"{sol_file_name}.sol.txt"
                )
                corresponding_json_path = os.path.normpath(corresponding_json_path)

                print(f"Analyzing contract: {sol_file_name}")
                print(f"Analyzing file path: {corresponding_json_path}")

                smartcheck_output = read_smartcheck_result(corresponding_json_path)

                if smartcheck_output is None:
                    print(f"Skipping contract {sol_file_name}, smartcheck result could not be read.")
                    continue

                structure_hint = analyze_contract_structure_from_txt(sol_file_name, solc_analysis_dir)
                if structure_hint is None:
                    print(f"Skipping contract {sol_file_name}, structure hint not found.")
                    continue

                start_time = time.time()

                with open(sol_file_path, 'r', encoding='utf-8') as sol_file:
                    solidity_content = clean_solidity_comments(sol_file.read())

                swc_codes = analyze_with_gpt_until_intersection(smartcheck_output, solidity_content, structure_hint, sol_file_name)

                elapsed_time = time.time() - start_time
                total_time += elapsed_time

                print(f"Contract {sol_file_name} analysis time: {elapsed_time:.2f} seconds")

                save_analysis_result(sol_file_name, swc_codes, result_dir)

    if total_files > 0:
        avg_time_per_file = total_time / total_files
        print(f"Average analysis time per file: {avg_time_per_file:.2f} seconds")
    print(f"Total analysis time for all files: {total_time:.2f} seconds")

def main():
    sol_base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../datasets/DAppSCAN'))
    smartcheck_base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/smartcheck_tool_analysis_filter'))
    solc_analysis_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/solc-process'))
    result_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/smartcheck_CoT_gpt_3_5_turbo'))
    analyze_smartcheck_results_in_directory(sol_base_dir, smartcheck_base_dir, solc_analysis_dir, result_dir)


if __name__ == "__main__":
    main()

