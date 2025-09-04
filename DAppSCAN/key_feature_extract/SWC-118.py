import os
import re
from packaging import version


def remove_comments_and_strings(code):
    """Remove comments and strings from the code to avoid interfering with syntax analysis"""
    # Remove multi-line comments /* ... */
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    # Remove single-line comments // ...
    code = re.sub(r'//.*', '', code)
    # Remove double-quoted strings
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', code)
    # Remove single-quoted strings
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)
    return code


def extract_compiler_version(cleaned_code):
    """Extract Solidity compiler version information"""
    pragma_pattern = r'pragma\s+solidity\s+([^;]+);'
    match = re.search(pragma_pattern, cleaned_code)
    if not match:
        return None  # No version specified

    version_str = match.group(1).strip()
    # Extract semantic version number (e.g., extract 0.4.22 from ^0.4.22)
    version_match = re.search(r'\d+\.\d+\.\d+', version_str)
    if version_match:
        return version.parse(version_match.group(0))
    return None


def find_matching_brace(code, start_pos):
    """Find the matching brace for a given starting position (supports nested braces)"""
    if start_pos >= len(code) or code[start_pos] != '{':
        return None

    brace_count = 1
    current_pos = start_pos + 1
    while current_pos < len(code):
        if code[current_pos] == '{':
            brace_count += 1
        elif code[current_pos] == '}':
            brace_count -= 1
            if brace_count == 0:
                return current_pos
        current_pos += 1
    return None  # No matching brace found (syntax error)


def get_line_number_from_position(original_code, abs_pos):
    """Calculate the line number from the absolute position"""
    if abs_pos < 0 or abs_pos > len(original_code):
        return -1  # Invalid position
    return original_code[:abs_pos].count('\n') + 1


def is_using_legacy_constructor_syntax(compiler_version):
    """Determine if legacy constructor syntax is used (<0.4.23)"""
    if not compiler_version:
        return True  # Default to legacy if no version is specified
    return compiler_version < version.parse("0.4.23")


def analyze_contract_constructors(cleaned_code, original_code):
    """Analyze contract constructors and identify potential SWC-118 issues"""
    contracts = []
    # Match contract definitions: contract contract_name { ... }
    contract_pattern = r'contract\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:is\s+[^\{]*)?\{'
    contract_matches = re.finditer(contract_pattern, cleaned_code)

    for contract_match in contract_matches:
        contract_name = contract_match.group(1)
        contract_start = contract_match.start()
        contract_end = find_matching_brace(cleaned_code, contract_match.end() - 1)
        if not contract_end:
            continue  # Skip incomplete contracts

        # Extract contract code
        contract_code = cleaned_code[contract_start:contract_end + 1]

        # Check for modern constructor keyword usage
        has_modern_constructor = bool(
            re.search(r'constructor\s*\([^)]*\)\s*\{', contract_code)
        )

        # Check for a legacy constructor with the same name as the contract
        legacy_constructor = None
        func_pattern = 'function\s+{re.escape(contract_name)}\s*\(\s*\)\s*(public)?\s*\{(?!\s*returns?\s*\()'  # Fix this part
        func_match = re.search(func_pattern, contract_code)

        if func_match:
            func_start_abs = contract_start + func_match.start()
        func_end_abs = find_matching_brace(cleaned_code, func_start_abs + func_match.end() - 1)
        if func_end_abs:
            legacy_constructor = {
                'name': contract_name,
                'code': cleaned_code[func_start_abs:func_end_abs + 1].strip(),
                'line': get_line_number_from_position(original_code, func_start_abs)
            }

        # Find potential erroneous constructors with similar names
        potential_errors = []
        if not has_modern_constructor and not legacy_constructor:
            # Match possible constructors (public visibility, no return type)
            candidate_pattern = r'function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\([^)]*\)\s*(public|internal|private)?\s*\{(?!\s*return)'  # Fix this part
            for candidate in re.finditer(candidate_pattern, contract_code):
                func_name = candidate.group(1)
            # Filter highly similar function names (reduce false positives)
            if (func_name.lower() == contract_name.lower() or
                    func_name == contract_name + '_' or
                    func_name == '_' + contract_name or
                    (len(func_name) >= len(contract_name) - 1 and
                     len(func_name) <= len(contract_name) + 1)):
                func_start_abs = contract_start + candidate.start()
            func_end_abs = find_matching_brace(cleaned_code, func_start_abs + candidate.end() - 1)
            if func_end_abs:
                potential_errors.append({
                    'name': func_name,
                    'code': cleaned_code[func_start_abs:func_end_abs + 1].strip(),
                    'line': get_line_number_from_position(original_code, func_start_abs)
                })

        contracts.append({
            'name': contract_name,
            'has_modern_constructor': has_modern_constructor,
            'legacy_constructor': legacy_constructor,
            'potential_errors': potential_errors
        })

    return contracts


