import os
import re

# SWC-120: Vulnerability detection tool using tx.origin for authorization
# Vulnerability principle: tx.origin returns the original transaction sender, not the direct caller. Malicious contracts can exploit this feature to bypass authorization

# Sensitive permission verification patterns: potentially dangerous modes using tx.origin
SENSITIVE_AUTH_PATTERNS = [
    # Directly using tx.origin for permission checks
    r'require\s*\(\s*tx\.origin\s*==\s*(\w+)\s*\)',  # require(tx.origin == owner)
    r'require\s*\(\s*(\w+)\s*==\s*tx\.origin\s*\)',  # require(owner == tx.origin)
    r'if\s*\(\s*tx\.origin\s*!=\s*(\w+)\s*\)',  # if(tx.origin != admin)
    r'if\s*\(\s*(\w+)\s*!=\s*tx\.origin\s*\)',  # if(admin != tx.origin)

    # Permission checks with logical operators
    r'require\s*\(\s*tx\.origin\s*==\s*(\w+)\s*&&\s*[^)]*\)',  # tx.origin check in composite conditions
    r'require\s*\(\s*[^(]+\s*&&\s*tx\.origin\s*==\s*(\w+)\s*\)',
]

# Sensitive role variables: variables commonly used for permission verification
SENSITIVE_ROLES = [
    'owner', 'admin', 'governance', 'manager', 'operator',
    'controller', 'root', 'supervisor', 'authority'
]

# Safe authorization patterns (for comparison)
SAFE_AUTH_PATTERNS = [
    r'require\s*\(\s*msg\.sender\s*==\s*(\w+)\s*\)',  # Safe mode using msg.sender
    r'hasRole\s*\(\s*[^,]+,\s*msg\.sender\s*\)',  # Safe mode using role-based control
    r'onlyOwner\b', r'onlyAdmin\b', r'onlyGovernance\b'  # Safe modifiers
]


def remove_comments_and_strings(code):
    """Remove comments and strings from code to avoid interfering with analysis"""
    # Remove multiline comments /* ... */
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    # Remove single-line comments // ...
    code = re.sub(r'//.*', '', code)
    # Remove double-quoted strings
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', code)
    # Remove single-quoted strings
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)
    # Compress spaces and newlines
    code = re.sub(r'\s+', ' ', code).strip()
    return code


def find_matching_brace(code, start_pos, opening='{', closing='}'):
    """Find matching braces, handling nested cases"""
    if start_pos >= len(code) or code[start_pos] != opening:
        return None
    brace_count = 1
    current_pos = start_pos + 1
    while current_pos < len(code):
        if code[current_pos] == opening:
            brace_count += 1
        elif code[current_pos] == closing:
            brace_count -= 1
            if brace_count == 0:
                return current_pos
        current_pos += 1
    return None  # No matching brace found


def get_line_number(original_code, abs_pos):
    """Calculate line number based on absolute position"""
    if abs_pos < 0:
        return 1
    if abs_pos >= len(original_code):
        return original_code.count('\n') + 1
    return original_code[:abs_pos].count('\n') + 1


def extract_contracts_and_functions(cleaned_code):
    """Extract contracts and their internal function information"""
    contracts = []
    # Match contract definitions: support contracts with inheritance
    contract_pattern = r'(contract|library)\s+(\w+)\s*(?:is\s+[\w\s,]+)?\s*\{?'
    for cm in re.finditer(contract_pattern, cleaned_code):
        contract_type = cm.group(1)
        contract_name = cm.group(2)
        contract_start = cm.start()
        contract_end = find_matching_brace(cleaned_code, contract_start)
        if not contract_end:
            continue  # Skip incomplete contracts

        contract_code = cleaned_code[contract_start:contract_end + 1]
        functions = []

        # Match functions (support constructors and regular functions)
        func_pattern = r'''
            (function\s+\w+|constructor)\s*   # Function name or constructor
            \([^)]*\)\s*                     # Parameter list
            (?:modifier\d*\s*)*              # Modifiers
            (external|public|internal|private|view|pure|payable)?\s*  # Visibility
            \{?                              # Left brace
        '''
        for fm in re.finditer(func_pattern, contract_code, re.VERBOSE):
            func_start = fm.start()
            func_end = find_matching_brace(contract_code, func_start)
            if not func_end:
                continue  # Skip incomplete functions

            func_code = contract_code[func_start:func_end + 1]
            func_name = fm.group(1).split(' ')[1] if 'function' in fm.group(1) else 'constructor'
            visibility = fm.group(2) if fm.lastindex >= 2 else 'public'

            functions.append({
                'name': func_name,
                'code': func_code,
                'visibility': visibility,
                'start_in_contract': func_start,
                'end_in_contract': func_end
            })

        contracts.append({
            'name': contract_name,
            'type': contract_type,
            'functions': functions,
            'code': contract_code,
            'start': contract_start,
            'end': contract_end
        })
    return contracts


def has_safe_authorization(func_code):
    """Check if a function contains safe authorization methods"""
    for pattern in SAFE_AUTH_PATTERNS:
        if re.search(pattern, func_code, re.IGNORECASE):
            return True
    return False


