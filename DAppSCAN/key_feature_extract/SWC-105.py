import os
import re

# Sensitive operations list: Expand more high-risk functions
SENSITIVE_OPERATIONS = [
    'setAdmin', 'transferOwnership', 'withdraw', 'destroyContract', 'mintTokens',
    'releaseFunds', 'payout', 'upgradeContract', 'mint', 'burn', 'approve',
    'transferFrom', 'addMinter', 'removeMinter', 'transferEth', 'sendFunds',
    'rescueTokens', 'setFeeCollector', 'updatePermissions', 'executeTransaction'
]

# Sensitive variables list: Add more key state variables
SENSITIVE_VARIABLES = [
    'admin', 'owner', 'funds', 'userFunds', 'totalSupply', 'contractUpgrader',
    'feeCollector', 'paused', 'governance', 'minter', 'treasury'
]

# Permission check patterns: Enhance regex to cover more scenarios
PERMISSION_CHECK_PATTERNS = [
    # Modifiers (including custom permission modifiers)
    r'\b(onlyOwner|onlyAdmin|onlyMinter|onlyGovernance|onlyTreasury|restricted)\b',
    # Permission check functions (supporting parameterized cases)
    r'\b(hasRole|isAuthorized|checkPermissions|hasPermission)\s*\([^)]*\)',
    # Direct permission checks (supporting space variations in parentheses)
    r'require\s*\(\s*msg\.sender\s*==\s*(admin|owner|governance|treasury)\s*\)',
    r'require\s*\(\s*(admin|owner|governance|treasury)\s*==\s*msg\.sender\s*\)',
    # Role checks (like AccessControl's hasRole)
    r'require\s*\(\s*hasRole\s*\([^,]+,\s*msg\.sender\s*\)\s*\)'
]


def remove_comments_and_strings(code):
    """Remove comments and strings from the code to avoid interfering with syntax analysis"""
    # Remove multiline comments /* ... */ (enhanced for newline handling)
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    # Remove single-line comments // ... (including inline comments)
    code = re.sub(r'//.*', '', code)
    # Remove double-quoted strings (supports escape characters)
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', code)
    # Remove single-quoted strings
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)
    # Remove blank lines and excess spaces, compressing code for easier analysis
    code = re.sub(r'\n\s*', ' ', code)
    return code


def find_matching_brace(code, start_pos, opening='{', closing='}'):
    """Find matching braces (supports nested and multi-line cases)"""
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
    """Calculate line number from absolute position (fix boundary cases)"""
    if abs_pos < 0:
        return 1
    if abs_pos >= len(original_code):
        return original_code.count('\n') + 1
    return original_code[:abs_pos].count('\n') + 1


