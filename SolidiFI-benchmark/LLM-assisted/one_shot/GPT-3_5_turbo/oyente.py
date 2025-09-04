import os
import json
import openai  # Used to call GPT API
import time
import re
import logging
from collections import Counter

# Configure OpenAI GPT-3.5 API key
openai.api_key = ('...')  # Please replace with your actual API key

# Set up logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(message)s")


# Clean oyente output: remove comments and extra whitespace
def clean_oyente_output(oyente_content):
    oyente_content = re.sub(r'//.*', '', oyente_content)  # Remove single-line comments
    oyente_content = re.sub(r'/\*.*?\*/', '', oyente_content, flags=re.DOTALL)  # Remove multi-line comments
    oyente_content = re.sub(r'\n\s*\n', '\n', oyente_content)  # Remove extra blank lines
    return oyente_content


# Read oyente analysis result from file
def read_oyente_result(result_file_path):
    if not os.path.exists(result_file_path):
        logging.warning(f"Result file not found: {result_file_path}. Returning None.")
        return None

    with open(result_file_path, 'r', encoding='latin-1') as file:
        content = file.read().strip()
        if not content:
            logging.warning(f"File {result_file_path} is empty.")
            return None

        try:
            # If content is valid JSON, parse it
            oyente_output = json.loads(content)
            return oyente_output
        except json.JSONDecodeError:
            # If not JSON, clean content and return
            logging.warning(f"File {result_file_path} is not valid JSON, returning cleaned content.")
            return clean_oyente_output(content)


# Clean comments in Solidity code
def clean_solidity_comments(solidity_content):
    solidity_content = re.sub(r'//.*', '', solidity_content)
    solidity_content = re.sub(r'/\*.*?\*/', '', solidity_content, flags=re.DOTALL)
    solidity_content = re.sub(r'\n\s*\n', '\n', solidity_content)
    return solidity_content


# Send text to GPT for analysis
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


# Analyze contract vulnerabilities
def analyze_common_vulnerabilities_with_gpt(oyente_output, solidity_content):
    swc_codes = set()

    # Convert oyente output to string
    oyente_output_str = json.dumps(oyente_output, indent=2) if isinstance(oyente_output,
                                                                                  dict) else oyente_output

    prompt = (
        f"Please analyze the following Solidity code and oyente output to identify vulnerability types:\n"
        f"SWC-101: overflow_underflow\n"
        f"SWC-104: unhandled_exceptions\n"
        f"SWC-105: unchecked_send\n"
        f"SWC-107: reentrancy\n"
        f"SWC-116: timestamp_dependency\n"
        f"SWC-115: tx_origin_dependency\n"
        f"SWC-136: time of day dependency\n"
        f"Solidity code:\n{solidity_content}\n\n"
        f"Oyente output:\n{oyente_output_str}\n"
        f"Please identify any potential vulnerabilities and return the corresponding list of SWC codes."
    )

    # Send to GPT for analysis
    gpt_response = send_to_gpt(prompt)

    # Extract SWC codes from GPT response
    swc_codes.update(re.findall(r'SWC-(\d+)', gpt_response))

    return set([f"SWC-{code}" for code in swc_codes])


# Three-round contract analysis
def analyze_with_gpt_in_three_rounds(oyente_output, solidity_content, structure_hint, sol_file_name):
    round_results = []
    for _ in range(3):
        vulnerabilities_result = analyze_common_vulnerabilities_with_gpt(oyente_output, solidity_content)
        execution_result = simulate_symbolic_execution_with_gpt(oyente_output, solidity_content,
                                                                vulnerabilities_result, sol_file_name)
        combined_result = execution_result
        round_results.append(combined_result)
    return round_results


# Cross-validation until intersection of three rounds is found
def analyze_with_gpt_until_intersection(oyente_output, solidity_content, structure_hint, sol_file_name,
                                        max_attempts=5):
    attempt = 0
    all_swc_codes = []
    intersection_result = None

    while attempt < max_attempts:
        attempt += 1
        logging.info(f"Round {attempt} analysis")
        current_round_results = analyze_with_gpt_in_three_rounds(oyente_output, solidity_content, structure_hint,
                                                                 sol_file_name)
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


