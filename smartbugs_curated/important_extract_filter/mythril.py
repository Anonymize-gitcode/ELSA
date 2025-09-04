import os
import re


def filter_analysis_results(input_dir, output_dir):
    # Get all txt files in the input directory
    txt_files = [f for f in os.listdir(input_dir) if f.endswith('.txt')]

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for txt_file in txt_files:
        input_file_path = os.path.join(input_dir, txt_file)
        output_file_path = os.path.join(output_dir, txt_file)

        with open(input_file_path, 'r', encoding='utf-8') as infile:
            lines = infile.readlines()

        with open(output_file_path, 'w', encoding='utf-8') as outfile:
            for line in lines:
                # Remove entire line containing "In file:"
                if "In file:" in line:
                    continue
                # Remove entire line containing "Caller:"
                if "Caller:" in line:
                    continue
                if "Transaction Sequence:" in line:
                    continue
                if "Account:" in line:
                    continue
                if "Initial State:" in line:
                    continue
                # Keep other information
                outfile.write(line)


# Input and output directory paths
input_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/mythril_tool_analysis'))
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/mythril_tool_analysis_filter'))

# Execute filtering operation
filter_analysis_results(input_dir, output_dir)