def is_critical_function(func_name):
    """Determine if a function is critical (high-risk)"""
    critical_functions = [
        'transferOwnership', 'setAdmin', 'withdraw', 'mint', 'burn',
        'upgrade', 'pause', 'unpause', 'grantRole', 'revokeRole',
        'execute', 'emergencyWithdraw', 'setFee'
    ]
    return any(critical in func_name.lower() for critical in critical_functions)


def detect_swc120(file_path):
    """Detect SWC-120 vulnerability: using tx.origin for authorization"""
    vulnerabilities = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_code = f.read()

        cleaned_code = remove_comments_and_strings(original_code)
        contracts = extract_contracts_and_functions(cleaned_code)

        for contract in contracts:
            contract_functions = contract['functions']
            contract_start = contract['start']

            # Check if tx.origin is used anywhere in the contract
            if 'tx.origin' not in cleaned_code:
                continue

            for func in contract_functions:
                func_code = func['code']
                func_name = func['name']
                func_start_in_contract = func['start_in_contract']

                # Check if tx.origin is used for authorization in the function
                for pattern in SENSITIVE_AUTH_PATTERNS:
                    for match in re.finditer(pattern, func_code, re.IGNORECASE):
                        # Extract matching code snippet
                        auth_code = match.group(0).strip()
                        # Extract role variable for comparison (e.g., owner, admin)
                        role_var = match.group(1) if match.lastindex >= 1 else 'unknown'

                        # Determine if it's a sensitive role
                        is_sensitive_role = role_var in SENSITIVE_ROLES

                        # Determine if the function is critical
                        is_critical = is_critical_function(func_name)

                        # Check if there are safe authorization methods present (reduce false positives)
                        has_safe_auth = has_safe_authorization(func_code)

                        # Risk level categorization
                        if is_critical and is_sensitive_role and not has_safe_auth:
                            risk_level = "Critical"
                        elif (is_critical or is_sensitive_role) and not has_safe_auth:
                            risk_level = "High"
                        else:
                            risk_level = "Medium"

                        # Calculate line number
                        abs_call_start = contract_start + func_start_in_contract + match.start()
                        line_number = get_line_number(original_code, abs_call_start)

                        # Build description
                        desc_parts = [
                            f"Using tx.origin for authorization in `{auth_code}`. "
                            f"tx.origin is vulnerable to phishing attacks as it refers to the original transaction sender, "
                            f"not the direct caller."
                        ]
                        if is_sensitive_role:
                            desc_parts.append(f"Comparing tx.origin with sensitive role `{role_var}` increases risk.")
                        if is_critical:
                            desc_parts.append(
                                f"Function `{func_name}` is a critical operation that requires strict authorization.")
                        if has_safe_auth:
                            desc_parts.append("Note: Safe authorization methods are also present in this function.")

                        vulnerabilities.append({
                            'type': 'SWC-120',
                            'contract': contract['name'],
                            'function': func_name,
                            'risk_level': risk_level,
                            'line': line_number,
                            'code_snippet': auth_code,
                            'description': ' '.join(desc_parts)
                        })

    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")

    return vulnerabilities


def batch_analyze(input_dir, output_dir):
    """Batch analyze and generate reports"""
    os.makedirs(output_dir, exist_ok=True)
    total_files = 0
    vulnerable_files = 0

    for filename in os.listdir(input_dir):
        if not filename.endswith('.sol'):
            continue
        total_files += 1
        file_path = os.path.join(input_dir, filename)
        issues = detect_swc120(file_path)

        output_file = os.path.join(output_dir, f"{os.path.splitext(filename)[0]}_swc120_report.txt")
        with open(output_file, 'w', encoding='utf-8') as f:
            if issues:
                vulnerable_files += 1
                f.write(f"SWC-120 Vulnerability Report for {filename}\n")
                f.write("=" * 80 + "\n")
                f.write(f"Total issues found: {len(issues)}\n\n")

                for i, issue in enumerate(issues, 1):
                    f.write(f"Issue #{i} (Risk: {issue['risk_level']})\n")
                    f.write(f"Contract: {issue['contract']}\n")
                    f.write(f"Function: {issue['function']}\n")
                    f.write(f"Line: {issue['line']}\n")
                    f.write(f"Code Snippet: {issue['code_snippet']}\n")
                    f.write(f"Description: {issue['description']}\n\n")
                    f.write("-" * 80 + "\n\n")
            else:
                f.write(f"No SWC-120 issues detected in {filename}.\n")

    print(f"\nAnalysis Complete:")
    print(f"Total files processed: {total_files}")
    print(f"Files with SWC-120 issues: {vulnerable_files}")
    print(f"Reports saved to: {os.path.abspath(output_dir)}")


if __name__ == "__main__":
    # Configure input and output paths
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-120'))

    if not os.path.exists(input_directory_path):
        print(f"Error: Input directory not found - {input_directory_path}")
        print("Please create the directory or update the path in the script.")
    else:
        batch_analyze(input_directory_path, output_directory_path)