# Placeholder: symbolic execution simulation with GPT
def simulate_symbolic_execution_with_gpt(oyente_output, solidity_content, vulnerabilities_result, sol_file_name):
    # Actual symbolic execution code can be inserted here; currently a placeholder
    logging.info(f"Simulating symbolic execution analysis: {sol_file_name}")
    # Simulated execution result
    return vulnerabilities_result


# Save analysis result to file
def save_analysis_result(contract_name, swc_codes, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    result_file_path = os.path.join(output_dir, f"{contract_name}")
    result_file_path = result_file_path.replace('.sol', '_gpt_analysis.txt')
    print(result_file_path)
    # Check if result file already exists; if so, skip analysis
    if os.path.exists(result_file_path):
        logging.info(f"Skipping contract {contract_name}, result file already exists.")
        return

    # If result file does not exist, save analysis result
    with open(result_file_path, 'w', encoding='utf-8') as result_file:
        if swc_codes:
            result_file.write(f"Contract {contract_name} detected the following SWC codes: {', '.join(swc_codes)}\n")
        else:
            result_file.write(f"Contract {contract_name} returned no valid vulnerabilities.\n")

    logging.info(f"Analysis result saved to: {result_file_path}")


# Analyze all Solidity files in a directory
def analyze_oyente_results_in_directory(sol_base_dir, oyente_base_dir, result_dir):
    if not os.path.exists(sol_base_dir):
        logging.error(f"Directory not found: {sol_base_dir}")
        return

    total_files = 0
    total_time = 0.0

    # Traverse all Solidity files in directory and process sequentially
    for root, _, files in os.walk(sol_base_dir):
        for file in files:
            if file.endswith('.sol'):
                total_files += 1
                sol_file_path = os.path.join(root, file)
                oyente_file_path = os.path.join(oyente_base_dir, f"{file}.txt")

                if os.path.exists(oyente_file_path):
                    analyze_single_contract(sol_file_path, oyente_file_path, result_dir)
                else:
                    logging.warning(f"Oyente result for {file} not found, skipping contract.")

    logging.info(f"Analyzed {total_files} contracts in {total_time:.2f} seconds.")


# Analyze a single contract
def analyze_single_contract(sol_file_path, oyente_file_path, result_dir):
    contract_name = os.path.basename(sol_file_path)
    result_file_path = os.path.join(result_dir,  f"{contract_name.replace('.sol', '_gpt_analysis.txt')}")
    print(result_file_path)

    # Skip analysis if result file already exists
    if os.path.exists(result_file_path):
        logging.info(f"Analysis result for contract {contract_name} already exists, skipping.")
        return

    logging.info(f"Analyzing contract: {contract_name}")

    # Read Solidity contract content
    with open(sol_file_path, 'r', encoding='utf-8') as sol_file:
        solidity_content = sol_file.read()

    # Read oyente output
    oyente_output = read_oyente_result(oyente_file_path)

    if not oyente_output:
        logging.warning(f"Contract {contract_name} has no valid oyente output, skipping.")
        return

    # Start vulnerability analysis
    start_time = time.time()

    # Get final vulnerability result
    swc_codes = analyze_with_gpt_until_intersection(oyente_output, solidity_content, '', contract_name)

    end_time = time.time()
    total_time = end_time - start_time

    # Save analysis result
    save_analysis_result(contract_name, swc_codes, result_dir)

    logging.info(f"Analysis of contract {contract_name} completed in {total_time:.2f} seconds.\n")

def main():
    sol_base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../datasets/SolidiFI-benchmark'))
    oyente_base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/oyente_tool_analysis_filter'))
    result_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/oyente_one_shot_gpt_3_5_turbo'))

    analyze_oyente_results_in_directory(sol_base_dir, oyente_base_dir, result_dir)


if __name__ == "__main__":
    main()

