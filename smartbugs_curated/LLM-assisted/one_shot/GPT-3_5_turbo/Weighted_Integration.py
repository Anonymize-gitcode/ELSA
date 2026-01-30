import os
import re
from collections import defaultdict

# File path settings
sol_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../datasets/smartbugs_curated'))
mythril_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/mythril_one_shot_gpt_3_5_turbo'))
slither_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/slither_one_shot_gpt_3_5_turbo'))
smartcheck_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/smartcheck_one_shot_gpt_3_5_turbo'))
manticore_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/manticore_one_shot_gpt_3_5_turbo'))
osiris_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/osiris_one_shot_gpt_3_5_turbo'))
oyente_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/oyente_one_shot_gpt_3_5_turbo'))
honeybadger_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/honeybadger_one_shot_gpt_3_5_turbo'))
output_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/WI_one_shot_gpt_3_5_turbo'))


# Utility functions
def read_swc_codes(file_path):
    """Read a txt file of SWC codes and return a list of SWC codes"""
    if not os.path.exists(file_path):
        print(f"Warning: file {file_path} does not exist!")
        return []
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
            return re.findall(r'SWC-\d+', content)
    except UnicodeDecodeError as e:
        print(f"Error: unable to read file {file_path}, encoding issue {e}")
        return []


def get_swc_codes_from_sol(sol_file):
    """Get detection results from all techniques"""
    result = {}
    for technique, folder in zip(
            ['mythril', 'slither', 'smartcheck', 'manticore', 'osiris', 'oyente', 'honeybadger'],
            [mythril_folder, slither_folder, smartcheck_folder, manticore_folder, osiris_folder, oyente_folder,
             honeybadger_folder]
    ):
        file_path = os.path.join(folder, sol_file.replace('.sol', '_analysis.txt'))
        result[technique] = read_swc_codes(file_path)
    return result


def select_final_vulnerability(swc_codes_by_technique):
    """Select the final vulnerability based on technique results"""
    # Define weighted accuracy of techniques (comprehensive of precision and recall)
    technique_weights = {
        'mythril': 0.1,     # Increase weight for Mythril
        'slither': 0.1,     # Keep Slither weight unchanged
        'smartcheck': 0.05, # Slightly lower SmartCheck weight
        'manticore': 0.4,   # Increase Manticore weight
        'osiris': 0.1,      # Keep Osiris weight unchanged
        'oyente': 0.05,     # Slightly lower Oyente weight
        'honeybadger': 0.2  # Keep Honeybadger weight unchanged
    }

    # Count SWC codes to determine the final vulnerability
    swc_count = defaultdict(lambda: {'count': 0, 'techniques': []})

    for technique, swcs in swc_codes_by_technique.items():
        for swc in swcs:
            swc_count[swc]['count'] += 1
            swc_count[swc]['techniques'].append(technique)

    # Calculate scores and select final vulnerability
    best_swc = None
    best_score = -1

    for swc, data in swc_count.items():
        score = sum(technique_weights[technique] for technique in data['techniques'])

        # Add consistency filter: confirmed by multiple techniques
        if data['count'] >= 1:  # At least one technique confirms
            score *= 1.5  # Give higher weight

        if score > best_score:
            best_score = score
            best_swc = swc

    return best_swc


def save_results(sol_file, final_vulnerability):
    """Save analysis result"""
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


# Batch processing of Solidity files
for sol_file in os.listdir(sol_folder):
    if sol_file.endswith('.sol'):
        output_file = os.path.join(output_folder, sol_file.replace('.sol', '_result.txt'))
        if os.path.exists(output_file):
            print(f"Result file {output_file} already exists, skipping analysis.")
            continue

        swc_codes_by_technique = get_swc_codes_from_sol(sol_file)
        final_vulnerability = select_final_vulnerability(swc_codes_by_technique)
        save_results(sol_file, final_vulnerability)
