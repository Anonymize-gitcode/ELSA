import os
import re
import string


def remove_comments_and_strings(solidity_code):
    """Remove comments but keep strings (since strings may contain sensitive data)"""
    # First, save the position of the strings for later restoration
    string_matches = []
    code = solidity_code

    # Extract double-quoted strings
    pattern = r'"(?:\\.|[^"\\])*"'
    for match in re.finditer(pattern, code):
        string_matches.append((match.start(), match.end(), match.group(0)))
    code = re.sub(pattern, '""', code)  # Placeholder with empty string

    # Extract single-quoted strings
    pattern = r"'(?:\\.|[^'\\])*'"
    for match in re.finditer(pattern, code):
        string_matches.append((match.start(), match.end(), match.group(0)))
    code = re.sub(pattern, "''", code)  # Placeholder with empty string

    # Remove single-line comments
    code = re.sub(r'//.*', '', code)

    # Remove multi-line comments
    while re.search(r'/\*.*?\*/', code, flags=re.DOTALL):
        code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)

    # Restore strings
    for start, end, value in sorted(string_matches, key=lambda x: -x[0]):
        code = code[:start] + value + code[end:]

    return code


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


def extract_contracts(cleaned_code):
    """Extract contract information (name and code range)"""
    contracts = []
    contract_pattern = r'(contract|library|interface)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*(is\s+[a-zA-Z_,\s]+)?\s*\{?'
    matches = re.finditer(contract_pattern, cleaned_code)

    for match in matches:
        start = match.start()
        end = find_matching_delimiter(cleaned_code, start, '{', '}')
        if end:
            contracts.append((start, end))

    return contracts


def extract_state_variables(cleaned_code, contract_ranges):
    """Extract state variables from contracts (may store sensitive data)"""
    variables = []
    # Match state variable definitions (with visibility modifiers)
    var_pattern = r'(?:(public|private|internal|external)\s+)?([a-zA-Z_][a-zA-Z0-9_]*\s*(?:\[\s*\])?)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(=.*?)?;'
    matches = re.finditer(var_pattern, cleaned_code)

    for match in matches:
        var_start = match.start()
        var_end = match.end()

        # Check if the variable is within the contract range and not within a function
        in_contract = any(start <= var_start <= end for start, end in contract_ranges)
        if not in_contract:
            continue

        # Check if it is inside a function (exclude local variables)
        in_function = False
        func_pattern = r'function\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\([^)]*\)\s*\{?'
        func_matches = re.finditer(func_pattern, cleaned_code)
        for func_match in func_matches:
            func_start = func_match.start()
            func_end = find_matching_delimiter(cleaned_code, func_start, '{', '}')
            if func_end and func_start < var_start < func_end:
                in_function = True
                break

        if in_function:
            continue

        # Extract variable information
        visibility = match.group(1) or 'internal'
        var_type = match.group(2).strip()
        var_name = match.group(3).strip()
        var_value = match.group(4) or ''  # Variable initialization value

        variables.append({
            'name': var_name,
            'type': var_type,
            'visibility': visibility,
            'value': var_value.strip('=').strip(),
            'start': var_start,
            'end': var_end
        })

    return variables


def extract_string_literals(cleaned_code):
    """Extract string literals from the code (may contain sensitive data)"""
    strings = []
    # Match double-quoted strings
    pattern = r'"(?:\\.|[^"\\])*"'
    for match in re.finditer(pattern, cleaned_code):
        value = match.group(0)[1:-1]  # Remove quotes
        if value:  # Non-empty strings
            strings.append({
                'value': value,
                'type': 'string',
                'start': match.start(),
                'end': match.end()
            })

    # Match single-quoted strings
    pattern = r"'(?:\\.|[^'\\])*'"
    for match in re.finditer(pattern, cleaned_code):
        value = match.group(0)[1:-1]  # Remove quotes
        if value:  # Non-empty strings
            strings.append({
                'value': value,
                'type': 'string',
                'start': match.start(),
                'end': match.end()
            })

    return strings


