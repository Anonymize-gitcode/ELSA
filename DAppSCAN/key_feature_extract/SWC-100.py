import os
import re


def remove_comments_and_strings(solidity_code):
    """Remove comments and strings to avoid interference in detection"""
    # Remove strings (single and double quotes, handling escape characters)
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', solidity_code)
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)

    # Remove single-line comments
    code = re.sub(r'//.*', '', code)

    # Remove multi-line comments (handling nesting)
    while re.search(r'/\*.*?\*/', code, flags=re.DOTALL):
        code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)

    return code


def find_contract_ranges(cleaned_code):
    """Identify contract ranges (including contracts, libraries, interfaces)"""
    contract_ranges = []
    contract_pattern = r'(contract|library|interface)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*(is\s+[a-zA-Z_,\s]+)?\s*\{?'
    matches = re.finditer(contract_pattern, cleaned_code)

    for match in matches:
        start = match.start()
        # Find the closing brace of the contract body
        end = find_matching_delimiter(cleaned_code, start, '{', '}')
        if end:
            contract_ranges.append((start, end))

    return contract_ranges


def find_function_ranges(cleaned_code, contract_ranges):
    """Identify function ranges (used to differentiate state variables and local variables)"""
    function_ranges = []
    # Match functions and constructors
    func_pattern = r'(function\s+[a-zA-Z_][a-zA-Z0-9_]*|constructor)\s*\([^)]*\)\s*(external|public|internal|private)?\s*\{?'
    matches = re.finditer(func_pattern, cleaned_code)

    for match in matches:
        # Ensure the function is within the contract range
        in_contract = any(start <= match.start() <= end for start, end in contract_ranges)
        if not in_contract:
            continue

        start = match.start()
        end = find_matching_delimiter(cleaned_code, start, '{', '}')
        if end:
            function_ranges.append((start, end))

    return function_ranges


def find_matching_delimiter(code, start_pos, opening='{', closing='}'):
    """Find matching delimiter (supports nesting)"""
    count = 1 if code[start_pos:start_pos + 1] == opening else 0
    pos = start_pos
    while pos < len(code):
        pos += 1
        if pos >= len(code):
            return None
        if code[pos] == opening:
            count += 1
        elif code[pos] == closing:
            count -= 1
            if count == 0:
                return pos
    return None


def is_reference_type(var_type):
    """Check if it is a reference type (riskier uninitialized variables)"""
    reference_patterns = [
        r'^string',  # String
        r'^\w+\s*\[\s*\]',  # Array
        r'^mapping',  # Mapping
        r'^struct',  # Struct
        r'^bytes\s*\[\s*\]',  # Byte array
        r'^address\s+\[\s*\]'  # Address array
    ]
    return any(re.match(pattern, var_type.strip()) for pattern in reference_patterns)


def get_constructor_code(cleaned_code, contract_ranges):
    """Extract constructor code (used to check if initialization occurs in the constructor)"""
    constructor_code = []
    # Match constructor
    constructor_pattern = r'constructor\s*\([^)]*\)\s*(public)?\s*\{[^}]*\}'
    matches = re.finditer(constructor_pattern, cleaned_code, flags=re.DOTALL)

    for match in matches:
        # Ensure the constructor is within the contract range
        if any(start <= match.start() <= end for start, end in contract_ranges):
            constructor_code.append(match.group(0))

    return '\n'.join(constructor_code)


def is_initialized_in_constructor(var_name, constructor_code):
    """Check if a variable is initialized in the constructor"""
    if not constructor_code:
        return False

    # Match assignments in the constructor (e.g., var = ...;)
    init_patterns = [
        rf'\b{var_name}\s*=',  # Direct assignment
        rf'\b{var_name}\s*\[\s*\]\s*=',  # Array assignment
        rf'\b{var_name}\s*\.\s*\w+\s*='  # Struct member assignment
    ]

    return any(re.search(pattern, constructor_code) for pattern in init_patterns)


