import re
import os

# Define vulnerability patterns to check: SWC-104 (Front Running)
VULNERABLE_PATTERNS = [
    r'\.transfer\([^)]*\)',      # Unchecked transfer call
    r'\.call\{value:[^}]*\}',    # Unchecked call call
    r'block\.timestamp\s*[<>=!]+\s*\d+',   # Direct comparison of timestamp
    r'block\.number\s*[<>=!]+\s*\d+',      # Direct comparison of block number
    r'\.delegatecall\([^)]*\)',  # delegatecall usage
    r'\.send\([^)]*\)',          # send usage
]

# Define exclusion rules: safe usage patterns
EXCLUSION_PATTERNS = [
    r'onlyOwner',                # Detected access control
    r'onlyAdmin',                # Access modifier
    r'nonReentrant',             # Reentrancy guard
    r'require\(.*msg.sender\s*==',  # Valid msg.sender check
    r'require\(.*block\.timestamp\s*[<>=]',  # Valid timestamp restriction
    r'private',                  # Private functions are not considered risky
    r'internal',                 # Internal functions
    r'emit\s+\w+',               # Emitting events is usually safe
    r'OpenZeppelin',             # Exclude OpenZeppelin library functions
]

# Check if a Solidity file contains vulnerabilities and save results
def check_for_vulnerabilities(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

        vulnerabilities_found = []
        already_reported_lines = set()  # Track already reported lines to avoid duplicates

        # Check each line of code
        for line_num, line in enumerate(lines, start=1):
            # Skip if this line has already been reported
            if line_num in already_reported_lines:
                continue

            # Exclude code that matches safe patterns
            if any(re.search(exclusion, line) for exclusion in EXCLUSION_PATTERNS):
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

                    # Format and append vulnerability information with line number and code
                    vulnerabilities_found.append(f"Potential vulnerability type (SWC-104): Front Running\n"
                                                 f"Line: {line_num}\n"
                                                 f"Code: {line.strip()}\n"
                                                 f"--------------------------------------------------")
                    already_reported_lines.add(line_num)
                    break  # Report only once per line

        # If vulnerabilities found, save to file
        if vulnerabilities_found:
            # Create output file with same name as source file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            # Write vulnerability information to file
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("\n".join(vulnerabilities_found))
            return True  # Vulnerability detected
        else:
            # If no vulnerabilities, write message and save to file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("No SWC-104 related vulnerabilities detected\n")
            return False  # No vulnerability detected

# Scan all Solidity files in the directory
def scan_solidity_files(input_directory, output_directory):
    no_vulnerabilities_count = 0  # Count of files with no vulnerabilities
    total_files_count = 0         # Total number of files

    for root, dirs, files in os.walk(input_directory):
        for file in files:
            if file.endswith(".sol"):  # Only process .sol files
                file_path = os.path.join(root, file)
                total_files_count += 1
                # Check if file has vulnerabilities
                if not check_for_vulnerabilities(file_path, output_directory):
                    no_vulnerabilities_count += 1

    # Output statistics
    print(f"Total number of files scanned: {total_files_count}")
    print(f"Number of files with no vulnerabilities: {no_vulnerabilities_count}")

# Set scan directory and output result directory
solidity_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/smartbugs_curated'))
# Set detection result output directory
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-104'))

# Create output directory if it doesn't exist
os.makedirs(output_directory, exist_ok=True)

# Scan Solidity files and save detection results
scan_solidity_files(solidity_directory, output_directory)
