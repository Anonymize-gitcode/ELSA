import re
import os

# Define the vulnerability pattern to check: direct use of tx.origin (SWC-115)
VULNERABLE_PATTERNS = [
    r'\btx\.origin\b'  # Match standalone usage of tx.origin in the code
]

# Check if a Solidity file contains vulnerabilities and save the result
def check_for_vulnerabilities(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

        vulnerabilities_found = []
        already_reported_lines = set()  # Track already reported line numbers to avoid duplication

        in_multiline_comment = False  # Used to track the state of multi-line comments

        # Check each line of code
        for line_num, line in enumerate(lines, start=1):
            stripped_line = line.strip()

            # Skip the start of multi-line comments
            if stripped_line.startswith("/*"):
                in_multiline_comment = True

            # If inside a multi-line comment, skip this line
            if in_multiline_comment:
                if "*/" in stripped_line:
                    in_multiline_comment = False  # End of multi-line comment
                continue

            # Skip single-line comments
            if stripped_line.startswith("//"):
                continue

            # Skip tx.origin inside string literals
            if '"' in stripped_line or "'" in stripped_line:
                stripped_line_no_strings = re.sub(r'".*?"|\'.*?\'', '', stripped_line)  # Remove strings
            else:
                stripped_line_no_strings = stripped_line

            for pattern in VULNERABLE_PATTERNS:
                if re.search(pattern, stripped_line_no_strings):
                    # Check if it's possibly harmless usage, such as logging
                    if "emit" in stripped_line or "Log" in stripped_line:
                        continue  # Skip logging usage

                    # Format vulnerability information
                    vulnerabilities_found.append(f"Potential Vulnerability Type (SWC-115): tx.origin Usage\n"
                                                 f"Line: {line_num}\n"
                                                 f"Code: {stripped_line}\n"
                                                 f"--------------------------------------------------")
                    # Mark this line as reported
                    already_reported_lines.add(line_num)
                    break  # Ensure the same line is reported only once

        # If vulnerabilities are found, save to file
        if vulnerabilities_found:
            # Create output file with the same name as the source file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            # Write vulnerability info to output file
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("\n".join(vulnerabilities_found))
            return True  # Indicates vulnerabilities were detected in this file
        else:
            # If no vulnerabilities, return a specific message and save to file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("No SWC-115 related vulnerabilities detected\n")
            return False  # Indicates no vulnerabilities were found in this file

# Scan all Solidity files in the directory
def scan_solidity_files(input_directory, output_directory):
    no_vulnerabilities_count = 0  # Count of files with no vulnerabilities
    total_files_count = 0  # Total number of files processed

    for root, dirs, files in os.walk(input_directory):
        for file in files:
            if file.endswith(".sol"):  # Only process .sol files
                file_path = os.path.join(root, file)
                total_files_count += 1
                # Check if the file contains vulnerabilities
                if not check_for_vulnerabilities(file_path, output_directory):
                    no_vulnerabilities_count += 1

    # Print statistics
    print(f"Total number of scanned files: {total_files_count}")
    print(f"Number of files with no vulnerabilities: {no_vulnerabilities_count}")

# Set the directory to scan for Solidity files
input_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/SolidiFI-benchmark'))  # Set your Solidity file directory path
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-115'))  # Set output path

# Create the output directory if it doesn't exist
os.makedirs(output_directory, exist_ok=True)

# Scan Solidity files in the directory, detect vulnerabilities and save results
scan_solidity_files(input_directory, output_directory)
