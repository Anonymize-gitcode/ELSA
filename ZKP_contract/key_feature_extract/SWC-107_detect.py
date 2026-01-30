import re
import os

# Define vulnerability patterns to check: Unprotected Withdrawals (SWC-107)
VULNERABLE_PATTERNS = [
    # Unprotected transfer call (e.g., sending funds directly via call)
    r'\.call\{value:\s*[^}]*\}',

    # Transfer calls: no access control or failure check
    r'transfer\([^)]*\)',

    # Balance-related operations: without proper access control
    r'address\(this\)\.balance',  # Contract balance operation, potentially vulnerable if not controlled
    r'\w+\[msg\.sender\]',  # User balance related (e.g. deposits[msg.sender]), may be vulnerable if unprotected

    # Withdraw operations lacking access control
    r'function\s+\w+\s*\(.*\)\s*public\s*{[^}]*call\{value:',  # call within public function
    r'function\s+\w+\s*\(.*\)\s*public\s*{[^}]*transfer\(',  # transfer within public function

    # Repeated calls to transfer or missing failure checks in loop
    r'for\s*\(.*\)\s*\{[^}]*call\{value:',  # call inside loop
    r'for\s*\(.*\)\s*\{[^}]*transfer\(',  # transfer inside loop

    # Withdraw operations without success checks (missing require or similar)
    r'call\{value:[^}]*\}\s*;',  # call without require or check
    r'transfer\([^)]*\)\s*;',  # transfer without require or check

    # Access control checks: e.g. public withdrawal functions lacking `onlyOwner` or other modifiers
    r'function\s+\w+\s*\(.*\)\s*(public|external)\s*{[^}]*call\{value:',  # public/external functions with no access control
    r'function\s+\w+\s*\(.*\)\s*public\s*{[^}]*transfer\(',  # transfer within public function
]

# Check whether contract functions have access control (e.g., `onlyOwner`)
ACCESS_CONTROL_PATTERNS = [
    r'function\s+\w+\s*\(.*\)\s*(public|external)\s*{[^}]*call\{value:',  # Direct call in public function
    r'function\s+\w+\s*\(.*\)\s*public\s*{[^}]*transfer\(',  # Direct transfer in public function
]

# Check whether a Solidity file contains vulnerabilities and save results
def check_for_vulnerabilities(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

        vulnerabilities_found = []
        already_reported_lines = set()  # Record already reported line numbers to avoid duplication

        # Check each line of code
        for line_num, line in enumerate(lines, start=1):
            # Skip line if already reported
            if line_num in already_reported_lines:
                continue

            for pattern in VULNERABLE_PATTERNS:
                if re.search(pattern, line):
                    # Format vulnerability report
                    vulnerabilities_found.append(f"Potential Vulnerability (SWC-107): UnprotectedWithdraw\n"
                                                 f"Line: {line_num}\n"
                                                 f"Code: {line.strip()}\n"
                                                 f"--------------------------------------------------")
                    already_reported_lines.add(line_num)
                    break  # Only report once per line

            # Check for access control to confirm if missing
            for pattern in ACCESS_CONTROL_PATTERNS:
                if re.search(pattern, line) and not re.search(r'onlyOwner|onlyAdmin|onlyAuthorized', line):
                    vulnerabilities_found.append(f"Potential Vulnerability (SWC-107): UnprotectedWithdraw (Missing Access Control)\n"
                                                 f"Line: {line_num}\n"
                                                 f"Code: {line.strip()}\n"
                                                 f"--------------------------------------------------")
                    already_reported_lines.add(line_num)
                    break  # Only report once per line

        # If vulnerabilities are found, save to file
        if vulnerabilities_found:
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("\n".join(vulnerabilities_found))
            return True  # Indicates vulnerabilities detected
        else:
            # If no vulnerabilities, write specific message and save to file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("No SWC-107 related vulnerabilities detected\n")
            return False  # Indicates no vulnerabilities detected

# Scan all Solidity files in the directory
def scan_solidity_files(input_directory, output_directory):
    no_vulnerabilities_count = 0  # Count of files with no vulnerabilities
    total_files_count = 0  # Total number of files processed

    for root, dirs, files in os.walk(input_directory):
        for file in files:
            if file.endswith(".sol"):  # Only process .sol files
                file_path = os.path.join(root, file)
                total_files_count += 1
                if not check_for_vulnerabilities(file_path, output_directory):
                    no_vulnerabilities_count += 1

    # Output statistics
    print(f"Total files scanned: {total_files_count}")
    print(f"Files with no vulnerabilities: {no_vulnerabilities_count}")

solidity_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/ZKP_contract'))  # Set your Solidity file directory path
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-107'))  # Set output path
# Create output directory if it does not exist
os.makedirs(output_directory, exist_ok=True)

# Scan Solidity files in directory, detect vulnerabilities and save results
scan_solidity_files(solidity_directory, output_directory)
