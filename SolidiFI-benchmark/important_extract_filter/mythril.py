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
                # Delete entire line containing "Potential Risk Vulnerability Type" ("Potential Risk Vulnerability Type")
                if "Potential Risk Vulnerability Type" in line:
                    continue
                # Delete entire line containing "Caller:" (commented out in original)

                # Keep other information (strip source path/filename first — it encodes
                # the vulnerability for descriptively-named contracts; keep line numbers).
                line = re.sub(r"[a-zA-Z0-9_./\\:-]+\.sol:(\d+):\d+", r"line \1", line)
                line = re.sub(r"[a-zA-Z0-9_.\\/-]*[\\/][a-zA-Z0-9_.-]+\.sol", "", line)
                outfile.write(line)


# Input and output directory paths
input_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/mythril_tool_analysis'))
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/mythril_tool_analysis_filter'))

# Execute the filtering operation
filter_analysis_results(input_dir, output_dir)
