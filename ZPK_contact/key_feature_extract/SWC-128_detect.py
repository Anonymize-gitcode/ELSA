import re
import os

# General regex patterns to handle more complex cases, optimized for comments and implicit visibility
patterns = [
    # Check visibility of state variables
    {'name': 'UnspecifiedStateVariableVisibility',
     'pattern': r'^\s*(uint|int|address|bool|bytes\d*|string|mapping\(.+\)|struct|enum)\s+\w+\s*(;|=).*?(\s*//.*)?$'},

    # Check visibility of functions
    {'name': 'UnspecifiedFunctionVisibility',
     'pattern': r'^\s*function\s+\w+\s*\(.*\)\s*(public|external|internal|private)?\s*\{.*\}\s*(//.*)?$'},

    # Check visibility of modifiers
    {'name': 'UnspecifiedModifierVisibility', 'pattern': r'^\s*modifier\s+\w+\s*\{.*\}\s*(//.*)?$'},

    # Check visibility of events
    {'name': 'UnspecifiedEventVisibility', 'pattern': r'^\s*event\s+\w+\(.*\);\s*(//.*)?$'},

    # Check visibility of constants
    {'name': 'UnspecifiedConstantVisibility',
     'pattern': r'^\s*(uint|int|address|bool|bytes\d*|string)\s+constant\s+\w+\s*=\s*.*;\s*(//.*)?$'},

    # Check visibility of libraries
    {'name': 'UnspecifiedLibraryVisibility', 'pattern': r'^\s*library\s+\w+\s*\{.*\}\s*(//.*)?$'}
]


def detect_vulnerabilities(file_path):
    """Detect SWC-128 vulnerabilities in the given Solidity file"""
    violations = []

    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.readlines()

    # Process each line in the file
    for line_number, line in enumerate(content, start=1):
        # Skip empty lines and single-line comments
        if not line.strip() or line.strip().startswith("//"):
            continue

        for pattern in patterns:
            # Check if the line matches the vulnerability pattern, excluding lines that already specify visibility
            if re.search(pattern['pattern'], line) and not re.search(r'(public|private|internal|external)', line):
                violations.append({
                    'file': file_path,
                    'line': line_number,
                    'violation': pattern['name'],
                    'code': line.strip()
                })

    return violations


def process_directory(input_directory, output_directory):
    """Process all Solidity files in the specified directory and output the results to the target directory"""
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    no_vulnerability_count = 0  # Count of files with no vulnerabilities

    # Read all files in the directory
    for file_name in os.listdir(input_directory):
        if file_name.endswith('.sol'):
            file_path = os.path.join(input_directory, file_name)
            violations = detect_vulnerabilities(file_path)

            result_file_path = os.path.join(output_directory, f'{os.path.splitext(file_name)[0]}.txt')
            with open(result_file_path, 'w', encoding='utf-8') as result_file:
                if violations:
                    for violation in violations:
                        result_file.write(f"Potential vulnerability type (SWC-128): {violation['violation']}\n")
                        result_file.write(f"Line: {violation['line']}\n")
                        result_file.write(f"Code: {violation['code']}\n")
                        result_file.write("--------------------------------------------------\n")
                else:
                    result_file.write('No SWC-128 related vulnerabilities detected.\n')
                    no_vulnerability_count += 1

    # Output the number of files with no vulnerabilities
    print(f"A total of {no_vulnerability_count} file(s) had no SWC-128 related vulnerabilities detected.")


def main():
    input_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/ZPK_contact'))  # Set the path to your Solidity file directory
    output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-128'))  # Set the output path

    process_directory(input_directory, output_directory)

    print(f"Detection results saved to: {output_directory}")


if __name__ == '__main__':
    main()