def extract_contracts_and_functions(cleaned_code):
    """Extract contracts and their internal functions (optimized for matching complex function definitions)"""
    contracts = []
    # Match contract definitions: supports contracts with inheritance
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

        # Match functions (supports functions with modifiers and complex visibility)
        func_pattern = r'''
            (function\s+\w+|constructor)\s*   # Function name or constructor
            \([^)]*\)\s*                     # Parameter list
            (?:modifier\d*\s*)*              # Modifiers (e.g., onlyOwner)
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


def extract_low_level_calls(func_code):
    """Extract low-level calls within a function (fixes missed cases in multi-line calls)"""
    calls = []
    # Enhance regex: supports multi-line, complex parameters, and options for low-level calls
    call_pattern = r'''
        (\w+)\s*\.\s*                     # Call target (e.g., addr, _token)
        (call|delegatecall|staticcall|send|transfer)\s*  # Low-level call type
        (?:\{[^}]*\})?\s*                 # Optional options (e.g., {gas: 1000})
        \([^)]*\)                         # Parameter list (supports multi-line)
    '''
    # Use DOTALL to ensure . matches newlines, covering multi-line calls
    for match in re.finditer(call_pattern, func_code, re.VERBOSE | re.DOTALL):
        target = match.group(1)
        call_type = match.group(2)
        # Extract the complete call snippet (for subsequent return value checks)
        call_snippet = match.group(0).strip()
        calls.append({
            'target': target,
            'type': call_type,
            'snippet': call_snippet,
            'start': match.start(),
            'end': match.end()
        })
    return calls


def check_return_value_handling(func_code, call_start, call_end):
    """Check return value handling (covers more edge cases)"""
    call_snippet = func_code[call_start:call_end].strip()
    # Extract all code after the call (used for return value handling checks)
    post_call_code = func_code[call_end:].strip()
    escaped_call = re.escape(call_snippet)

    # Extend return value check patterns to cover more scenarios
    check_patterns = [
        # 1. Direct checks (including space variations in parentheses)
        rf'if\s*\(\s*!\s*{escaped_call}\s*\)',
        rf'require\s*\(\s*{escaped_call}\s*,\s*[^)]*\)',  # require with error message
        rf'assert\s*\(\s*{escaped_call}\s*\)',

        # 2. Check after assignment (supports different variable names and spaces)
        rf'bool\s+\w+\s*=\s*{escaped_call}\s*;.*?if\s*\(\s*!\w+\s*\)',
        rf'(bytes4|uint256|bytes)\s+\w+\s*=\s*{escaped_call}\s*;.*?if\s*\(\s*\w+\s*==\s*0\s*\)',  # Check for bytes4 return value

        # 3. Logical operations (supports short-circuit logic)
        rf'{escaped_call}\s*&&\s*.*?;',
        rf'!\s*{escaped_call}\s*\|\|\s*.*?;',

        # 4. Early return (e.g., return call();)
        rf'return\s+{escaped_call}\s*;',

        # 5. Ternary operation (e.g., call() ? x : revert();)
        rf'{escaped_call}\s*\?\s*[^:]+:\s*revert\s*\('
    ]

    # Check if any of the above patterns are present in the code after the call
    for pattern in check_patterns:
        if re.search(pattern, post_call_code, flags=re.DOTALL | re.IGNORECASE):
            return True

    # Special case: variable defined before the call, checked after (multi-line)
    pre_call_code = func_code[:call_start].strip()
    var_match = re.search(r'(\w+)\s*=\s*.*?;', pre_call_code)
    if var_match:
        var_name = var_match.group(1)
        if re.search(rf'if\s*\(\s*!\s*{var_name}\s*\)', post_call_code, re.DOTALL):
            return True

    return False


def has_permission_check(code_segment):
    """Check permission control (fixes missing checks for custom permission functions)"""
    for pattern in PERMISSION_CHECK_PATTERNS:
        if re.search(pattern, code_segment, re.IGNORECASE | re.DOTALL):
            return True
    # Check permission control in function modifiers (e.g., function xxx() onlyOwner { ... })
    if re.search(r'\b(onlyOwner|onlyAdmin|onlyGovernance)\b', code_segment):
        return True
    return False


def is_sensitive_operation(func_name):
    """Determine if it's a sensitive operation (supports partial matching)"""
    return any(op.lower() in func_name.lower() for op in SENSITIVE_OPERATIONS)


def is_external_target(target, contract_functions, func_code):
    """Determine if it's an external call (reduces false positives for internal calls)"""
    # Exclude contract functions (e.g., this.transfer or internal functions)
    if any(func['name'].lower() == target.lower() for func in contract_functions):
        return False
    # Exclude contract address (e.g., address(this) or payable(this))
    if re.search(r'address\(\s*this\s*\)', target) or re.search(r'payable\(\s*this\s*\)', target):
        return False
    # Exclude known internal variables (e.g., _self, _this)
    if re.search(r'\b(_self|_this|_contract)\b', target) and re.search(r'_self\s*=\s*address\(this\)', func_code):
        return False
    return True


def detect_swc105(file_path):
    """Detect SWC-105 vulnerabilities (fixes missed detection issues)"""
    vulnerabilities = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_code = f.read()

        cleaned_code = remove_comments_and_strings(original_code)
        contracts = extract_contracts_and_functions(cleaned_code)

        for contract in contracts:
            contract_functions = contract['functions']
            contract_start = contract['start']

            for func in contract_functions:
                func_code = func['code']
                func_name = func['name']
                func_start_in_contract = func['start_in_contract']

                # Extract low-level calls (including multi-line calls)
                low_level_calls = extract_low_level_calls(func_code)
                for call in low_level_calls:
                    target = call['target']
                    call_type = call['type']
                    call_start = call['start']
                    call_end = call['end']

                    # Only detect external calls (internal calls have lower risk)
                    if not is_external_target(target, contract_functions, func_code):
                        continue

                    # Check if return value is handled (core logic)
                    return_handled = check_return_value_handling(func_code, call_start, call_end)
                    if not return_handled:
                        # Sensitive operation check
                        sensitive = is_sensitive_operation(func_name)
                        # Permission check (including function modifiers)
                        has_perm_check = has_permission_check(func_code[:call_start])

                        # Risk level classification
                        risk_level = "Critical" if (sensitive and not has_perm_check) else \
                            "High" if (sensitive or not has_perm_check) else "Medium"

                        # Calculate line number (fixes offset issues)
                        abs_call_start = contract_start + func_start_in_contract + call_start
                        line_number = get_line_number(original_code, abs_call_start)

                        # Build description
                        desc_parts = [
                            f"Unchecked low-level {call_type}() to external target `{target}`. "
                            f"Return value not verified, which may allow silent failures."
                        ]
                        if sensitive:
                            desc_parts.append(
                                f"Function `{func_name}` involves sensitive operations (e.g., fund transfers or permission changes).")
                        if not has_perm_check:
                            desc_parts.append(
                                "No permission checks detected before this call, increasing attack surface.")

                        vulnerabilities.append({
                            'type': 'SWC-105',
                            'contract': contract['name'],
                            'function': func_name,
                            'call_type': call_type,
                            'target': target,
                            'risk_level': risk_level,
                            'line': line_number,
                            'code_snippet': call['snippet'],
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
        issues = detect_swc105(file_path)

        output_file = os.path.join(output_dir, f"{os.path.splitext(filename)[0]}_swc105_report.txt")
        with open(output_file, 'w', encoding='utf-8') as f:
            if issues:
                vulnerable_files += 1
                f.write(f"SWC-105 Vulnerability Report for {filename}\n")
                f.write("=" * 80 + "\n")
                f.write(f"Total issues found: {len(issues)}\n\n")

                for i, issue in enumerate(issues, 1):
                    f.write(f"Issue #{i} (Risk: {issue['risk_level']})\n")
                    f.write(f"Contract: {issue['contract']}\n")
                    f.write(f"Function: {issue['function']}\n")
                    f.write(f"Call Type: {issue['call_type']}\n")
                    f.write(f"Target: {issue['target']}\n")
                    f.write(f"Line: {issue['line']}\n")
                    f.write(f"Code Snippet: {issue['code_snippet']}\n")
                    f.write(f"Description: {issue['description']}\n\n")
                    f.write("-" * 80 + "\n\n")
            else:
                f.write(f"No SWC-105 issues detected in {filename}.\n")

    print(f"\nAnalysis Complete:")
    print(f"Total files processed: {total_files}")
    print(f"Files with SWC-105 issues: {vulnerable_files}")
    print(f"Reports saved to: {os.path.abspath(output_dir)}")


if __name__ == "__main__":
    # Configure input/output paths (modify based on actual needs)
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-105'))

    if not os.path.exists(input_directory_path):
        print(f"Error: Input directory not found - {input_directory_path}")
        print("Please create the directory or update the path in the script.")
    else:
        batch_analyze(input_directory_path, output_directory_path)
