import os
import re


def remove_comments_and_strings(solidity_code):
    """Remove comments and strings to avoid interference with detection"""
    # Remove strings (single and double quotes, handle escape characters)
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', solidity_code)
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)

    # Remove single-line comments
    code = re.sub(r'//.*', '', code)

    # Remove multi-line comments (handle nested)
    while re.search(r'/\*.*?\*/', code, flags=re.DOTALL):
        code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)

    return code


def find_matching_delimiter(code, start_pos, opening='{', closing='}'):
    """Find matching delimiter (supports nested structures)"""
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


def get_function_context(cleaned_code, position):
    """Enhanced: Get function context (visibility, parameters, modifiers)"""
    # Find the function containing the current position
    func_pattern = r'function\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\('
    func_matches = list(re.finditer(func_pattern, cleaned_code))

    for match in reversed(func_matches):
        if match.start() < position:
            func_start = match.start()
            param_start = cleaned_code.find('(', func_start)
            param_end = find_matching_delimiter(cleaned_code, param_start, '(', ')')
            if not param_end:
                continue

            body_start = cleaned_code.find('{', param_end)
            if body_start == -1:
                continue

            body_end = find_matching_delimiter(cleaned_code, body_start)
            if body_end and func_start < position < body_end:
                # Extract function visibility
                visibility_match = re.search(
                    r'(external|public|internal|private)\b',
                    cleaned_code[func_start:param_end]
                )
                return {
                    'visibility': visibility_match.group(1) if visibility_match else 'public',
                    'is_view': 'view' in cleaned_code[func_start:param_end],
                    'is_pure': 'pure' in cleaned_code[func_start:param_end]
                }
    return {'visibility': 'public', 'is_view': False, 'is_pure': False}


def get_solidity_version(solidity_code):
    """Identify Solidity version (used to adapt to different return value formats)"""
    version_match = re.search(r'pragma\s+solidity\s+([\^~>=<]+?)\s*(\d+\.\d+\.\d+)', solidity_code)
    if version_match:
        return version_match.group(2)
    return None


def is_indirect_check_function(func_name):
    """Determine if the function is a common return value check function"""
    check_patterns = [
        r'check', r'verify', r'ensure', r'validate',
        r'require', r'assert', r'handle', r'process'
    ]
    return any(pattern in func_name.lower() for pattern in check_patterns)


def is_return_value_checked(cleaned_code, call_start, call_end, solidity_version):
    """Enhanced: Check if return value is handled (supports complex scenarios)"""
    # 1. Define analysis range: 10 lines before and after the call (instead of fixed character count)
    code_before = cleaned_code[:call_start].split('\n')
    code_after = cleaned_code[call_end:].split('\n')
    context_lines = code_before[-10:] + code_after[:10]
    context = '\n'.join(context_lines).lower()

    # 2. Direct check patterns (e.g., if (!call()), require(call()))
    direct_checks = [
        r'\bif\s*\(\s*!',  # if (!call())
        r'\brequire\s*\(\s*',  # require(call())
        r'\bassert\s*\(\s*',  # assert(call())
        r'==\s*false',
        r'==\s*0'
    ]
    if any(re.search(pattern, context) for pattern in direct_checks):
        return True

    # 3. Variable assignment check (supports multi-line)
    var_assign_pattern = r'(\w+)\s*=\s*[^;]+' + re.escape(cleaned_code[call_start:call_end].lower())
    var_match = re.search(var_assign_pattern, cleaned_code[:call_end].lower())
    if var_match:
        var_name = var_match.group(1)
        # Check if the variable is later verified
        var_check_patterns = [
            rf'\bif\s*\(\s*!{var_name}\s*\)',
            rf'\brequire\s*\(\s*{var_name}\s*\)',
            rf'\bassert\s*\(\s*{var_name}\s*\)',
            rf'{var_name}\s*==\s*false',
            rf'{var_name}\s*==\s*0'
        ]
        if any(re.search(pattern, context) for pattern in var_check_patterns):
            return True

    # 4. Indirect check (through custom functions)
    indirect_check_pattern = r'(\w+)\s*\(\s*[^;]+' + re.escape(cleaned_code[call_start:call_end].lower()) + r'\s*\)'
    indirect_match = re.search(indirect_check_pattern, cleaned_code[:call_end + 200].lower())
    if indirect_match and is_indirect_check_function(indirect_match.group(1)):
        return True

    # 5. Adapt to tuple return values for version 0.8.0+ (e.g., (bool success, ...))
    if solidity_version and tuple(int(v) for v in solidity_version.split('.')) >= (0, 8, 0):
        tuple_pattern = r'\(\s*(bool\s+\w+)\s*,\s*[^)]*\)\s*=\s*' + re.escape(cleaned_code[call_start:call_end].lower())
        tuple_match = re.search(tuple_pattern, cleaned_code[:call_end].lower())
        if tuple_match:
            var_name = tuple_match.group(1).split()[-1]
            if re.search(rf'\bif\s*\(\s*!{var_name}\s*\)', context) or \
                    re.search(rf'\brequire\s*\(\s*{var_name}\s*\)', context):
                return True

    return False


