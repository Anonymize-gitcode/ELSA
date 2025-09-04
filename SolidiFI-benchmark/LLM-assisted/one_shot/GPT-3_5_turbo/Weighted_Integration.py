import os
import re
from collections import defaultdict

# File path settings
sol_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../datasets/SolidiFI-benchmark'))
mythril_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/mythril_one_shot_gpt_3_5_turbo'))
slither_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/slither_one_shot_gpt_3_5_turbo'))
smartcheck_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/smartcheck_one_shot_gpt_3_5_turbo'))
manticore_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/manticore_one_shot_gpt_3_5_turbo'))
securify_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/securify_one_shot_gpt_3_5_turbo'))
oyente_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/oyente_one_shot_gpt_3_5_turbo'))
output_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/WI_one_shot_gpt_3_5_turbo'))


# Utility helper function
def read_swc_codes(file_path):
    """Read a txt file with SWC codes and return the SWC code list"""
    if not os.path.exists(file_path):
        print(f"Warning: File {file_path} does not exist!")
        return []
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
            return re.findall(r'SWC-\d+', content)
    except UnicodeDecodeError as e:
        print(f"Error: Failed to read file {file_path} due to encoding issue {e}")
        return []


def get_swc_codes_from_sol(sol_file):
    """Get detection results from all tools"""
    result = {}
    for tool, folder in zip(
            ['mythril', 'slither', 'smartcheck', 'manticore', 'securify', 'oyente'],
            [mythril_folder, slither_folder, smartcheck_folder, manticore_folder, securify_folder, oyente_folder]
    ):
        file_path = os.path.join(folder, sol_file.replace('.sol', '_gpt_analysis.txt'))
        result[tool] = read_swc_codes(file_path)
    return result


def select_final_vulnerability(swc_codes_by_tool):
    """Select the final vulnerability based on detection results from tools"""

    # Define base weights for tools
    base_weights = {
        'mythril': 0.15,
        'slither': 0.1,
        'smartcheck': 0.1,
        'manticore': 0.25,
        'securify': 0.1,
        'oyente': 0.1,
    }

    # Count the number of valid tools (tools with detection results)
    valid_tools = {tool: swcs for tool, swcs in swc_codes_by_tool.items() if swcs}  # filter out tools with empty results
    valid_tool_count = len(valid_tools)

    # If no tools have detection results, return None
    if valid_tool_count == 0:
        return None

    # Adjust weights dynamically based on the number of valid tools
    adjusted_weights = {}
    for tool, weight in base_weights.items():
        if tool in valid_tools:
            adjusted_weights[tool] = weight / valid_tool_count  # redistribute weights evenly among valid tools

    # Count SWC codes and determine final vulnerability
    swc_count = defaultdict(lambda: {'count': 0, 'tools': []})

    for tool, swcs in valid_tools.items():
        for swc in swcs:
            swc_count[swc]['count'] += 1
            swc_count[swc]['tools'].append(tool)

    # Compute score for each vulnerability and select the best one
    best_swc = None
    best_score = -1

    for swc, data in swc_count.items():
        score = sum(adjusted_weights[tool] for tool in data['tools'])

        # Add consistency filter: confirmed by multiple tools
        if data['count'] >= 2:  # at least two tools confirm
            score *= 1.5  # give higher weight

        if score > best_score:
            best_score = score
            best_swc = swc

    return best_swc


def save_results(sol_file, final_vulnerability):
    """Save the analysis result"""
    if not final_vulnerability:
        print(f"No vulnerability detected: {sol_file}")
        return

    output_file = os.path.join(output_folder, sol_file.replace('.sol', '_result.txt'))
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    try:
        output_content = f"Final confirmed vulnerability: {final_vulnerability}"

        with open(output_file, 'w', encoding='utf-8') as file:
            file.write(output_content)
        print(f"Result saved to {output_file}")
    except Exception as e:
        print(f"Error occurred while saving result: {e}")


# Batch process Solidity files
for sol_file in os.listdir(sol_folder):
    if sol_file.endswith('.sol'):
        output_file = os.path.join(output_folder, sol_file.replace('.sol', '_result.txt'))
        if os.path.exists(output_file):
            print(f"Result file {output_file} already exists, skipping analysis.")
            continue

        swc_codes_by_tool = get_swc_codes_from_sol(sol_file)
        final_vulnerability = select_final_vulnerability(swc_codes_by_tool)
        save_results(sol_file, final_vulnerability)
