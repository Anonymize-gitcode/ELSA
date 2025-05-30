import re
import os

# Define regex patterns to detect SWC-124 vulnerabilities
vulnerability_patterns = [
    # SWC-124: Check for unauthorized delegatecall or call
    {
        'name': 'UnauthorizedDelegateCallOrCall',
        'pattern': r'(\.delegatecall\(|\.call\()',  # Match call or delegatecall invocation
        'check': lambda code: 'require' not in code and 'assert' not in code and 'revert' not in code  # Ensure no require/assert/revert permission check
    },
    # Check if the contract address being called is initiated from an unverified address
    {
        'name': 'CallWithUncontrolledAddress',
        'pattern': r'(\.delegatecall\(|\.call\()([^\)]*)',  # Match the address part of call or delegatecall
        'check': lambda code: 'address' not in code.lower() and 'require' not in code.lower() and 'assert' not in code.lower() and 'revert' not in code.lower()  # Ensure proper address verification is absent
    },
    # Check if msg.sender-based access control is missing
    {
        'name': 'UnverifiedSenderInCall',
        'pattern': r'(msg\.sender)',  # Check if msg.sender is involved in the call
        'check': lambda code: 'require' not in code and 'assert' not in code and 'revert' not in code  # Check for access verification
    },
    # Check whether calls using dynamically computed addresses are properly verified
    {
        'name': 'CallWithDynamicAddress',
        'pattern': r'(\.delegatecall\(|\.call\()([^\)]*)',  # Match the address part of call or delegatecall
        'check': lambda code: 'address' in code and 'require' not in code and 'assert' not in code and 'revert' not in code  # Perform extra checks for dynamic address calls
    },
    # Check if state changes like balance updates or mappings lack permission checks
    {
        'name': 'UncheckedStateChange',
        'pattern': r'balances\[[^\]]+\]\s*[\+\-]\s*[^\;]+',  # Look for mapping state updates
        'check': lambda code: 'require' not in code and 'assert' not in code and 'revert' not in code  # State changes without access control
    },
    # Check if amount-related operations lack validation
    {
        'name': 'UncheckedAmountChange',
        'pattern': r'(\d+\s*[\+\-\*\/]\s*\d+)',  # Look for amount/quantity calculations
        'check': lambda code: 'require' not in code and 'assert' not in code and 'revert' not in code  # No validation for amount operations
    },
    # Check if contract state updates are followed by proper verification
    {
        'name': 'UncheckedStateChangeAfterAction',
        'pattern': r'(balances\[[^\]]+\]\s*[\+\-]\s*[^\;]+)',  # Focus on balance update actions
        'check': lambda code: 'require' not in code and 'assert' not in code and 'revert' not in code
    }
]

def detect_vulnerabilities_in_solidity(file_path):
    """
    Detect SWC-124 vulnerabilities in a single Solidity file, return vulnerability types and line numbers
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            sol_code = file.readlines()  # Use readlines() to keep line numbers
    except UnicodeDecodeError:
        print(f"Cannot read file {file_path}, possibly due to encoding issues.")
        return []

    detected_issues = []

    # Iterate through each line and apply regex
    for i, line in enumerate(sol_code, 1):  # Start line numbering from 1
        for vuln in vulnerability_patterns:
            if re.search(vuln['pattern'], line) and vuln['check'](line):  # Ensure match passes check
                detected_issues.append({
                    'SWC': vuln['name'],  # Vulnerability type
                    'line': i,            # Line number
                    'code': line.strip()  # Relevant code
                })

    return detected_issues

def scan_directory_for_vulnerabilities(directory_path):
    """
    Scan all Solidity files in the directory and detect SWC-124 vulnerabilities
    """
    vulnerabilities_found = {}

    # Traverse all Solidity files in the directory
    for filename in os.listdir(directory_path):
        if filename.lower().endswith(".sol"):  # Ensure file extension is .sol (case insensitive)
            file_path = os.path.join(directory_path, filename)
            print(f"Scanning file: {file_path}")  # Print file path being scanned

            detected_issues = detect_vulnerabilities_in_solidity(file_path)
            if detected_issues:
                vulnerabilities_found[filename] = detected_issues
            else:
                vulnerabilities_found[filename] = []  # Record the file even if no vulnerabilities were found

    return vulnerabilities_found

def save_vulnerabilities_to_file(vulnerabilities, output_directory):
    """
    Save the detected SWC-124 vulnerabilities of each file into separate files
    """
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)  # Create the folder if it doesn't exist

    # Create a separate output file for each source file
    for filename, issues in vulnerabilities.items():
        output_file_path = os.path.join(output_directory, f"{filename}.txt")

        with open(output_file_path, 'w', encoding='utf-8') as f:
            if issues:
                for issue in issues:
                    f.write(f"Potential vulnerability type (SWC-124): {issue['SWC']}\n")
                    f.write(f"Line number: {issue['line']}\n")
                    f.write(f"Relevant code: {issue['code']}\n")
                    f.write("-" * 50 + "\n")
            else:
                f.write("No SWC-124 related vulnerabilities detected\n")

        print(f"Scan results saved to {output_file_path}")

def main():
    directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/ZPK_contact'))  # Set the path to your Solidity files
    output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-124'))  # Set the output path

    vulnerabilities = scan_directory_for_vulnerabilities(directory_path)

    # Save the vulnerability detection results to file
    save_vulnerabilities_to_file(vulnerabilities, output_directory)

# Call main function
if __name__ == "__main__":
    main()
