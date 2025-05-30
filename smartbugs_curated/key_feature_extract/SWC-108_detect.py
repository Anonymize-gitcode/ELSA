import re
import os

# Regular expression rules
VULNERABLE_PATTERNS = [
    r'^\s*(?:uint|int|address|bool|string|bytes[0-9]*|mapping|struct)\s+\w+[^;]*;$',  # Match variable declarations
]

EXCLUDE_PATTERNS = [
    r'(public|private|internal|external|constant|immutable)',  # Exclude explicitly declared modifiers
    r'function\s',  # Exclude function parameters
    r'returns\s*\(',  # Exclude function return values
]

# Utility functions
def remove_comments(code):
    """Remove single-line and multi-line comments"""
    code = re.sub(r'//.*', '', code)  # Single-line comments
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)  # Multi-line comments
    return code

def merge_multiline_statements(lines):
    """Merge multi-line declarations"""
    merged_lines = []
    buffer = ""
    for line in lines:
        buffer += line.strip()
        if line.strip().endswith(";"):
            merged_lines.append(buffer)
            buffer = ""
    if buffer:
        merged_lines.append(buffer)
    return merged_lines

def is_state_variable(line, previous_lines):
    """Check whether the current line is a contract-level state variable"""
    function_context = any(re.search(r'\bfunction\b', prev_line) for prev_line in previous_lines)
    contract_context = any(re.search(r'\bcontract\b', prev_line) for prev_line in previous_lines)
    return contract_context and not function_context

# Detection function
def check_for_swc_108(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        code = file.read()

    # Remove comments
    code = remove_comments(code)
    lines = code.splitlines()
    lines = merge_multiline_statements(lines)

    vulnerabilities_found = []
    previous_lines = []
    for line_num, line in enumerate(lines, start=1):
        if not is_state_variable(line, previous_lines):
            previous_lines.append(line)
            continue

        for pattern in VULNERABLE_PATTERNS:
            if re.search(pattern, line):
                if not any(re.search(exclude, line) for exclude in EXCLUDE_PATTERNS):
                    vulnerabilities_found.append(f"Potential vulnerability type (SWC-108): State Variable Default Visibility\n"
                                                 f"Line: {line_num}\n"
                                                 f"Code: {line.strip()}\n"
                                                 f"--------------------------------------------------")
        previous_lines.append(line)

    file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
    output_file_path = os.path.join(output_path, file_name)

    with open(output_file_path, 'w', encoding='utf-8') as output_file:
        if vulnerabilities_found:
            output_file.write("\n".join(vulnerabilities_found))
        else:
            output_file.write("No SWC-108 related vulnerabilities detected\n")
    return len(vulnerabilities_found) == 0  # Return whether no vulnerabilities were found

def scan_solidity_files(input_directory, output_directory):
    """
    Scan Solidity files in the directory and detect SWC-108 vulnerabilities.
    """
    os.makedirs(output_directory, exist_ok=True)

    no_vulnerabilities_count = 0
    total_files_count = 0

    for root, dirs, files in os.walk(input_directory):
        for file in files:
            if file.endswith(".sol"):
                file_path = os.path.join(root, file)
                total_files_count += 1
                if check_for_swc_108(file_path, output_directory):
                    no_vulnerabilities_count += 1

    # Output scan statistics
    print(f"Total number of files scanned: {total_files_count}")
    print(f"Number of files with no vulnerabilities detected: {no_vulnerabilities_count}")

# Input and output directories
# Set scan directory and result output directory
solidity_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/smartbugs_curated'))
# Set the detection result output directory
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-108'))  # Create the output directory if it does not exist

# Run detection
scan_solidity_files(solidity_directory, output_directory)
