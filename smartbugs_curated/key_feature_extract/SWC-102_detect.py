import re
import os

# Define vulnerable patterns to check: Insecure randomness generation (SWC-102)
VULNERABLE_PATTERNS = [
    # Use of blockhash, which can be exploited to generate pseudo-random numbers
    r'blockhash\([^\)]*\)',  # Use of blockhash
    r'block\.timestamp',     # Use of block.timestamp
    r'now',                  # Use of now
    r'block\.number',        # Use of block.number
    r'tx\.origin',           # Use of tx.origin
    r'block\.difficulty',    # Use of block.difficulty
    r'block\.gaslimit',      # Use of block.gaslimit

    # Insecure randomness generation, e.g., keccak256( block.timestamp ) or keccak256( block.number )
    r'keccak256\([^\)]*block\.timestamp[^\)]*\)',  # Use of keccak256(block.timestamp)
    r'keccak256\([^\)]*block\.number[^\)]*\)',     # Use of keccak256(block.number)
    r'keccak256\([^\)]*now[^\)]*\)',               # Use of keccak256(now)
    r'keccak256\([^\)]*block\.difficulty[^\)]*\)', # Use of keccak256(block.difficulty)
    r'keccak256\([^\)]*block\.gaslimit[^\)]*\)',   # Use of keccak256(block.gaslimit)

    # Use of msg.sender or msg.value as a source of randomness, which may lead to insecure results
    r'keccak256\([^\)]*msg\.sender[^\)]*\)',       # Use of msg.sender as source of randomness
    r'keccak256\([^\)]*msg\.value[^\)]*\)',        # Use of msg.value as source of randomness
]

# Check whether a Solidity file has vulnerabilities and save the result
def check_for_vulnerabilities(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

        vulnerabilities_found = []
        already_reported_lines = set()  # Used to record already reported line numbers to avoid duplication

        # Check each line of code line by line
        for line_num, line in enumerate(lines, start=1):
            # Skip if this line has already been reported
            if line_num in already_reported_lines:
                continue

            for pattern in VULNERABLE_PATTERNS:
                if re.search(pattern, line):
                    # Format and output vulnerability info, including line number
                    vulnerabilities_found.append(f"Potential vulnerable type (SWC-102): BadRandomness\n"
                                                 f"Line: {line_num}\n"
                                                 f"Code: {line.strip()}")  # Only output the current line of code
                    # Mark this line as reported
                    already_reported_lines.add(line_num)
                    break  # Ensure each line is only reported once

        # If vulnerabilities are found, save to file
        if vulnerabilities_found:
            # Create output file with the same name as the source file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            # Write vulnerability info to output file
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("\n".join(vulnerabilities_found))
            return True  # Indicates vulnerabilities were detected in this file
        else:
            # If no vulnerabilities, return a specific message and save to file
            file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
            output_file_path = os.path.join(output_path, file_name)

            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write("No SWC-102 related vulnerabilities detected\n")
            return False  # Indicates no vulnerabilities were found in this file

# Scan all Solidity files in a directory
def scan_solidity_files(input_directory, output_directory):
    no_vulnerabilities_count = 0  # Count of files with no vulnerabilities
    total_files_count = 0  # Total number of processed files

    for root, dirs, files in os.walk(input_directory):
        for file in files:
            if file.endswith(".sol"):  # Only process .sol files
                file_path = os.path.join(root, file)
                total_files_count += 1
                # Check whether this file has vulnerabilities
                if not check_for_vulnerabilities(file_path, output_directory):
                    no_vulnerabilities_count += 1

    # Output statistics
    print(f"Total number of scanned files: {total_files_count}")
    print(f"Number of files with no vulnerabilities: {no_vulnerabilities_count}")

# Set directory to scan Solidity files
solidity_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/smartbugs_curated'))
# Set output directory for detection results
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-102'))

# Create output directory if it doesn't exist
os.makedirs(output_directory, exist_ok=True)

# Scan Solidity files in the directory, detect vulnerabilities and save results
scan_solidity_files(solidity_directory, output_directory)
