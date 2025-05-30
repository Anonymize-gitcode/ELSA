import re
import os

# Patterns used to identify vulnerabilities related to short address attacks
PATTERNS = [
    r'function\s+\w+\(.*address\s+\w+.*\)',  # Function signatures containing address parameters
    r'mapping\s*\(address\s+.*\)\s+balances',  # Address-related mappings
    r'Transfer\(',  # Functions that handle transfers
]

# Determines whether the function has already performed address length checking
def is_address_length_checked(lines, start_line, end_line):
    for line in lines[start_line:end_line]:
        # Check if there's a length check, e.g., require(address.length == 20)
        if re.search(r'require\(.+length\s*==\s*20\)', line):
            return True
    return False

# Check for the use of tx.origin or msg.sender
def is_address_using_sender_or_origin(line):
    # Check if tx.origin or msg.sender is being assigned or directly used
    if re.search(r'(tx\.origin|msg\.sender)\s*=', line):  # Check if address is being assigned
        return True
    if re.search(r'(tx\.origin|msg\.sender)', line):  # Check if address is being passed
        return True
    return False

# Determine if there is a valid address length check
def is_address_checked(line):
    # Check if length check exists
    if re.search(r'require\(.+length\s*==\s*20\)', line):  # Ensure address length check
        return True
    return False

# Determine whether the function has proper permission control
def is_proper_permission_control(line):
    if re.search(r'onlyOwner|onlyAdmin|onlyAuthorized|onlyWhitelist|ownerOnly', line):  # Permission control
        return True
    return False

# Further exclude known secure functions (e.g., functions with `require()` checks)
def is_security_function(line):
    if re.search(r'require\(', line) or re.search(r'assert\(', line):
        return True
    return False

# Only match key functions actually involved in transfer or sending coins
def is_transfer_related_function(line):
    if re.search(r'balances[^\w]', line) or re.search(r'sendCoin\(', line):
        return True
    return False

# Precisely exclude confirmed non-vulnerable cases
def is_excluded_function(line):
    # Exclude some common non-vulnerable functions (e.g., ERC-20 standard transfer, approve)
    if re.search(r'function\s+(transfer|approve|transferFrom|mint|burn|safeTransfer|safeTransferFrom)\(', line):
        return True
    # Also exclude if the function involves permission control or address validation
    if is_proper_permission_control(line) or is_security_function(line):
        return True
    return False

# Check whether there is a SWC-106 vulnerability in the file
def check_for_vulnerabilities(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    vulnerabilities_found = []

    for line_num, line in enumerate(lines, start=1):
        # 1. Check for usage of tx.origin or msg.sender
        if re.search(r'(tx\.origin|msg\.sender)', line):
            # Exclude common non-vulnerable functions
            if is_excluded_function(line):
                continue

            # Check if tx.origin or msg.sender is used in the function
            if is_address_using_sender_or_origin(line):
                start_line = max(0, line_num - 5)
                end_line = min(len(lines), line_num + 5)

                # 2. Skip if address length check is already done
                if is_address_length_checked(lines, start_line, end_line):
                    continue

                # 3. Skip if permission control is already implemented
                if is_proper_permission_control(line):
                    continue

                # 4. Skip if it's already a security function (e.g., require, assert)
                if is_security_function(line):
                    continue

                # 5. Skip if address validation is done
                if is_address_checked(line):
                    continue

                # 6. Refined judgment whether it's a short address vulnerability
                if is_transfer_related_function(line):
                    vulnerabilities_found.append({
                        'type': 'SHORT_ADDRESSES',
                        'line': line_num,
                        'code': line.strip()
                    })

    # Save detection results
    file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
    output_file_path = os.path.join(output_path, file_name)

    with open(output_file_path, 'w', encoding='utf-8') as output_file:
        if vulnerabilities_found:
            for vulnerability in vulnerabilities_found:
                output_file.write(f"Potential Risk Vulnerability Type (SWC-106): {vulnerability['type']}\n")
                output_file.write(f"Line Number: {vulnerability['line']}\n")
                output_file.write(f"Related Code: {vulnerability['code']}\n")
                output_file.write("-" * 50 + "\n")
        else:
            output_file.write("No SWC-106 vulnerability detected.\n")

    return len(vulnerabilities_found) > 0


# Scan all Solidity files in the directory
def scan_solidity_files(input_directory, output_directory):
    total_files_count = 0  # Total number of scanned files
    no_vulnerabilities_count = 0  # Number of files without vulnerabilities

    os.makedirs(output_directory, exist_ok=True)

    for root, _, files in os.walk(input_directory):
        for file in files:
            if file.endswith(".sol"):
                total_files_count += 1
                file_path = os.path.join(root, file)
                # Check if the file contains vulnerabilities
                if not check_for_vulnerabilities(file_path, output_directory):
                    no_vulnerabilities_count += 1

    # Output statistics
    print(f"Total number of scanned files: {total_files_count}")
    print(f"Number of files without detected vulnerabilities: {no_vulnerabilities_count}")


# Set the scan directory and result output directory
solidity_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/smartbugs_curated'))
# Set the detection result output directory
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-106'))  # Create the directory if it does not exist

# Execute scan
scan_solidity_files(solidity_directory, output_directory)
