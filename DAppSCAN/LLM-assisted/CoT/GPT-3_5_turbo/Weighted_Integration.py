import os
import re
from collections import defaultdict

sol_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../datasets/DAppSCAN'))
mythril_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/mythril_CoT_gpt_3_5_turbo'))
slither_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/slither_CoT_gpt_3_5_turbo'))
smartcheck_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/smartcheck_CoT_gpt_3_5_turbo'))
output_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../result/WI_CoT_gpt_3_5_turbo'))


def read_swc_codes(file_path):
    """
    Fix SWC format anomalies:
    1. Match normal format (SWC-XXX) and abnormal format (SWC-SWC-XXX)
    2. Automatically fix the abnormal format to the standard format
    3. Remove duplicates and standardize
    """
    if not os.path.exists(file_path):
        print(f"Warning: Detection result file does not exist - {file_path}")
        return []

    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()

            # Key fix: Match normal format and abnormal format (SWC-SWC-XXX)
            # Regular expression explanation:
            # - (SWC-){1,2} → Match 1 or 2 occurrences of "SWC-" (handles both normal and abnormal formats)
            # - (\d+) → Match the numeric part
            swc_pattern = r'(SWC-){1,2}(\d+)'
            swc_matches = re.findall(swc_pattern, content)

            # Extract and fix format: Regardless of whether 1 or 2 occurrences of "SWC-" are matched, standardize as "SWC-number"
            normalized_swc = []
            for prefix_part, number_part in swc_matches:
                # Standard format concatenation: "SWC-" + number
                standard_swc = f"SWC-{number_part}"
                normalized_swc.append(standard_swc)

            # Remove duplicates
            unique_swc = list(set(normalized_swc))

            # Debugging information: Display fixed results
            print(f"Extracted SWC from {os.path.basename(file_path)}: {unique_swc}")
            return unique_swc

    except UnicodeDecodeError as e:
        print(f"Error: File encoding error - {file_path}, error message: {e}")
        return []
    except Exception as e:
        print(f"Error: Failed to read file - {file_path}, error message: {e}")
        return []


def get_swc_codes_from_sol(sol_file):
    """Get vulnerability detection results from three tools for the same contract"""
    mythril_result_path = os.path.join(mythril_folder, sol_file.replace('.sol', '_gpt_analysis.txt'))
    slither_result_path = os.path.join(slither_folder, sol_file.replace('.sol', '_gpt_analysis.txt'))
    smartcheck_result_path = os.path.join(smartcheck_folder, sol_file.replace('.sol', '_gpt_analysis.txt'))

    mythril_result = read_swc_codes(mythril_result_path)
    slither_result = read_swc_codes(slither_result_path)
    smartcheck_result = read_swc_codes(smartcheck_result_path)

    return mythril_result, slither_result, smartcheck_result


def select_final_vulnerability(mythril_result, slither_result, smartcheck_result):
    """Calculate optimal vulnerability based on tool weights"""
    tool_weights = {
        'mythril': 0.1,
        'slither': 0.3,
        'smartcheck': 0.1
    }

    swc_scores = defaultdict(float)
    for tool_name, results in zip(
            ['mythril', 'slither', 'smartcheck'],
            [mythril_result, slither_result, smartcheck_result]
    ):
        for swc in results:
            swc_scores[swc] += tool_weights[tool_name]

    if swc_scores:
        best_swc = max(swc_scores.items(), key=lambda x: x[1])[0]
        best_score = swc_scores[best_swc]
    else:
        best_swc = None
        best_score = 0.0

    return best_swc, best_score, {
        'mythril': mythril_result,
        'slither': slither_result,
        'smartcheck': smartcheck_result
    }


def save_results(sol_file, final_vulnerability, score, tool_results):
    """Save analysis results"""
    output_file = os.path.join(output_folder, sol_file.replace('.sol', '_result.txt'))
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    try:
        content = [f"# Contract Vulnerability Analysis Results: {sol_file}"]

        if final_vulnerability:
            content.append(f"Final Confirmed Vulnerability (Weighted Fusion): {final_vulnerability}")
            content.append(f"Vulnerability Weighted Score: {score:.2f}")
        else:
            content.append("Final Result: No clear vulnerability detected after weighted fusion")

        content.append("\n## Tool Detection Details (SWC Vulnerability Codes)")
        content.append(
            f"- Mythril (Weight: 0.3): {', '.join(tool_results['mythril']) if tool_results['mythril'] else 'None'}")
        content.append(
            f"- Slither (Weight: 0.5): {', '.join(tool_results['slither']) if tool_results['slither'] else 'None'}")
        content.append(
            f"- SmartCheck (Weight: 0.2): {', '.join(tool_results['smartcheck']) if tool_results['smartcheck'] else 'None'}")

        content.append("\n> Note: 'No vulnerability detected' simply means the weighted threshold was not met, not that the contract is absolutely secure. It is recommended to combine manual audit.")

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(content))

        if final_vulnerability:
            print(f"Results saved: {output_file} (Vulnerability detected: {final_vulnerability})")
        else:
            print(f"Results saved: {output_file} (No vulnerabilities detected)")

    except Exception as e:
        print(f"Error: Failed to save results - {sol_file}, error message: {e}")


# Batch processing
if __name__ == "__main__":
    for sol_file in os.listdir(sol_folder):
        if sol_file.endswith('.sol'):
            output_file = os.path.join(output_folder, sol_file.replace('.sol', '_result.txt'))

            if os.path.exists(output_file):
                print(f"Result already exists, skipping analysis: {output_file}")
                continue

            mythril_res, slither_res, smartcheck_res = get_swc_codes_from_sol(sol_file)
            final_vuln, score, tool_res = select_final_vulnerability(mythril_res, slither_res, smartcheck_res)
            save_results(sol_file, final_vuln, score, tool_res)

    print("Batch analysis complete!")
