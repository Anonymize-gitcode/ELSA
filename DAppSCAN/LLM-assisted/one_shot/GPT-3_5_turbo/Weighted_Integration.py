import os
import re

# File path settings
sol_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../datasets/DAppSCAN'))
mythril_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/mythril_one_shot_gpt_3_5_turbo'))
slither_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/slither_one_shot_gpt_3_5_turbo'))
smartcheck_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/smartcheck_one_shot_gpt_3_5_turbo'))
output_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/WI_one_shot_gpt_3_5_turbo'))


# Utility helper functions
def read_swc_codes(file_path):
    """Read txt file of SWC codes and return a list of SWC codes"""
    if not os.path.exists(file_path):
        print(f"Warning: File {file_path} does not exist!")
        return []
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
            return re.findall(r'SWC-\d+', content)
    except UnicodeDecodeError as e:
        print(f"Error: Unable to read file {file_path}, encoding issue {e}")
        return []


def get_swc_codes_from_sol(sol_file):
    """Obtain technique detection results"""
    mythril_result_path = os.path.join(mythril_folder, sol_file.replace('.sol', '_gpt_analysis.txt'))
    slither_result_path = os.path.join(slither_folder, sol_file.replace('.sol', '_gpt_analysis.txt'))
    smartcheck_result_path = os.path.join(smartcheck_folder, sol_file.replace('.sol', '_gpt_analysis.txt'))

    mythril_result = read_swc_codes(mythril_result_path)
    slither_result = read_swc_codes(slither_result_path)
    smartcheck_result = read_swc_codes(smartcheck_result_path)

    return mythril_result, slither_result, smartcheck_result


def select_final_vulnerability(mythril_result, slither_result, smartcheck_result):
    """Select the final vulnerability"""
    # Define weighted accuracy of techniques (combining precision and recall)
    technique_weights = {
        'mythril': 0.1,  # Consider only precision
        'slither': 0.2,
        'smartcheck': 0.3
    }

    # Count SWC codes to determine the final vulnerability
    swc_count = {}
    for technique_name, result in zip(['mythril', 'slither', 'smartcheck'],
                                 [mythril_result, slither_result, smartcheck_result]):
        for swc in result:
            if swc not in swc_count:
                swc_count[swc] = {'count': 0, 'techniques': []}
            swc_count[swc]['count'] += 1
            swc_count[swc]['techniques'].append(technique_name)

    best_swc = None
    best_score = -1

    # Iterate through all SWC vulnerabilities and calculate final scores
    for swc, data in swc_count.items():
        score = 0
        for technique in data['techniques']:
            score += technique_weights[technique]

        # Select the vulnerability with the highest score
        if score > best_score:
            best_score = score
            best_swc = swc

    return best_swc


def save_results(sol_file, final_vulnerability):
    """Save analysis results"""
    if not final_vulnerability:
        print(f"No vulnerabilities detected: {sol_file}")
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

        mythril_result, slither_result, smartcheck_result = get_swc_codes_from_sol(sol_file)
        final_vulnerability = select_final_vulnerability(mythril_result, slither_result, smartcheck_result)
        save_results(sol_file, final_vulnerability)