def check_uninitialized_state_variables(solidity_code):
    """Detect uninitialized state variable vulnerability (SWC-100)"""
    vulnerabilities = []
    cleaned_code = remove_comments_and_strings(solidity_code)
    if not cleaned_code:
        return vulnerabilities

    # Create line number mapping
    line_mapping = []
    original_lines = solidity_code.split('\n')
    cleaned_lines = cleaned_code.split('\n')
    original_idx = 0

    for cleaned_line in cleaned_lines:
        while original_idx < len(original_lines):
            processed_original = remove_comments_and_strings(original_lines[original_idx]).strip()
            if processed_original == cleaned_line.strip():
                line_mapping.append(original_idx + 1)  # Line numbers start from 1
                original_idx += 1
                break
            original_idx += 1
        else:
            line_mapping.append(line_mapping[-1] if line_mapping else None)

    # Identify contract and function ranges
    contract_ranges = find_contract_ranges(cleaned_code)
    function_ranges = find_function_ranges(cleaned_code, contract_ranges)
    constructor_code = get_constructor_code(cleaned_code, contract_ranges)

    # Match state variable definitions (excluding local variables inside functions)
    # State variable pattern: type + variable name (may include modifiers)
    var_pattern = r'(?:(public|private|internal|external)\s+)?([a-zA-Z_][a-zA-Z0-9_]*\s*(?:\[\s*\])?)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:=|;)'
    matches = re.finditer(var_pattern, cleaned_code)

    detected_vars = set()

    for match in matches:
        var_start = match.start()
        var_end = match.end()

        # Filter condition 1: must be within the contract range
        in_contract = any(start <= var_start <= end for start, end in contract_ranges)
        if not in_contract:
            continue

        # Filter condition 2: cannot be within function range (exclude local variables)
        in_function = any(start <= var_start <= end for start, end in function_ranges)
        if in_function:
            continue

        # Filter condition 3: exclude constants and immutable variables (they must be initialized)
        var_declaration = cleaned_code[var_start:var_end]
        if 'constant' in var_declaration or 'immutable' in var_declaration:
            continue

        # Extract variable information
        visibility = match.group(1) or 'internal'
        var_type = match.group(2).strip()
        var_name = match.group(3).strip()

        # Check if initialized during declaration
        declared_with_init = '=' in var_declaration

        # Check if initialized in constructor
        initialized_in_constructor = is_initialized_in_constructor(var_name, constructor_code)

        # Uninitialized condition
        if not declared_with_init and not initialized_in_constructor:
            # Calculate the original line number
            cleaned_line_num = cleaned_code[:var_start].count('\n') + 1
            original_line_num = line_mapping[cleaned_line_num - 1] if (
                        cleaned_line_num - 1 < len(line_mapping)) else None

            if (var_name, original_line_num) in detected_vars:
                continue

            # Risk level: reference types are riskier
            risk_level = "High" if is_reference_type(var_type) else "Medium"

            vulnerabilities.append({
                "type": f"Uninitialized state variable (SWC-100)",
                "line": original_line_num,
                "code": var_declaration.strip().rstrip(';').rstrip('='),
                "variable": var_name,
                "type": var_type,
                "risk": risk_level,
                "description": f"Uninitialized {risk_level.lower()} risk state variable '{var_name}' (type: {var_type}). "
                               f"Reference types default to zero address which may lead to unexpected behavior."
            })
            detected_vars.add((var_name, original_line_num))

    return vulnerabilities


def check_solidity_file(file_path):
    """Check a single Solidity file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            solidity_code = file.read()

        return check_uninitialized_state_variables(solidity_code)
    except Exception as e:
        print(f"Error processing file {file_path}: {str(e)}")
        return []


def check_all_files_in_directory(input_directory, output_directory):
    """Bulk check Solidity files in a directory"""
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    for filename in os.listdir(input_directory):
        if filename.endswith(".sol"):
            file_path = os.path.join(input_directory, filename)
            print(f"Checking file: {filename}")
            vulnerabilities = check_solidity_file(file_path)

            output_file_path = os.path.join(output_directory, f"{filename}.swc100.txt")
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                if vulnerabilities:
                    output_file.write(
                        f"Found {len(vulnerabilities)} potential SWC-100 vulnerabilities in {filename}:\n")
                    output_file.write("=" * 80 + "\n")

                    for i, vuln in enumerate(vulnerabilities, 1):
                        output_file.write(f"Vulnerability #{i}:\n")
                        output_file.write(f"Type: {vuln['type']}\n")
                        output_file.write(f"Line: {vuln['line']}\n")
                        output_file.write(f"Variable: {vuln['variable']}\n")
                        output_file.write(f"Type: {vuln['type']}\n")
                        output_file.write(f"Risk Level: {vuln['risk']}\n")
                        output_file.write(f"Code: {vuln['code']}\n")
                        output_file.write(f"Description: {vuln['description']}\n")
                        output_file.write("-" * 80 + "\n")
                else:
                    output_file.write(f"No SWC-100 vulnerabilities detected in {filename}\n")


if __name__ == "__main__":
    # Configure paths
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-100'))

    # Verify paths exist
    if not os.path.exists(input_directory_path):
        print(f"Error: Input directory does not exist - {input_directory_path}")
    else:
        print(f"Starting SWC-100 detection...")
        print(f"Input directory: {input_directory_path}")
        print(f"Output directory: {output_directory_path}")

        check_all_files_in_directory(input_directory_path, output_directory_path)
        print("Detection completed.")
