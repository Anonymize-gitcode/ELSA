import re
import os

# Define vulnerability patterns to check: Time Manipulation vulnerabilities
VULNERABLE_PATTERNS = [
    # 1. Timestamp condition judgment, may be manipulated by miners
    r'block\.timestamp',  # usage of block.timestamp
    r'now',  # usage of now
    r'if\s*\(.*(block\.timestamp|now).*',  # block.timestamp or now used in if condition
    r'require\(\s*(block\.timestamp|now)\s*[^)]*\)',  # block.timestamp or now used in require
    r'function\s+\w+\s*\(.*\)\s*(public|external)\s*{[^}]*\b(block\.timestamp|now)\b[^}]*\btransfer\(',  # timestamp controls fund transfer
    r'function\s+\w+\s*\(.*\)\s*(public|external)\s*{[^}]*\b(block\.timestamp|now)\b[^}]*\brequire\(',  # timestamp controls require statement
]

# Check whether contract functions have timestamp manipulation vulnerabilities
def check_for_vulnerabilities(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

        vulnerabilities_found = []
        already_reported_lines = set()  # Used to record reported line numbers to avoid duplicates

        # Check each line of code
        for line_num, line in enumerate(lines, start=1):
            # Skip if the line has already been reported
            if line_num in already_reported_lines:
                continue

            # 1. Check for usage of block.timestamp or now
            for pattern in VULNERABLE_PATTERNS:
                if re.search(pattern, line):
                    # Format vulnerability info
                    vulnerabilities_found.append(f"Potential Vulnerability Type (Time Manipulation)\n"
                                                 f"Line: {line_num}\n"
                                                 f"Code: {line.strip()}\n"
                                                 f"--------------------------------------------------")
                    # Mark this line as reported
                    already_reported_lines.add(line_num)
                    break  # Ensure each line is only reported once

        # If vulnerabilities found, save to file
        if vulnerabilities_found:
            # Create output file with same name as source file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            # Write vulnerabilities to output file
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("\n".join(vulnerabilities_found))
            return True  # Indicates that vulnerabilities were detected in the file
        else:
            # If no vulnerabilities, return message and save to file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("No Time Manipulation related vulnerabilities detected\n")
            return False  # Indicates that no vulnerabilities were found

# Scan all Solidity files in the directory
def scan_solidity_files(input_directory, output_directory):
    no_vulnerabilities_count = 0  # Count of files without vulnerabilities
    total_files_count = 0  # Total number of processed files

    for root, dirs, files in os.walk(input_directory):
        for file in files:
            if file.endswith(".sol"):  # Only process .sol files
                file_path = os.path.join(root, file)
                total_files_count += 1
                # Check whether the file contains vulnerabilities
                if not check_for_vulnerabilities(file_path, output_directory):
                    no_vulnerabilities_count += 1

    # Print statistics
    print(f"Total number of scanned files: {total_files_count}")
    print(f"Number of files without vulnerabilities: {no_vulnerabilities_count}")

# Set the directory containing Solidity files to scan
solidity_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/smartbugs_curated'))
# Set the output directory for detection results
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-107'))  # Create the directory if it doesn't exist

# Create the output directory if it doesn't exist
os.makedirs(output_directory, exist_ok=True)

# Scan Solidity files in the directory, detect vulnerabilities and save results
scan_solidity_files(solidity_directory, output_directory)
