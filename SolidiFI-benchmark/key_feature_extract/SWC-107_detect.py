import re
import os

# Define vulnerability patterns to check: Time Manipulation vulnerabilities
VULNERABLE_PATTERNS = [
    # 1. Timestamp condition checks, potentially manipulated by miners
    r'block\.timestamp',  # usage of block.timestamp
    r'now',  # usage of now
    r'if\s*\(.*(block\.timestamp|now).*',  # usage in if condition
    r'require\(\s*(block\.timestamp|now)\s*[^)]*\)',  # usage in require statement
    r'function\s+\w+\s*\(.*\)\s*(public|external)\s*{[^}]*\b(block\.timestamp|now)\b[^}]*\btransfer\(',  # timestamp controls fund transfer
    r'function\s+\w+\s*\(.*\)\s*(public|external)\s*{[^}]*\b(block\.timestamp|now)\b[^}]*\brequire\(',  # timestamp controls require statement
]

# Check whether the contract functions contain timestamp manipulation vulnerabilities
def check_for_vulnerabilities(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

        vulnerabilities_found = []
        already_reported_lines = set()  # Record already reported lines to avoid duplicate outputs

        # Check each line of code
        for line_num, line in enumerate(lines, start=1):
            # Skip if already reported
            if line_num in already_reported_lines:
                continue

            # 1. Check for usage of block.timestamp or now
            for pattern in VULNERABLE_PATTERNS:
                if re.search(pattern, line):
                    # Format vulnerability information
                    vulnerabilities_found.append(f"Potential Vulnerability Type (Time Manipulation)\n"
                                                 f"Line: {line_num}\n"
                                                 f"Code: {line.strip()}\n"
                                                 f"--------------------------------------------------")
                    # Mark this line as reported
                    already_reported_lines.add(line_num)
                    break  # Ensure each line reports only once

        # If vulnerabilities are found, save to file
        if vulnerabilities_found:
            # Create output file with same name as source file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            # Write vulnerabilities to output file
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("\n".join(vulnerabilities_found))
            return True  # Indicates vulnerabilities found in this file
        else:
            # If no vulnerabilities, return specific message and save to file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("No Time Manipulation related vulnerabilities detected\n")
            return False  # Indicates no vulnerabilities found

# Scan all Solidity files in a directory
def scan_solidity_files(input_directory, output_directory):
    no_vulnerabilities_count = 0  # Count of files without vulnerabilities
    total_files_count = 0  # Total number of files processed

    for root, dirs, files in os.walk(input_directory):
        for file in files:
            if file.endswith(".sol"):  # Only process .sol files
                file_path = os.path.join(root, file)
                total_files_count += 1
                # Check if the file has vulnerabilities
                if not check_for_vulnerabilities(file_path, output_directory):
                    no_vulnerabilities_count += 1

    # Output statistics
    print(f"Total number of files scanned: {total_files_count}")
    print(f"Number of files with no vulnerabilities detected: {no_vulnerabilities_count}")

# Set the directory of Solidity files to scan
input_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/SolidiFI-benchmark'))  # Set your Solidity file directory path
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-107'))  # Set output path

# Create output directory if it does not exist
os.makedirs(output_directory, exist_ok=True)

# Scan Solidity files in the directory, detect vulnerabilities, and save results
scan_solidity_files(input_directory, output_directory)
