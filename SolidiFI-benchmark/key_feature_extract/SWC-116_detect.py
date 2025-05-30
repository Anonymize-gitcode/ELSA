import re
import os
from solidity_parser import parser

# Define vulnerability patterns to check: Timestamp Dependency (SWC-116)
VULNERABLE_PATTERNS = [
    r'if\s*\([^)]*block\.timestamp[^)]*\)',  # Detect use of block.timestamp in if statement
    r'if\s*\([^)]*now[^)]*\)',  # Detect use of now in if statement
    r'block\.timestamp\s*[<>=!\+\-\*/]\s*\d+',  # Detect comparison or operation between timestamp and number
    r'now\s*[<>=!\+\-\*/]\s*\d+',  # Detect comparison or operation between now and number
    r'block\.timestamp\s*==\s*now',  # Detect equality between timestamp and now
]

# Safe usage patterns to exclude
SAFE_USAGE_PATTERNS = [
    r'emit\s+\w+\(.*block\.timestamp.*\)',  # Legitimate usage in logs
    r'onlyOwner|onlyAdmin|onlyAuthorized',  # Access control modifiers
    r'require\(msg\.sender\s*==\s*\w+\)',   # Explicit permission check
]

# Check if a Solidity file contains vulnerabilities and save the result
def check_for_vulnerabilities(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    vulnerabilities_found = []
    already_reported_lines = set()

    for line_num, line in enumerate(lines, start=1):
        stripped_line = line.strip()
        # Skip comment lines
        if stripped_line.startswith("//") or stripped_line.startswith("/*"):
            continue

        # Skip if the line has already been reported
        if line_num in already_reported_lines:
            continue

        for pattern in VULNERABLE_PATTERNS:
            match = re.search(pattern, line)
            if match:
                # Exclude safe usages
                is_safe = any(re.search(safe_pattern, line) for safe_pattern in SAFE_USAGE_PATTERNS)
                if is_safe:
                    continue

                vulnerabilities_found.append(f"Potential vulnerability type (SWC-116): Time of Day Dependency\n"
                                             f"Line: {line_num}\n"
                                             f"Code: {line.strip()}\n"
                                             f"--------------------------------------------------")
                already_reported_lines.add(line_num)
                break

    # Use AST parser to check for complex timestamp dependencies
    try:
        with open(file_path, 'r', encoding='utf-8') as source_file:
            source_code = source_file.read()
            ast = parser.parse(source_code)
            if detect_complex_timestamp_dependencies(ast):
                vulnerabilities_found.append(f"Complex timestamp dependency detected (SWC-116): File {file_path}\n"
                                             f"--------------------------------------------------")
    except Exception as e:
        print(f"Failed to parse file {file_path}, error: {e}")

    # Save detection result
    file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
    output_file_path = os.path.join(output_path, file_name)

    with open(output_file_path, 'w', encoding='utf-8') as output_file:
        if vulnerabilities_found:
            output_file.write("\n".join(vulnerabilities_found))
        else:
            output_file.write("No SWC-116 related vulnerabilities detected\n")

    return bool(vulnerabilities_found)

# Parse AST and detect complex timestamp dependencies
def detect_complex_timestamp_dependencies(ast):
    def traverse(node):
        if isinstance(node, dict):
            for key, value in node.items():
                if isinstance(value, (dict, list)):
                    if traverse(value):
                        return True
                elif key == "member" and value in ["timestamp", "now"]:
                    return True
        elif isinstance(node, list):
            for item in node:
                if traverse(item):
                    return True
        return False

    return traverse(ast)

# Scan all Solidity files in the directory
def scan_solidity_files(input_directory, output_directory):
    no_vulnerabilities_count = 0
    total_files_count = 0

    for root, dirs, files in os.walk(input_directory):
        for file in files:
            if file.endswith(".sol"):
                file_path = os.path.join(root, file)
                total_files_count += 1
                print(f"Start checking file: {file_path}")
                if not check_for_vulnerabilities(file_path, output_directory):
                    no_vulnerabilities_count += 1

    print(f"\nTotal number of scanned files: {total_files_count}")
    print(f"Number of files without vulnerabilities: {no_vulnerabilities_count}")

# Set scan path and output path
input_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/SolidiFI-benchmark'))  # Set your Solidity file directory path
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-116'))  # Set output path

os.makedirs(output_directory, exist_ok=True)
scan_solidity_files(input_directory, output_directory)
