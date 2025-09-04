import re
import os

# Define vulnerability patterns to check: Access control vulnerability (SWC-100)
VULNERABLE_PATTERNS = [
    # Check for calls without access control in public functions (limited context to avoid false positives)
    r'function\s+\w+\s*\(.*\)\s*(public|external)\s*[^}]*call\{value:[^\}]*\}\s*;',
    r'function\s+\w+\s*\(.*\)\s*(public|external)\s*[^}]*transfer\([^\)]*\)\s*;',

    # Check transfer/call operations without proper access control (enhanced condition to avoid false positives)
    r'call\{value:[^\}]*\}\s*;',  # Direct call to `call` or `transfer` without access control
    r'transfer\([^\)]*\)\s*;',    # Direct call to `transfer` without access control

    # Check for missing modifiers like `onlyOwner`, `onlyAdmin`, `onlyAuthorized`, etc.
    r'function\s+\w+\s*\(.*\)\s*(public|external)\s*[^}]*{.*(transfer|call)\(',  # Public function without access control

    # Check whether there is no proper require/assert/revert for access validation
    r'function\s+\w+\s*\(.*\)\s*(public|external)\s*{[^}]*require\([^}]*\)\s*;',
    r'function\s+\w+\s*\(.*\)\s*(public|external)\s*{[^}]*assert\([^}]*\)\s*;',
    r'function\s+\w+\s*\(.*\)\s*(public|external)\s*{[^}]*revert\([^}]*\)\s*;',
]

# Check for access control modifiers
ACCESS_CONTROL_MODIFIERS = [
    r'onlyOwner|onlyAdmin|onlyAuthorized',  # Access control modifiers
]


# Check whether a Solidity file contains vulnerabilities and save the result
def check_for_vulnerabilities(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

        vulnerabilities_found = []
        already_reported_lines = set()  # Record line numbers already reported to avoid duplication

        # Check each line of code
        for line_num, line in enumerate(lines, start=1):
            # Skip lines that have already been reported
            if line_num in already_reported_lines:
                continue

            # Check for unsafe function calls
            for pattern in VULNERABLE_PATTERNS:
                if re.search(pattern, line):
                    # Format vulnerability info
                    vulnerabilities_found.append(f"Potential vulnerability type (SWC-100): AccessControl\n"
                                                 f"Line: {line_num}\n"
                                                 f"Code: {line.strip()}\n"
                                                 f"--------------------------------------------------")
                    # Record the reported line
                    already_reported_lines.add(line_num)
                    break  # Ensure the same line is only reported once

            # Check for access control modifiers
            for modifier in ACCESS_CONTROL_MODIFIERS:
                if re.search(modifier, line):
                    # If no modifier found, report vulnerability
                    if not any(re.search(m, line) for m in ACCESS_CONTROL_MODIFIERS):
                        vulnerabilities_found.append(
                            f"Potential vulnerability type (SWC-100): AccessControl (Missing proper access control modifier)\n"
                            f"Line: {line_num}\n"
                            f"Code: {line.strip()}\n"
                            f"--------------------------------------------------")
                        already_reported_lines.add(line_num)
                        break  # Ensure the same line is only reported once

        # Save results if vulnerabilities are found
        if vulnerabilities_found:
            # Create output file named the same as the source file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            # Write vulnerability info to output file
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("\n".join(vulnerabilities_found))
            return True  # Indicates vulnerabilities were found
        else:
            # If no vulnerabilities, return specific message and save to file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("No SWC-100 related vulnerabilities detected\n")
            return False  # Indicates no vulnerabilities were found


# Scan all Solidity files in a directory
def scan_solidity_files(input_directory, output_directory):
    no_vulnerabilities_count = 0  # Count of files without vulnerabilities
    total_files_count = 0  # Total number of files processed

    for root, dirs, files in os.walk(input_directory):
        for file in files:
            if file.endswith(".sol"):  # Only process .sol files
                file_path = os.path.join(root, file)
                total_files_count += 1
                # Check if the file contains vulnerabilities
                if not check_for_vulnerabilities(file_path, output_directory):
                    no_vulnerabilities_count += 1

    # Output statistics
    print(f"Total number of files scanned: {total_files_count}")
    print(f"Number of files without vulnerabilities: {no_vulnerabilities_count}")


# Set the directory of Solidity files to be scanned
solidity_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/smartbugs_curated'))
# Set the output directory for detection results
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-100'))

# Create the output directory if it doesn't exist
os.makedirs(output_directory, exist_ok=True)

# Scan Solidity files in the directory, detect vulnerabilities, and save results
scan_solidity_files(solidity_directory, output_directory)
