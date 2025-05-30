import re
import os

# Define vulnerability patterns to check: Time Dependency (SWC-136)
VULNERABLE_PATTERNS = [
    # Conditional check using block.timestamp or now directly
    r'if\s*\(.*block\.timestamp.*\)',

    # Other expressions based on block.timestamp or now
    r'\bblock\.timestamp\b',
    r'\bnow\b',

    # Time-related operations that directly rely on current time
    r'\bblock\.timestamp\s*[-+*/]\s*\d+',
    r'\bnow\s*[-+*/]\s*\d+',
]

# Check if a Solidity file has vulnerabilities and save the results
def check_for_vulnerabilities(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

        vulnerabilities_found = []
        already_reported_lines = set()  # Track reported line numbers to avoid duplicates

        # Check each line of code one by one
        for line_num, line in enumerate(lines, start=1):
            # Skip if the line has already been reported
            if line_num in already_reported_lines:
                continue

            for pattern in VULNERABLE_PATTERNS:
                if re.search(pattern, line):
                    # Format and record vulnerability information
                    vulnerabilities_found.append(f"Potential Vulnerability Type (SWC-136): Time of Day Dependency\n"
                                                 f"Line: {line_num}\n"
                                                 f"Code: {line.strip()}\n"
                                                 f"--------------------------------------------------")
                    already_reported_lines.add(line_num)
                    break  # Ensure the same line is only reported once

        # If vulnerabilities are found, save them to a file
        if vulnerabilities_found:
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("\n".join(vulnerabilities_found))
            return True  # Indicates vulnerabilities were found in the file
        else:
            # If no vulnerabilities found, write a message to the file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("No SWC-136 related vulnerabilities detected\n")
            return False  # Indicates no vulnerabilities were found

# Scan all Solidity files in a directory
def scan_solidity_files(input_directory, output_directory):
    no_vulnerabilities_count = 0  # Count of files with no vulnerabilities
    total_files_count = 0  # Total number of processed files

    for root, dirs, files in os.walk(input_directory):
        for file in files:
            if file.endswith(".sol"):  # Only process .sol files
                file_path = os.path.join(root, file)
                total_files_count += 1
                # Check for vulnerabilities in the file
                if not check_for_vulnerabilities(file_path, output_directory):
                    no_vulnerabilities_count += 1

    # Print statistics
    print(f"Total number of files scanned: {total_files_count}")
    print(f"Number of files with no vulnerabilities: {no_vulnerabilities_count}")

# Set the directory of Solidity files to scan
input_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/SolidiFI-benchmark'))  # Set your Solidity file directory path
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-136'))  # Set output path

# Create the output directory if it doesn't exist
os.makedirs(output_directory, exist_ok=True)

# Scan Solidity files in the directory, check for vulnerabilities, and save results
scan_solidity_files(input_directory, output_directory)
