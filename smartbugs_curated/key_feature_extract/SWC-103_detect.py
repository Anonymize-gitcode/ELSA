import re
import os

# Define the vulnerability patterns to check: Denial of Service (SWC-103)
VULNERABLE_PATTERNS = [
    # 1. Detect nested loops: nested loops may cause performance issues and trigger DoS
    re.compile(r'for\s*\(.*\)\s*\{.*?for\s*\(.*\)\s*\{.*?\}', re.DOTALL),  # Nested for loops
    re.compile(r'while\s*\(.*\)\s*\{.*?while\s*\(.*\)\s*\{.*?\}', re.DOTALL),  # Nested while loops
    re.compile(r'for\s*\(.*\)\s*\{.*?while\s*\(.*\)\s*\{.*?\}', re.DOTALL),  # for loop nested with while loop
    re.compile(r'while\s*\(.*\)\s*\{.*?for\s*\(.*\)\s*\{.*?\}', re.DOTALL),  # while loop nested with for loop

    # 2. External call-related DoS (gas limit, failure fallback)
    re.compile(r'\.call\s*\(.*\)\s*\{.*?gas\s*\([0-9]+\)\}', re.DOTALL),  # External call specifying gas
    re.compile(r'\.delegatecall\s*\(.*\)\s*\{.*?gas\s*\([0-9]+\)\}', re.DOTALL),  # delegatecall passing gas parameter
    re.compile(r'\.call\s*\(.*\)\s*\{.*?value\s*\([0-9]+\)\}', re.DOTALL),  # External call specifying value
    re.compile(r'\.delegatecall\s*\(.*\)\s*\{.*?value\s*\([0-9]+\)\}', re.DOTALL),  # delegatecall passing value parameter
    re.compile(r'\.send\s*\(.*\)'),  # send operation (considered high risk)
    re.compile(r'\.transfer\s*\(.*\)'),  # transfer operation (considered high risk)

    # 3. Recursive calls: recursive functions may cause stack overflow, leading to DoS
    re.compile(r'function\s+\w+\s*\(.*\)\s*public\s*\{.*?function\s+\w+\s*\(.*\)\s*\}', re.DOTALL),  # Recursive calls
]

# Check function to identify high-risk DoS vulnerabilities
def check_for_vulnerabilities(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

        vulnerabilities_found = []
        already_reported_lines = set()

        for line_num, line in enumerate(lines, start=1):
            if line_num in already_reported_lines:
                continue

            for pattern in VULNERABLE_PATTERNS:
                match = re.search(pattern, line)
                if match:
                    vulnerabilities_found.append(f"Potential vulnerability type (SWC-103): DenialOfService\n"
                                                 f"Line number: {line_num}\n"
                                                 f"Code snippet: {line.strip()}\n"
                                                 f"--------------------------------------------------")
                    already_reported_lines.add(line_num)
                    break

        # Generate output file path
        file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
        output_file_path = os.path.join(output_path, file_name)

        # Ensure output directory exists
        os.makedirs(output_path, exist_ok=True)

        # Write detection results
        if vulnerabilities_found:
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("\n".join(vulnerabilities_found))
            return True
        else:
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("No SWC-103 related vulnerabilities detected\n")
            return False

# Scan all Solidity files in the directory
def scan_solidity_files(input_directory, output_directory):
    no_vulnerabilities_count = 0  # Count of files without vulnerabilities
    for file_name in os.listdir(input_directory):
        file_path = os.path.join(input_directory, file_name)

        if os.path.isfile(file_path) and file_path.endswith('.sol'):
            print(f"Checking file: {file_name}")
            file_has_vulnerabilities = check_for_vulnerabilities(file_path, output_directory)
            if not file_has_vulnerabilities:
                no_vulnerabilities_count += 1

    print(f"Number of files with no SWC-103 related vulnerabilities detected: {no_vulnerabilities_count}")

# Set input and output directory paths
solidity_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/smartbugs_curated'))
# Set output directory for detection results
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-103'))

# Execute scanning
scan_solidity_files(solidity_directory, output_directory)
