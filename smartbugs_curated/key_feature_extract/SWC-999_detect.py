import re
import os

# Define vulnerability patterns to check: Other / uncategorized risky constructs (SWC-999).
# The DASP "other" bucket (unknown / uncommon vulnerabilities) has no single crisp signature and
# no official SWC ID (SWC-999 is used as a sentinel). This is a best-effort, line-level heuristic
# that flags miscellaneous dangerous constructs NOT covered by the other categories, as hints for
# the downstream LLM stage.
VULNERABLE_PATTERNS = [
    r'\bselfdestruct\s*\(',   # selfdestruct: irreversible contract removal
    r'\bsuicide\s*\(',        # deprecated selfdestruct alias
    r'\bdelegatecall\s*\(',   # delegatecall: executes external code in this contract's context
    r'\bcallcode\s*\(',       # deprecated callcode
    r'\bassembly\b',          # inline assembly bypasses high-level safety checks
]

# Check whether a Solidity file contains other/uncategorized risky constructs
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

            for pattern in VULNERABLE_PATTERNS:
                if re.search(pattern, line):
                    # Format vulnerability info
                    vulnerabilities_found.append(f"Potential Vulnerability Type (Other)\n"
                                                 f"Line: {line_num}\n"
                                                 f"Code: {line.strip()}\n"
                                                 f"--------------------------------------------------")
                    # Mark this line as reported
                    already_reported_lines.add(line_num)
                    break  # Ensure each line is only reported once

        # If vulnerabilities found, save to file
        if vulnerabilities_found:
            # Create output file with same name as source file
            file_name = os.path.basename(file_path) + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            # Write vulnerabilities to output file
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("\n".join(vulnerabilities_found))
            return True  # Indicates that vulnerabilities were detected in the file
        else:
            # If no vulnerabilities, return message and save to file
            file_name = os.path.basename(file_path) + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("No Other related vulnerabilities detected\n")
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
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-999'))  # Create the directory if it doesn't exist

# Create the output directory if it doesn't exist
os.makedirs(output_directory, exist_ok=True)

# Scan Solidity files in the directory, detect vulnerabilities and save results
scan_solidity_files(solidity_directory, output_directory)
