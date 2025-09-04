import os
import re


def remove_comments_and_strings(solidity_code):
    """Remove comments and strings to avoid interference in detection"""
    # Remove strings (single and double quotes, handle escape characters)
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', solidity_code)
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)

    # Remove single-line comments
    code = re.sub(r'//.*', '', code)

    # Remove multi-line comments (handle nested comments)
    while re.search(r'/\*.*?\*/', code, flags=re.DOTALL):
        code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)

    return code


def find_matching_delimiter(code, start_pos, opening='(', closing=')'):
    """Find matching delimiters (brackets/braces), supports nesting"""
    count = 1
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


def parse_condition(condition):
    """Parse the condition expression and recognize logical structures (handle &&, || and other composite conditions)"""
    # Remove spaces
    stripped = re.sub(r'\s+', '', condition)

    # Split composite conditions
    if '&&' in stripped:
        return [part.strip() for part in re.split(r'&&', condition)]
    elif '||' in stripped:
        return [part.strip() for part in re.split(r'\|\|', condition)]
    return [condition.strip()]


def is_trivial_condition(condition):
    """Improved version: Determine if the condition is always true/false (reduce false positives for composite conditions)"""
    conditions = parse_condition(condition)

    # Check if all sub-conditions are always true (overall true)
    all_trivial_true = True
    # Check if there are any always false sub-conditions (overall false)
    has_trivial_false = False

    trivial_true_patterns = {
        r'^true$',
        r'^\d+\s*==\s*\1$',  # 1==1, 5==5
        r'^\d+\s*<=\s*\d+(?=\D|$)',  # 3<=5
        r'^\d+\s*>=\s*\d+(?=\D|$)',  # 5>=3
        r'^[a-zA-Z_]+\s*==\s*[a-zA-Z_]+$'  # Variable self-comparison (x==x)
    }

    trivial_false_patterns = {
        r'^false$',
        r'^\d+\s*==\s*\d+(?!\1)(?=\D|$)',  # 1==2
        r'^\d+\s*<\s*\d+(?=\D|$)',  # 5<3
        r'^\d+\s*>\s*\d+(?=\D|$)'  # 3>5
    }

    for cond in conditions:
        stripped_cond = re.sub(r'\s+', '', cond)
        is_true = any(re.match(pattern, stripped_cond) for pattern in trivial_true_patterns)
        is_false = any(re.match(pattern, stripped_cond) for pattern in trivial_false_patterns)

        if not is_true:
            all_trivial_true = False
        if is_false:
            has_trivial_false = True

    if all_trivial_true:
        return True, "Condition is always true (trivial)"
    if has_trivial_false:
        return True, "Condition contains always false sub-expression"

    return False, ""


def get_function_context(cleaned_code, position):
    """Enhanced version: Get the function context (including modifiers, visibility, and parameters)"""
    # Find the nearest function definition
    func_pattern = r'function\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\('
    func_matches = list(re.finditer(func_pattern, cleaned_code))

    # Find the function that contains the current position
    target_func = None
    for match in reversed(func_matches):
        if match.start() < position:
            # Find the function start position
            func_start = match.start()
            param_start = cleaned_code.find('(', func_start)
            param_end = find_matching_delimiter(cleaned_code, param_start)
            if not param_end:
                continue

            # Find the function body start position
            body_start = cleaned_code.find('{', param_end)
            if body_start == -1:
                continue

            # Find the function body end position
            body_end = find_matching_delimiter(cleaned_code, body_start, '{', '}')
            if body_end and func_start < position < body_end:
                # Extract the full function definition
                target_func = {
                    'start': func_start,
                    'end': body_end,
                    'code': cleaned_code[func_start:body_end + 1],
                    'params': extract_function_parameters(cleaned_code[func_start:param_end + 1])
                }
                # Extract visibility and modifiers
                visibility_match = re.search(r'(external|public|internal|private)\b', target_func['code'])
                target_func['visibility'] = visibility_match.group(1) if visibility_match else 'public'

                # Extract function modifiers (for access control checks)
                modifier_match = re.search(r'function\s+[^\(]+\([^)]*\)\s*([^]*?)\{', target_func['code'])
                target_func['modifiers'] = modifier_match.group(1).strip() if modifier_match else ''
                break

    return target_func


def extract_function_parameters(func_signature):
    """Improved version: Extract function parameters (supports arrays, mappings, custom types)"""
    params = []
    # Extract the parameters inside the parentheses
    param_match = re.search(r'\((.*)\)', func_signature)
    if not param_match:
        return params

    param_str = param_match.group(1).strip()
    if not param_str:
        return params

    # Handle complex parameters (with nested parentheses)
    param_parts = []
    bracket_count = 0
    current_part = []

    for char in param_str:
        if char == ',' and bracket_count == 0:
            param_parts.append(''.join(current_part).strip())
            current_part = []
        else:
            current_part.append(char)
            if char == '(':
                bracket_count += 1
            elif char == ')':
                bracket_count -= 1

    if current_part:
        param_parts.append(''.join(current_part).strip())

    # Parse each parameter
    for part in param_parts:
        # Handle pointers and arrays
        part = re.sub(r'\s+', ' ', part)
        # Split type and name (find the last space)
        split_idx = part.rfind(' ')
        if split_idx == -1:
            continue

        param_type = part[:split_idx].strip()
        param_name = part[split_idx:].strip()
        params.append((param_name, param_type))

    return params