def detect_swc118_vulnerabilities(file_path):
    """Detect SWC-118 vulnerabilities in the specified Solidity file"""
    vulnerabilities = []

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_code = f.read()

        cleaned_code = remove_comments_and_strings(original_code)
        compiler_version = extract_compiler_version(cleaned_code)
        contracts = analyze_contract_constructors(cleaned_code, original_code)

        # Only check contracts for legacy compilers
        if not is_using_legacy_constructor_syntax(compiler_version):
            return vulnerabilities

        for contract in contracts:
            # Skip contracts with modern constructor keyword
            if contract['has_modern_constructor']:
                continue

            # Check potential erroneous constructors
            for error_func in contract['potential_errors']:
                # Precisely determine the error type
                if error_func['name'].lower() == contract['name'].lower():
                    error_type = "case mismatch (capitalization error)"
                elif (error_func['name'].startswith(contract['name']) or
                      error_func['name'].endswith(contract['name'])):
                    error_type = "near-miss spelling error"
                else:
                    error_type = "incorrect name (likely intended as constructor)"

                # Construct description (avoid f-string escape characters)
                description = (
                    f"Potential constructor has {error_type}. "
                    f"Expected name: '{contract['name']}', "
                    f"Found name: '{error_func['name']}'."
                )

                vulnerabilities.append({
                    'type': 'SWC-118',
                    'contract': contract['name'],
                    'incorrect_name': error_func['name'],
                    'expected_name': contract['name'],
                    'error_type': error_type,
                    'line': error_func['line'],
                    'code_snippet': error_func['code'],
                    'description': description
                })

    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")

    return vulnerabilities


def batch_analyze_solidity_files(input_dir, output_dir):
    """Batch analyze Solidity files in a directory and output results"""
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    total_files = 0
    safe_files = 0

    for filename in os.listdir(input_dir):
        if not filename.endswith('.sol'):
            continue

        total_files += 1
        file_path = os.path.join(input_dir, filename)
        print(f"Analyzing: {filename}")

        # Detect vulnerabilities
        issues = detect_swc118_vulnerabilities(file_path)

        # Generate output file
        output_filename = f"{os.path.splitext(filename)[0]}_swc118_report.txt"
        output_path = os.path.join(output_dir, output_filename)

        with open(output_path, 'w', encoding='utf-8') as f:
            if issues:
                f.write(f"SWC-118 Vulnerability Report for {filename}\n")
                f.write("=" * 80 + "\n")
                f.write(f"Total issues found: {len(issues)}\n\n")

                for i, issue in enumerate(issues, 1):
                    f.write(f"Issue #{i}\n")
                    f.write(f"Contract: {issue['contract']}\n")
                    f.write(f"Line Number: {issue['line']}\n")
                    f.write(f"Error Type: {issue['error_type']}\n")
                    f.write(f"Expected Constructor Name: {issue['expected_name']}\n")
                    f.write(f"Found Name: {issue['incorrect_name']}\n")
                    f.write("Problematic Code:\n")
                    f.write(f"{issue['code_snippet']}\n")
                    f.write(f"Description: {issue['description']}\n")
                    f.write("-" * 80 + "\n")
            else:
                f.write("No SWC-118 issues detected.\n")
                safe_files += 1

    print(f"\nAnalysis complete. Total files processed: {total_files}")
    print(f"Files with no SWC-118 issues: {safe_files}")
    print(f"Reports saved to: {os.path.abspath(output_dir)}")


if __name__ == "__main__":
    # Configure input and output paths (use os.path for cross-platform compatibility)
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-118'))

    # Check if input directory exists
    if not os.path.isdir(input_directory):
        print(f"Error: Input directory not found - {input_directory}")
        print("Please create the directory or update the INPUT_DIRECTORY path.")
    else:
        batch_analyze_solidity_files(input_directory, output_directory)
