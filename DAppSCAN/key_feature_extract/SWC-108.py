import os
import re


def remove_comments_and_strings(solidity_code):
    """Remove comments and strings to avoid interference with detection (a key step to reduce false positives)"""
    # First remove strings (single and double quotes)
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', solidity_code)
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)

    # Remove single-line comments
    code = re.sub(r'//.*', '', code)

    # Remove multi-line comments
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)

    return code


def get_contract_structure(solidity_code):
    """Identify contract structure and mark internal ranges of structs, enums, mappings, etc. (to reduce false positives)"""
    structure = {
        'struct_ranges': [],  # Start and end positions of struct definitions
        'enum_ranges': [],  # Start and end positions of enum definitions
        'mapping_ranges': []  # Start and end positions of mapping definitions
    }

    # Match struct definitions
    struct_matches = re.finditer(r'struct\s+[^\{]+\{', solidity_code)
    for match in struct_matches:
        start = match.start()
        # Find the corresponding closing brace
        end = find_matching_brace(solidity_code, start)
        if end:
            structure['struct_ranges'].append((start, end))

    # Match enum definitions
    enum_matches = re.finditer(r'enum\s+[^\{]+\{', solidity_code)
    for match in enum_matches:
        start = match.start()
        end = find_matching_brace(solidity_code, start)
        if end:
            structure['enum_ranges'].append((start, end))

    return structure


def find_matching_brace(code, start_pos):
    """Find the matching closing brace for the starting position (handles nested structures)"""
    count = 1
    pos = start_pos
    while pos < len(code):
        pos += 1
        if pos >= len(code):
            return None
        if code[pos] == '{':
            count += 1
        elif code[pos] == '}':
            count -= 1
            if count == 0:
                return pos
    return None


def is_inside_struct_or_enum(pos, structure):
    """Determine if the position is inside a struct or enum (to exclude variables inside these ranges)"""
    for start, end in structure['struct_ranges'] + structure['enum_ranges']:
        if start <= pos <= end:
            return True
    return False


def check_state_variable_visibility(solidity_code):
    """Improved state variable visibility detection (to reduce false positives)"""
    vulnerabilities = []

    # Clean the code (remove comments and strings)
    cleaned_code = remove_comments_and_strings(solidity_code)

    # Get contract structure information (to exclude variables inside structs/enums)
    structure = get_contract_structure(cleaned_code)

    # Create line number mapping (cleaned code -> original code)
    line_mapping = []
    current_line = 1
    for line in solidity_code.split('\n'):
        processed_line = remove_comments_and_strings(line).strip()
        if processed_line:
            line_mapping.append(current_line)
        current_line += 1

    # Improved state variable matching regex
    pattern = r'(?<!function\s)(?<!event\s)(?<!struct\s)(?<!enum\s)(?<!modifier\s)' \
              r'(?<!public\s)(?<!private\s)(?<!internal\s)(?<!external\s)' \
              r'(?<!return\s)(?<!emit\s)(?<!for\s)(?<!while\s)(?<!if\s)' \
              r'([a-zA-Z_][a-zA-Z0-9_]*\s*(\[\s*\])*\s+[a-zA-Z_][a-zA-Z0-9_]*\s*[=;])'

    matches = re.finditer(pattern, cleaned_code)
    detected_lines = set()

    for match in matches:
        # Check if inside a struct or enum (to exclude these cases)
        if is_inside_struct_or_enum(match.start(), structure):
            continue

        # Calculate the line number in the cleaned code
        cleaned_line_num = cleaned_code[:match.start()].count('\n') + 1

        # Map to the original code line number
        if cleaned_line_num - 1 < len(line_mapping):
            original_line_num = line_mapping[cleaned_line_num - 1]
        else:
            original_line_num = None

        # Avoid duplicate reports
        if original_line_num in detected_lines:
            continue

        # Further validation: exclude function parameters and local variables
        code_before = cleaned_code[:match.start()]
        if re.search(r'function\s+[^\{]+\{', code_before) and '}' not in code_before.split('\n')[-1]:
            continue  # Likely a local variable inside a function

        detected_lines.add(original_line_num)
        code_snippet = match.group(0).strip().rstrip(';').rstrip('=')

        vulnerabilities.append({
            "type": "State variable with default visibility (SWC-108)",
            "line": original_line_num,
            "code": code_snippet,
            "description": "State variable does not explicitly specify visibility (defaults to internal)"
        })

    return vulnerabilities


def check_solidity_file(file_path):
    """Check a single Solidity file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            solidity_code = file.read()

        return check_state_variable_visibility(solidity_code)
    except Exception as e:
        print(f"Error processing file {file_path}: {str(e)}")
        return []


def check_all_files_in_directory(input_directory, output_directory):
    """Batch check Solidity files in the directory"""
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    for filename in os.listdir(input_directory):
        if filename.endswith(".sol"):
            file_path = os.path.join(input_directory, filename)
            print(f"Checking file: {filename}")
            vulnerabilities = check_solidity_file(file_path)

            output_file_path = os.path.join(output_directory, f"{filename}.swc108.txt")
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                if vulnerabilities:
                    output_file.write(
                        f"Found {len(vulnerabilities)} potential SWC-108 vulnerabilities in {filename}:\n")
                    output_file.write("=" * 80 + "\n")

                    for i, vuln in enumerate(vulnerabilities, 1):
                        output_file.write(f"Vulnerability #{i}:\n")
                        output_file.write(f"Type: {vuln['type']}\n")
                        output_file.write(f"Line: {vuln['line']}\n")
                        output_file.write(f"Code: {vuln['code']}\n")
                        output_file.write(f"Description: {vuln['description']}\n")
                        output_file.write("-" * 80 + "\n")
                else:
                    output_file.write(f"No SWC-108 vulnerabilities detected in {filename}\n")


if __name__ == "__main__":
    # Use your provided absolute path
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-108'))

    # Verify if paths exist
    if not os.path.exists(input_directory_path):
        print(f"Error: Input directory does not exist - {input_directory_path}")
    else:
        print(f"Starting SWC-108 detection...")
        print(f"Input directory: {input_directory_path}")
        print(f"Output directory: {output_directory_path}")

        check_all_files_in_directory(input_directory_path, output_directory_path)
        print("Detection completed.")
