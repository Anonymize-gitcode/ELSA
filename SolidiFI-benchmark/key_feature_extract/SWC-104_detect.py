import re
import os

# Define vulnerability patterns to check: SWC-104 (Front Running)
VULNERABLE_PATTERNS = [
    r'\.transfer\([^)]*\)\s*;',      # Unchecked transfer call
    r'\.call\{value:[^}]*\}\s*;',    # Unchecked call
    r'block\.timestamp\s*([<>=!]+\s*\d+)\s*;',   # Direct timestamp comparison
    r'block\.number\s*([<>=!]+\s*\d+)\s*;',      # Direct block number comparison
    r'\.delegatecall\([^)]*\)\s*;',  # delegatecall usage
    r'\.send\([^)]*\)\s*;',          # send usage
]

# Define exclusion rules: legitimate usage patterns
EXCLUSION_PATTERNS = [
    r'onlyOwner',                # Permission control
    r'onlyAdmin',                # Modifier for permission
    r'nonReentrant',             # Reentrancy protection
    r'require\(.*msg.sender\s*==',  # Valid msg.sender check
    r'require\(.*block\.timestamp\s*[<>=]',  # Valid timestamp restriction
    r'private',                  # Private functions not considered risky
    r'internal',                # Internal functions
    r'emit\s+\w+',               # Event logging is usually safe
    r'OpenZeppelin',             # Exclude OpenZeppelin library functions
    r'constructor',              # Exclude constructors
    r'function\s+[a-zA-Z0-9_]+\s*\(.*\)\s*\{', # Exclude function declarations
    r'address\((0x[a-fA-F0-9]{40})\)',  # Exclude known valid addresses
    r'require\s*\(',             # Exclude require function
    r'assert\s*\(',              # Exclude assert function
]

# Common operations inside functions to reduce false positives
VALID_FUNCTION_OPERATIONS = [
    r'public',                   # Public functions are usually safe
    r'protected',                # Protected functions
    r'view',                     # View functions
    r'pure',                     # Pure functions
]

# Check whether a Solidity file contains vulnerabilities and save the results
def check_for_vulnerabilities(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

        vulnerabilities_found = []
        already_reported_lines = set()  # Track reported lines to avoid duplicates

        # Check each line of code
        for line_num, line in enumerate(lines, start=1):
            # Skip if line already reported
            if line_num in already_reported_lines:
                continue

            # Skip if line matches a safe usage pattern
            if any(re.search(exclusion, line) for exclusion in EXCLUSION_PATTERNS):
                continue

            # Further skip if line matches legitimate function operation
            if any(re.search(valid, line) for valid in VALID_FUNCTION_OPERATIONS):
                continue

            for pattern in VULNERABLE_PATTERNS:
                if re.search(pattern, line):
                    # Check context to ensure it's not protected
                    context_safe = False
                    for exclusion in EXCLUSION_PATTERNS:
                        if re.search(exclusion, line):
                            context_safe = True
                            break
                    if context_safe:
                        continue

                    # Format vulnerability info including line number and code
                    vulnerabilities_found.append(f"Potential Vulnerability Type (SWC-104): Front Running\n"
                                                 f"Line: {line_num}\n"
                                                 f"Code: {line.strip()}\n"
                                                 f"--------------------------------------------------")
                    already_reported_lines.add(line_num)
                    break  # Only report one vulnerability per line

        # If vulnerabilities found, save to file
        if vulnerabilities_found:
            # Create output file with same name as source file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            # Write vulnerability info to file
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("\n".join(vulnerabilities_found))
            return True  # Indicates vulnerabilities were detected
        else:
            # If no vulnerabilities, return message and save to file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("No SWC-104 related vulnerabilities detected\n")
            return False  # Indicates no vulnerabilities detected

# Scan all Solidity files in a directory
def scan_solidity_files(input_directory, output_directory):
    no_vulnerabilities_count = 0  # Count of files with no vulnerabilities
    total_files_count = 0         # Total file count

    for root, dirs, files in os.walk(input_directory):
        for file in files:
            if file.endswith(".sol"):  # Only process .sol files
                file_path = os.path.join(root, file)
                total_files_count += 1
                # Check whether file contains vulnerabilities
                if not check_for_vulnerabilities(file_path, output_directory):
                    no_vulnerabilities_count += 1

    # Output summary statistics
    print(f"Total files scanned: {total_files_count}")
    print(f"Files with no vulnerabilities: {no_vulnerabilities_count}")

# Set scan directory and output directory
input_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/SolidiFI-benchmark'))  # Set your Solidity file directory path
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-104'))  # Set output path

# Create output directory if it doesn't exist
os.makedirs(output_directory, exist_ok=True)

# Scan Solidity files and save detection results
scan_solidity_files(input_directory, output_directory)
