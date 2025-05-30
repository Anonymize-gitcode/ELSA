import os
import json
import openai  # For calling GPT API
import time
import re
import logging
from collections import Counter

# Configure OpenAI GPT-3.5 API key
openai.api_key = ('...')  # Please replace with your actual API key

# Set up logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(message)s")


# Clean mythril output by removing comments and extra whitespace
def clean_mythril_output(mythril_content):
    mythril_content = re.sub(r'//.*', '', mythril_content)  # Remove single-line comments
    mythril_content = re.sub(r'/\*.*?\*/', '', mythril_content, flags=re.DOTALL)  # Remove multi-line comments
    mythril_content = re.sub(r'\n\s*\n', '\n', mythril_content)  # Remove extra blank lines
    return mythril_content


# Read mythril analysis result from file
def read_mythril_result(result_file_path):
    if not os.path.exists(result_file_path):
        logging.warning(f"Result file not found: {result_file_path}. Returning None.")
        return None

    with open(result_file_path, 'r', encoding='latin-1') as file:
        content = file.read().strip()
        if not content:
            logging.warning(f"File {result_file_path} is empty.")
            return None

        try:
            mythril_output = json.loads(content)
            return mythril_output
        except json.JSONDecodeError:
            logging.warning(f"File {result_file_path} is not valid JSON format. Returning cleaned content.")
            return clean_mythril_output(content)


# Clean comments from Solidity code
def clean_solidity_comments(solidity_content):
    solidity_content = re.sub(r'//.*', '', solidity_content)
    solidity_content = re.sub(r'/\*.*?\*/', '', solidity_content, flags=re.DOTALL)
    solidity_content = re.sub(r'\n\s*\n', '\n', solidity_content)
    return solidity_content


# Send prompt to GPT for analysis
def send_to_gpt(prompt, model="gpt-3.5-turbo"):
    try:
        response = openai.ChatCompletion.create(
            model=model,
            messages=[{"role": "user", "content": prompt}]
        )
        return response['choices'][0]['message']['content'].strip()
    except openai.error.OpenAIError as e:
        logging.error(f"Error calling GPT API: {e}")
        return ""


def read_key_feature_file(sol_file_name):
    key_feature_file_path = os.path.abspath(os.path.join(os.path.dirname(__file__), f'../../../../result/key_feature_extract/combine/{sol_file_name}.sol.txt'))
    if os.path.exists(key_feature_file_path):
        with open(key_feature_file_path, 'r', encoding='utf-8') as feature_file:
            return feature_file.read().strip()
    else:
        print(f"Warning: Key feature extraction file not found: {key_feature_file_path}")
        return ""


# Analyze contract vulnerabilities
def analyze_common_vulnerabilities_with_gpt(mythril_output, solidity_content, sol_file_name, structure_hint):
    swc_codes = set()

    mythril_output_str = json.dumps(mythril_output, indent=2) if isinstance(mythril_output, dict) else mythril_output

    key_feature_content = read_key_feature_file(sol_file_name)
    length_threshold = 12000
    print(sol_file_name)
    if len(solidity_content) > length_threshold:
        print(f"Solidity code exceeds {length_threshold} characters, optimizing.")
        file_path = os.path.abspath(os.path.join(os.path.dirname(__file__), f'../../../../datasets/smartbugs_curated_compress/{sol_file_name}.sol'))
        print(file_path)

        if os.path.exists(file_path):
            try:
                with open(file_path, 'r', encoding='utf-8') as file:
                    solidity_content_vector = file.read()
                    print(f"Successfully read content of file {sol_file_name}.")
            except Exception as e:
                print(f"Error reading file {sol_file_name}: {e}")
                solidity_content_vector = "Error reading file, cannot continue analysis."
        else:
            print(f"File {sol_file_name} does not exist, cannot read.")
            solidity_content_vector = "Specified Solidity file does not exist, cannot continue analysis."

        solidity_response = solidity_content_vector

    else:
        print(f"Solidity code does not exceed {length_threshold} characters, no optimization needed.")
        solidity_response = solidity_content

    prompt = (
        f"Please analyze the following Solidity code and mythril output to identify vulnerability types. Return the highest-risk vulnerability type. "
        f"Detection range: 'SWC-100':'access_control', 'SWC-101':'arithmetic', 'SWC-102':'bad_randomness', "
        "'SWC-103':'denial_of_service', 'SWC-104':'front_running', 'SWC-105':'other', "
        "'SWC-106':'short_addresses', 'SWC-107':'reentrancy', 'SWC-108':'time_manipulation', "
        "'SWC-109':'unchecked_low_level_calls'.\n"
        f"Return format:\n"
        f"[SWC code]: Vulnerability at line: [specific line], brief description.\n"
        f"Example: SWC-100: Vulnerability at line: 52 \n SWC-107: Not found\n"
        f"Solidity code:\n{solidity_response}\n\n"
        f"Contract structure hints:\n{structure_hint}\n"
        f"mythril output:\n{mythril_output_str}\n"
        f"Please identify any potential vulnerabilities and return the corresponding SWC code list."
    )

    gpt_response = send_to_gpt(prompt)
    print(gpt_response)

    vulnerabilities = []
    if isinstance(gpt_response, str):
        matches = re.findall(r'SWC-(\d+): vulnerabilities at line: (\d+|不存在)', gpt_response)

        for match in matches:
            swc_code = match[0].strip()
            line_number = match[1].strip()
            vulnerabilities.append((swc_code, line_number))

        swc_codes = set(re.findall(r'SWC-\d+', gpt_response))
    else:
        print("GPT response is not a valid string.")

    return set([f"SWC-{code}" for code in swc_codes])