def has_missing_access_control(condition, function_context):
    """Enhanced version: Check for missing access control (based on function modifiers and conditions)"""
    # Internal functions usually do not need public access control
    if function_context['visibility'] not in ['external', 'public']:
        return False, ""

    # Check if the function modifiers include access control (like onlyOwner)
    if re.search(r'(onlyOwner|onlyAdmin|authorized|restricted)', function_context['modifiers']):
        return False, ""

    # Extended access control patterns
    access_patterns = [
        r'msg\.sender\s*==\s*[a-zA-Z0-9_]*owner',
        r'[a-zA-Z0-9_]*isOwner\(\s*\)',
        r'[a-zA-Z0-9_]*hasRole\(\s*[^,]+,\s*msg\.sender\s*\)',
        r'[a-zA-Z0-9_]*isAdmin\(\s*\)',
        r'[a-zA-Z0-9_]*isAuthorized\(\s*\)',
        r'[a-zA-Z0-9_]*hasPermission\(\s*msg\.sender\s*,\s*[^)]+\s*\)'
    ]

    # Check if the condition contains any access control patterns
    for pattern in access_patterns:
        if re.search(pattern, condition):
            return False, ""

    # Special case: constructors usually do not require access control
    if 'constructor' in function_context['code']:
        return False, ""

    return True, "Potential missing access control (no permission check for sensitive operation)"


def has_incomplete_input_validation(condition, params):
    """Enhanced version: Check for incomplete input validation (supports complex types and custom validation functions)"""
    if not params:
        return False, ""

    # Validation rules: type -> validation pattern list (supports custom validation functions)
    validation_rules = {
        # Address type validation
        r'address': [
            r'[param]\s*!=\s*address\(0\)',
            r'[param]\s*!=.*zero.*address',
            r'isValidAddress\(\s*[param]\s*\)'
        ],
        # Numeric type validation
        r'uint256|uint|int256|int': [
            r'[param]\s*<=\s*[a-zA-Z0-9_]+',
            r'[param]\s*>=',
            r'[param]\s*<',
            r'[param]\s*>',
            r'isValidAmount\(\s*[param]\s*\)'
        ],
        # Array type validation
        r'\[\]': [
            r'[param]\.length\s*>',
            r'[param]\.length\s*<',
            r'[param]\.length\s*!='
        ],
        # String type validation
        r'string': [
            r'[param]\.length\s*>',
            r'bytes\([param]\)\.length\s*<'
        ]
    }

    # Check each parameter for necessary validation
    for param_name, param_type in params:
        # Check if the parameter type requires validation
        matched = False
        for type_pattern, checks in validation_rules.items():
            if re.search(type_pattern, param_type):
                matched = True
                # Replace parameter name in validation patterns
                param_checks = [check.replace('[param]', param_name) for check in checks]
                # Check if any validation pattern matches
                if not any(re.search(check, condition) for check in param_checks):
                    return True, f"Incomplete validation for parameter '{param_name}' (type: {param_type})"

        # Special check: for parameters related to amounts (name contains 'amount' or 'value')
        if 'amount' in param_name or 'value' in param_name:
            if not re.search(rf'{param_name}\s*<=', condition) and \
                    not re.search(rf'{param_name}\s*>=', condition) and \
                    not re.search(rf'isValid.*\(\s*{param_name}\s*\)', condition):
                return True, f"Potential missing validation for value parameter '{param_name}'"

    return False, ""