def extract_bytes_literals(cleaned_code):
    """Extract byte literals from the code (may contain sensitive data)"""
    bytes_data = []
    # Match bytes and bytesN type constants
    pattern = r'bytes(?:\d+)?\s+constant\s+[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*0x[0-9a-fA-F]+;'
    for match in re.finditer(pattern, cleaned_code):
        # Extract variable name and value
        var_name_match = re.search(r'[a-zA-Z_][a-zA-Z0-9_]*\s*=', match.group(0))
        value_match = re.search(r'0x[0-9a-fA-F]+', match.group(0))

        if var_name_match and value_match:
            var_name = var_name_match.group(0).strip('=').strip()
            value = value_match.group(0)
            bytes_data.append({
                'name': var_name,
                'value': value,
                'type': 'bytes',
                'start': match.start(),
                'end': match.end()
            })

    # Match directly used bytes literals
    pattern = r'0x[0-9a-fA-F]{2,}'  # At least 2 hexadecimal characters
    for match in re.finditer(pattern, cleaned_code):
        # Exclude addresses (42 characters, 0x + 40) and hashes (66 characters, 0x + 64)
        value = match.group(0)
        if len(value) != 42 and len(value) != 66:
            bytes_data.append({
                'name': None,
                'value': value,
                'type': 'bytes_literal',
                'start': match.start(),
                'end': match.end()
            })

    return bytes_data


def is_sensitive_variable_name(var_name):
    """Determine if a variable name may store sensitive data"""
    sensitive_patterns = [
        r'private', r'secret', r'key', r'password', r'pass',
        r'api', r'token', r'credential', r'auth', r'secret',
        r'pvt', r'priv', r' mnemonic', r'seed', r'cert',
        r'identity', r'_ssn', r'_id', r'card', r'bank'
    ]
    return any(pattern in var_name.lower() for pattern in sensitive_patterns)