def check_unchecked_call_return_values(solidity_code):
    """Enhanced: Detect unchecked call return value vulnerabilities (SWC-129)"""
    vulnerabilities = []
    cleaned_code = remove_comments_and_strings(solidity_code)
    if not cleaned_code:
        return vulnerabilities

    # Identify Solidity version
    solidity_version = get_solidity_version(solidity_code)

    # Create more accurate line number mapping
    line_mapping = []
    original_lines = solidity_code.split('\n')
    cleaned_lines = cleaned_code.split('\n')
    original_idx = 0

    for cleaned_line in cleaned_lines:
        while original_idx < len(original_lines):
            processed_original = remove_comments_and_strings(original_lines[original_idx]).strip()
            if processed_original == cleaned_line.strip():
                line_mapping.append(original_idx + 1)  # Line number starts from 1
                original_idx += 1
                break
            original_idx += 1
        else:
            line_mapping.append(line_mapping[-1] if line_mapping else None)

    # Enhanced call pattern matching (supports complex parameters, named parameters, and newlines)
    call_patterns = [
        # Basic calls: .call()/.delegatecall() etc.
        r'\.(call|delegatecall|staticcall|send)\s*\([^)]*\)',
        # Calls with named parameters: .call{value: ...}()
        r'\.(call|delegatecall|staticcall)\s*\{[^}]+\}\s*\([^)]*\)'
    ]
    combined_pattern = r'|'.join(call_patterns)
    matches = re.finditer(combined_pattern, cleaned_code, flags=re.DOTALL)

    detected_lines = set()

    for match in matches:
        call_start = match.start()
        call_end = match.end()
        call_text = match.group(0).strip()

        # Get function context for the call
        func_context = get_function_context(cleaned_code, call_start)

        # Lower priority for internal functions and view/pure functions
        if func_context['visibility'] in ['internal', 'private'] or \
                func_context['is_view'] or func_context['is_pure']:
            # Risk is lower in these functions, require stricter unchecked evidence
            min_risk = True
        else:
            min_risk = False

        # Calculate original line number
        cleaned_line_num = cleaned_code[:call_start].count('\n') + 1
        original_line_num = line_mapping[cleaned_line_num - 1] if (cleaned_line_num - 1 < len(line_mapping)) else None

        if original_line_num in detected_lines:
            continue

        # Check if return value is handled
        if not is_return_value_checked(cleaned_code, call_start, call_end, solidity_version):
            # Determine call type
            call_type = re.search(r'\.(call|delegatecall|staticcall|send)', call_text).group(1)

            # For low-risk scenarios, only report high-certainty vulnerabilities
            if not min_risk or (min_risk and 'call' in call_type):
                vulnerabilities.append({
                    "type": f"Unchecked {call_type} return value (SWC-129)",
                    "line": original_line_num,
                    "code": call_text,
                    "description": f"Potential risk: {call_type} return value is not checked, which could hide failures. Solidity version: {solidity_version or 'unknown'}"
                })
                detected_lines.add(original_line_num)

    return vulnerabilities


def check_solidity_file(file_path):
    """Check a single Solidity file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            solidity_code = file.read()

        return check_unchecked_call_return_values(solidity_code)
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

            output_file_path = os.path.join(output_directory, f"{filename}.swc129.txt")
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                if vulnerabilities:
                    output_file.write(
                        f"Found {len(vulnerabilities)} potential SWC-129 vulnerabilities in {filename}:\n")
                    output_file.write("=" * 80 + "\n")

                    for i, vuln in enumerate(vulnerabilities, 1):
                        output_file.write(f"Vulnerability #{i}:\n")
                        output_file.write(f"Type: {vuln['type']}\n")
                        output_file.write(f"Line: {vuln['line']}\n")
                        output_file.write(f"Code: {vuln['code']}\n")
                        output_file.write(f"Description: {vuln['description']}\n")
                        output_file.write("-" * 80 + "\n")
                else:
                    output_file.write(f"No SWC-129 vulnerabilities detected in {filename}\n")


if __name__ == "__main__":
    # Configure paths
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-129'))

    # Verify directory existence
    if not os.path.exists(input_directory_path):
        print(f"Error: Input directory does not exist - {input_directory_path}")
    else:
        print(f"Starting enhanced SWC-129 detection...")
        print(f"Input directory: {input_directory_path}")
        print(f"Output directory: {output_directory_path}")

        check_all_files_in_directory(input_directory_path, output_directory_path)
        print("Detection completed.")