# Three-round contract analysis
def analyze_with_gpt_in_three_rounds(mythril_output, solidity_content, structure_hint, sol_file_name):
    round_results = []
    for _ in range(3):
        vulnerabilities_result = analyze_common_vulnerabilities_with_gpt(mythril_output, solidity_content, sol_file_name, structure_hint)
        execution_result = simulate_symbolic_execution_with_gpt(mythril_output, solidity_content, vulnerabilities_result, sol_file_name)
        combined_result = execution_result
        round_results.append(combined_result)
    return round_results


# Perform cross-validation until intersection of three rounds is found
def analyze_with_gpt_until_intersection(mythril_output, solidity_content, structure_hint, sol_file_name, max_attempts=5):
    attempt = 0
    all_swc_codes = []
    intersection_result = None

    while attempt < max_attempts:
        attempt += 1
        logging.info(f"Analysis round {attempt}")
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
        logging.info("No valid results found.")
        return set()


# Placeholder for symbolic execution simulation with GPT
def simulate_symbolic_execution_with_gpt(mythril_output, solidity_content, vulnerabilities_result, sol_file_name):
    logging.info(f"Running symbolic execution analysis: {sol_file_name}")
    return vulnerabilities_result


# Save analysis result to file
def save_analysis_result(contract_name, swc_codes, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    result_file_path = os.path.join(output_dir, f"{contract_name}")
    result_file_path = result_file_path.replace('.sol', '_gpt_analysis.txt')
    print(result_file_path)

    if os.path.exists(result_file_path):
        logging.info(f"Skipping contract {contract_name}, result file already exists.")
        return

    with open(result_file_path, 'w', encoding='utf-8') as result_file:
        if swc_codes:
            result_file.write(f"Contract {contract_name} detected the following SWC codes: {', '.join(swc_codes)}\n")
        else:
            result_file.write(f"Contract {contract_name} did not return any valid vulnerabilities.\n")

    logging.info(f"Analysis result saved to: {result_file_path}")


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


# Analyze all Solidity files in the directory
def analyze_mythril_results_in_directory(sol_base_dir, mythril_base_dir, result_dir, solc_analysis_dir):
    if not os.path.exists(sol_base_dir):
        logging.error(f"Directory not found: {sol_base_dir}")
        return

    total_files = 0
    total_time = 0.0

    for root, _, files in os.walk(sol_base_dir):
        for file in files:
            if file.endswith('.sol'):
                total_files += 1
                sol_file_name = os.path.splitext(file)[0]
                structure_hint = analyze_contract_structure_from_txt(sol_file_name, solc_analysis_dir)
                if structure_hint is None:
                    print(f"Skipping contract {sol_file_name}, structure hint not found.")
                    continue
                sol_file_path = os.path.join(root, file)
                mythril_file_path = os.path.join(mythril_base_dir, f"{file}.txt")

                if os.path.exists(mythril_file_path):
                    analyze_single_contract(sol_file_path, mythril_file_path, result_dir, structure_hint)
                else:
                    logging.warning(f"Related mythril analysis result not found for {file}, skipping.")

    logging.info(f"Analyzed {total_files} contracts, time taken: {total_time:.2f} seconds.")


# Analyze a single contract
def analyze_single_contract(sol_file_path, mythril_file_path, result_dir, structure_hint):
    contract_name = os.path.basename(sol_file_path)
    result_file_path = os.path.join(result_dir, f"{contract_name}_gpt_analysis.txt")
    print(result_file_path)

    if os.path.exists(result_file_path):
        logging.info(f"Analysis result for contract {contract_name} already exists, skipping.")
        return

    logging.info(f"Analyzing contract: {contract_name}")

    with open(sol_file_path, 'r', encoding='utf-8') as sol_file:
        solidity_content = sol_file.read()

    mythril_output = read_mythril_result(mythril_file_path)

    if not mythril_output:
        logging.warning(f"No valid mythril output for contract {contract_name}, skipping.")
        return

    start_time = time.time()
    swc_codes = analyze_with_gpt_until_intersection(mythril_output, solidity_content, structure_hint, contract_name)
    end_time = time.time()
    total_time = end_time - start_time

    save_analysis_result(contract_name, swc_codes, result_dir)
    logging.info(f"Contract {contract_name} analysis completed, time taken: {total_time:.2f} seconds.\n")


def main():
    sol_base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../datasets/smartbugs_curated'))
    mythril_base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/mythril_tool_analysis_filter'))
    solc_analysis_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/solc-process'))
    result_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/mythril_one_shot_gpt_3_5_turbo'))
    analyze_mythril_results_in_directory(sol_base_dir, mythril_base_dir, result_dir, solc_analysis_dir)


if __name__ == "__main__":
    main()