def is_sensitive_data(value, data_type):
    """Determine if the content is sensitive data"""
    if not value:
        return False, None

    # 1. Private key pattern (64 hexadecimal characters)
    if re.fullmatch(r'^[0-9a-fA-F]{64}$', value) or \
            re.fullmatch(r'^0x[0-9a-fA-F]{64}$', value):
        return True, "Private key (64 hex characters)"

    # 2. API key/token pattern (usually 32-128 alphanumeric characters)
    if re.fullmatch(r'^[A-Za-z0-9+/=]{32,128}$', value) or \
            re.fullmatch(r'^[A-Za-z0-9_\-]{32,128}$', value):
        return True, "Potential API key/token (alphanumeric string)"

    # 3. Password pattern (string with special characters)
    if len(value) >= 8 and re.search(r'[!@#$%^&*(),.?":{}|<>]', value):
        return True, "Potential password (contains special characters)"

    # 4. Mnemonic phrase pattern (12-24 words)
    words = value.split()
    if 12 <= len(words) <= 24 and all(len(word) >= 3 for word in words):
        return True, "Potential mnemonic phrase (12-24 words)"

    # 5. Email address
    if re.fullmatch(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$', value):
        return True, "Email address"

    # 6. ID/passport number
    if re.fullmatch(r'^[A-Z0-9]{8,16}$', value):
        return True, "Potential ID/passport number"

    return False, None


def get_line_number(position, code):
    """Get line number based on position"""
    return code[:position].count('\n') + 1


def check_unencrypted_private_data(solidity_code):
    """Check for unencrypted private data on the blockchain (SWC-102)"""
    vulnerabilities = []
    cleaned_code = remove_comments_and_strings(solidity_code)
    if not cleaned_code:
        return vulnerabilities

    # Extract contract ranges
    contract_ranges = extract_contracts(cleaned_code)

    # 1. Check state variables
    state_vars = extract_state_variables(cleaned_code, contract_ranges)
    for var in state_vars:
        # Risk factor 1: Variable name suggests sensitive data
        name_risk = is_sensitive_variable_name(var['name'])

        # Risk factor 2: Variable type suitable for storing sensitive data
        type_risk = var['type'] in ['string', 'bytes', 'bytes1', 'bytes2',
                                    'bytes32', 'bytes memory', 'string memory']

        # Risk factor 3: Variable value contains sensitive data
        value_risk, risk_type = is_sensitive_data(var['value'], var['type'])

        # Comprehensive judgment: High-risk variable name + suitable type, or value clearly indicates sensitive data
        if (name_risk and type_risk) or value_risk:
            line = get_line_number(var['start'], solidity_code)
            risk_level = "High" if value_risk else "Medium"
            description = f"Potential unencrypted private data in state variable '{var['name']}'. "

            if value_risk:
                description += f"Detected: {risk_type}."
            else:
                description += f"Suspicious variable name and type suggest private data storage."

            vulnerabilities.append({
                'type': 'SWC-102',
                'category': 'State variable',
                'variable': var['name'],
                'data_type': var['type'],
                'risk': risk_level,
                'line': line,
                'code': f"{var['type']} {var['name']} = {var['value'] or ''};",
                'description': description.strip()
            })

    # 2. Check string literals
    string_literals = extract_string_literals(cleaned_code)
    for str_data in string_literals:
        # Exclude obviously non-sensitive strings (like error messages, labels)
        value = str_data['value']
        if len(value) < 5:
            continue

        # Check for sensitive content
        is_sensitive, risk_type = is_sensitive_data(value, 'string')
        if is_sensitive:
            line = get_line_number(str_data['start'], solidity_code)
            vulnerabilities.append({
                'type': 'SWC-102',
                'category': 'String literal',
                'variable': None,
                'data_type': 'string',
                'risk': 'High',
                'line': line,
                'code': f'"{value[:30]}{"..." if len(value) > 30 else ""}"',
                'description': f"Unencrypted {risk_type} found in string literal"
            })

    # 3. Check byte literals
    bytes_literals = extract_bytes_literals(cleaned_code)
    for byte_data in bytes_literals:
        # Extract actual value (remove 0x prefix)
        value = byte_data['value'][2:] if byte_data['value'].startswith('0x') else byte_data['value']

        # Check for sensitive content
        is_sensitive, risk_type = is_sensitive_data(value, 'bytes')
        if is_sensitive:
            line = get_line_number(byte_data['start'], solidity_code)
            var_info = f"variable '{byte_data['name']}'" if byte_data['name'] else "literal"
            vulnerabilities.append({
                'type': 'SWC-102',
                'category': 'Bytes data',
                'variable': byte_data['name'],
                'data_type': byte_data['type'],
                'risk': 'High',
                'line': line,
                'code': f"{byte_data['value'][:30]}{'...' if len(byte_data['value']) > 30 else ''}",
                'description': f"Unencrypted {risk_type} found in bytes {var_info}"
            })

    return vulnerabilities


def check_solidity_file(file_path):
    """Check a single Solidity file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            solidity_code = file.read()

        return check_unencrypted_private_data(solidity_code)
    except Exception as e:
        print(f"Error processing file {file_path}: {str(e)}")
        return []


def check_all_files_in_directory(input_dir, output_dir):
    """Batch check Solidity files in a directory"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for filename in os.listdir(input_dir):
        if filename.endswith(".sol"):
            file_path = os.path.join(input_dir, filename)
            print(f"Checking {filename}...")
            vulns = check_solidity_file(file_path)

            output_path = os.path.join(output_dir, f"{filename}.swc102.txt")
            with open(output_path, 'w', encoding='utf-8') as f:
                if vulns:
                    f.write(f"Found {len(vulns)} SWC-102 vulnerabilities in {filename}:\n")
                    f.write("=" * 80 + "\n")
                    for i, v in enumerate(vulns, 1):
                        f.write(f"Vulnerability #{i}\n")
                        f.write(f"Type: {v['type']} ({v['category']})\n")
                        if v['variable']:
                            f.write(f"Variable: {v['variable']}\n")
                        f.write(f"Data Type: {v['data_type']}\n")
                        f.write(f"Line: {v['line']}\n")
                        f.write(f"Risk: {v['risk']}\n")
                        f.write(f"Code Snippet: {v['code']}\n")
                        f.write(f"Description: {v['description']}\n")
                        f.write("-" * 80 + "\n")
                else:
                    f.write(f"No SWC-102 vulnerabilities detected in {filename}\n")


if __name__ == "__main__":
    # Configure paths
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-102'))

    if not os.path.exists(input_dir):
        print(f"Error: Input directory not found - {input_dir}")
    else:
        print("Starting SWC-102 detection...")
        check_all_files_in_directory(input_dir, output_dir)
        print("Detection completed.")