def check_requirement_violations(solidity_code):
    """Improved version: Check for requirement validation defects (SWC-123)"""
    vulnerabilities = []

    # Clean the code
    cleaned_code = remove_comments_and_strings(solidity_code)
    if not cleaned_code:
        return vulnerabilities

    # Establish line mapping (more accurate mapping of original line numbers)
    line_mapping = []
    original_lines = solidity_code.split('\n')
    cleaned_lines = cleaned_code.split('\n')

    # Build the mapping of cleaned line numbers to original line numbers
    cleaned_line_to_original = []
    original_line_idx = 0

    for cleaned_line in cleaned_lines:
        # Find the corresponding line in the original code
        while original_line_idx < len(original_lines):
            processed_original = remove_comments_and_strings(original_lines[original_line_idx]).strip()
            if processed_original == cleaned_line.strip():
                cleaned_line_to_original.append(original_line_idx + 1)  # Line numbers start at 1
                original_line_idx += 1
                break
            original_line_idx += 1
        else:
            # If no corresponding line is found, use the last valid line number
            if cleaned_line_to_original:
                cleaned_line_to_original.append(cleaned_line_to_original[-1])
            else:
                cleaned_line_to_original.append(None)

    # Match require and assert statements (handle modifiers)
    validation_pattern = r'(require|assert)\s*\('
    matches = re.finditer(validation_pattern, cleaned_code)

    detected_lines = set()

    for match in matches:
        validation_type = match.group(1)
        start_pos = match.start()
        line_in_cleaned = cleaned_code[:start_pos].count('\n') + 1

        # Get the original line number
        if line_in_cleaned - 1 < len(cleaned_line_to_original):
            original_line_num = cleaned_line_to_original[line_in_cleaned - 1]
        else:
            original_line_num = None

        if original_line_num in detected_lines:
            continue

        # Find the matching right parenthesis
        end_pos = find_matching_delimiter(cleaned_code, start_pos + len(validation_type))
        if not end_pos:
            continue

        # Extract the condition and error message
        full_condition = cleaned_code[start_pos + len(validation_type) + 1: end_pos].strip()
        condition_parts = re.split(r',(?![^()]*\))', full_condition, 1)  # Do not split commas inside parentheses
        condition = condition_parts[0].strip()

        # Get function context
        function_context = get_function_context(cleaned_code, start_pos)
        if not function_context:
            continue  # Skip if function context cannot be identified

        # 1. Check for trivial conditions (always true/false)
        trivial, trivial_msg = is_trivial_condition(condition)
        if trivial:
            vulnerabilities.append({
                "type": f"Invalid {validation_type} condition (SWC-123)",
                "line": original_line_num,
                "code": f"{validation_type}({full_condition})",
                "description": trivial_msg
            })
            detected_lines.add(original_line_num)
            continue

        # 2. Check for missing access control (only for require and public/external functions)
        if validation_type == 'require':
            access_missing, access_msg = has_missing_access_control(condition, function_context)
            if access_missing:
                # Exclude false positives for view functions (usually do not need strict access control)
                if 'view' not in function_context['code'] and 'pure' not in function_context['code']:
                    vulnerabilities.append({
                        "type": f"Missing access control in {validation_type} (SWC-123)",
                        "line": original_line_num,
                        "code": f"{validation_type}({full_condition})",
                        "description": access_msg
                    })
                    detected_lines.add(original_line_num)
                    continue

        # 3. Check for incomplete input validation
        if validation_type == 'require' and function_context['params']:
            input_incomplete, input_msg = has_incomplete_input_validation(condition, function_context['params'])
            if input_incomplete:
                vulnerabilities.append({
                    "type": f"Incomplete input validation in {validation_type} (SWC-123)",
                    "line": original_line_num,
                    "code": f"{validation_type}({full_condition})",
                    "description": input_msg
                })
                detected_lines.add(original_line_num)
                continue

    return vulnerabilities


def check_solidity_file(file_path):
    """Check a single Solidity file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            solidity_code = file.read()

        return check_requirement_violations(solidity_code)
    except Exception as e:
        print(f"Error processing file {file_path}: {str(e)}")
        return []


def check_all_files_in_directory(input_directory, output_directory):
    """Batch check Solidity files in a directory"""
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    for filename in os.listdir(input_directory):
        if filename.endswith(".sol"):
            file_path = os.path.join(input_directory, filename)
            print(f"Checking file: {filename}")
            vulnerabilities = check_solidity_file(file_path)

            output_file_path = os.path.join(output_directory, f"{filename}.swc123.txt")
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                if vulnerabilities:
                    output_file.write(
                        f"Found {len(vulnerabilities)} potential SWC-123 vulnerabilities in {filename}:\n")
                    output_file.write("=" * 80 + "\n")

                    for i, vuln in enumerate(vulnerabilities, 1):
                        output_file.write(f"Vulnerability #{i}:\n")
                        output_file.write(f"Type: {vuln['type']}\n")
                        output_file.write(f"Line: {vuln['line']}\n")
                        output_file.write(f"Code: {vuln['code']}\n")
                        output_file.write(f"Description: {vuln['description']}\n")
                        output_file.write("-" * 80 + "\n")
                else:
                    output_file.write(f"No SWC-123 vulnerabilities detected in {filename}\n")


if __name__ == "__main__":
    # Configure paths
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-123'))

    # Verify if the paths exist
    if not os.path.exists(input_directory_path):
        print(f"Error: Input directory does not exist - {input_directory_path}")
    else:
        print(f"Starting SWC-123 detection (improved accuracy)...")
        print(f"Input directory: {input_directory_path}")
        print(f"Output directory: {output_directory_path}")

        check_all_files_in_directory(input_directory_path, output_directory_path)
        print("Detection completed.")
