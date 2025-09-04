import os
import re


def remove_comments_and_strings(solidity_code):
    """Remove comments and strings to avoid interference with detection"""
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', solidity_code)
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', solidity_code)
    code = re.sub(r'//.*', '', code)
    while re.search(r'/\*.*?\*/', code, flags=re.DOTALL):
        code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    return code


def find_matching_delimiter(code, start_pos, opening='{', closing='}'):
    """Find the matching delimiter (supports nesting)"""
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


def extract_contracts_and_functions(cleaned_code):
    """Extract contract and function information (including full code)"""
    contracts = []
    contract_pattern = r'(contract|library)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(is\s+[a-zA-Z_,\s]+)?\s*\{?'
    contract_matches = re.finditer(contract_pattern, cleaned_code)

    for cm in contract_matches:
        contract_start = cm.start()
        contract_end = find_matching_delimiter(cleaned_code, contract_start)
        if not contract_end:
            continue

        contract_code = cleaned_code[contract_start:contract_end + 1]
        functions = []
        func_pattern = r'(function\s+([a-zA-Z_][a-zA-Z0-9_]*|constructor)\s*\([^)]*\)\s*(external|public|internal|private)?\s*(payable)?\s*\{?)'
        func_matches = re.finditer(func_pattern, contract_code)

        for fm in func_matches:
            func_start_in_contract = fm.start()
            func_start_abs = contract_start + func_start_in_contract
            func_end_in_contract = find_matching_delimiter(contract_code, func_start_in_contract)
            if not func_end_in_contract:
                continue

            func_code = contract_code[func_start_in_contract:func_end_in_contract + 1]
            func_name = fm.group(2) or 'constructor'

            # Extract function modifiers
            modifiers = []
            mod_match = re.search(r'\)\s+([^({]+)\s*\{', func_code)
            if mod_match:
                modifiers = [m.strip() for m in mod_match.group(1).split() if m.strip()]

            functions.append({
                'name': func_name,
                'code': func_code,
                'start': func_start_abs,
                'end': contract_start + func_end_in_contract,
                'modifiers': modifiers
            })

        contracts.append({
            'name': cm.group(2),
            'code': contract_code,
            'start': contract_start,
            'end': contract_end,
            'functions': functions
        })

    return contracts


def extract_state_variables(contract):
    """Extract contract state variables (with initialization information and role tags)"""
    variables = []
    var_pattern = r'(?:(public|private|internal)\s+)?(address|address\[\])\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(=|;)'
    matches = re.finditer(var_pattern, contract['code'])

    for match in matches:
        var_decl = contract['code'][match.start():match.end()].strip()
        # Exclude local variables inside functions
        in_function = any(f['start'] - contract['start'] <= match.start() <= f['end'] - contract['start']
                          for f in contract['functions'])
        if in_function:
            continue

        visibility = match.group(1) or 'internal'
        var_type = match.group(2)
        var_name = match.group(3)

        # Extract initialization values and role tags (e.g., owner, treasury, etc.)
        init_value = None
        is_trusted_role = False
        if '=' in var_decl:
            init_match = re.search(r'=\s*(0x[0-9a-fA-F]{40}|[a-zA-Z_][a-zA-Z0-9_]*)\s*;?', var_decl)
            if init_match:
                init_value = init_match.group(1)
                # Mark trusted role variables (e.g., owner, admin, etc.)
                if any(role in var_name.lower() for role in ['owner', 'admin', 'treasury', 'governor']):
                    is_trusted_role = True

        variables.append({
            'name': var_name,
            'type': var_type,
            'visibility': visibility,
            'init_value': init_value,
            'is_trusted_role': is_trusted_role
        })

    return variables


def extract_ether_transfers(func_code):
    """Extract ether transfer operations in the function (enhanced, supports complex expressions)"""
    transfers = []
    # Match all transfer patterns, supporting complex target expressions with parentheses
    transfer_patterns = [
        # transfer()
        (r'transfer\s*\(\s*([^;]+?)\s*\)',
         lambda m: {'type': 'transfer', 'target': None, 'amount': m.group(1)}),
        # Full form: target.transfer(amount)
        (r'([^.]+?)\s*\.\s*transfer\s*\(\s*([^;]+?)\s*\)',
         lambda m: {'type': 'transfer', 'target': m.group(1), 'amount': m.group(2)}),
        # send()
        (r'([^.]+?)\s*\.\s*send\s*\(\s*([^;]+?)\s*\)',
         lambda m: {'type': 'send', 'target': m.group(1), 'amount': m.group(2)}),
        # call.value()
        (r'([^.]+?)\s*\.\s*call\s*\.\s*value\s*\(\s*([^)]+?)\s*\)\s*\(\s*\)',
         lambda m: {'type': 'call.value', 'target': m.group(1), 'amount': m.group(2)}),
        # Call with gas: target.call{value: ..., gas: ...}()
        (r'([^.]+?)\s*\.\s*call\s*\{[^}]*(value\s*:\s*([^,}]+))[^}]*\}\s*\(\s*\)',
         lambda m: {'type': 'call.value', 'target': m.group(1), 'amount': m.group(3)})
    ]

    for pattern, parser in transfer_patterns:
        for match in re.finditer(pattern, func_code):
            transfer = parser(match)
            if transfer['target'] is None:
                # Handle shorthand for this.transfer()
                transfer['target'] = 'address(this)'
            transfers.append({
                **transfer,
                'start': match.start(),
                'end': match.end()
            })

    return transfers


def get_function_parameters_and_locals(func_code):
    """Extract function parameters and local variables (used to determine address source)"""
    params = []
    # Extract parameters
    param_match = re.search(r'\(([^)]*)\)', func_code)
    if param_match:
        param_str = param_match.group(1).strip()
        if param_str:
            param_parts = re.split(r',\s*(?![^()]*\))', param_str)
            for part in param_parts:
                part = part.strip()
                if part and ' ' in part:
                    split_idx = part.rfind(' ')
                    param_type = part[:split_idx].strip()
                    param_name = part[split_idx + 1:].strip()
                    params.append({'name': param_name, 'type': param_type})

    # Extract local address variables
    locals = []
    local_pattern = r'address\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*=?.*?'
    for match in re.finditer(local_pattern, func_code):
        locals.append(match.group(1))

    return params, locals


def analyze_address_safety(target, state_vars, func_params, func_locals, contract_code):
    """Analyze address safety from multiple dimensions (core logic to reduce false positives)"""
    # 1. Clearly safe address types
    if target == 'msg.sender':
        return True, "msg.sender (function caller)"
    if target == 'address(this)':
        return True, "Contract itself"
    if re.match(r'^0x[0-9a-fA-F]{40}$', target):
        return True, "Hardcoded address"

    # 2. Check if it's a trusted state variable
    state_var = next((v for v in state_vars if v['name'] == target), None)
    if state_var:
        if state_var['is_trusted_role'] and state_var['init_value']:
            return True, f"Trusted role variable ({state_var['name']})"
        if state_var['init_value'] and re.match(r'^0x[0-9a-fA-F]{40}$', state_var['init_value']):
            return True, f"Predefined state variable ({state_var['name']})"

    # 3. Check if it's a local variable with a trusted source
    if target in func_locals:
        # Find local variable assignment source
        assign_pattern = rf'{target}\s*=\s*([^;]+);'
        assign_match = re.search(assign_pattern, contract_code)
        if assign_match:
            source = assign_match.group(1).strip()
            # Source is a trusted address
            if (source == 'msg.sender' or
                    re.match(r'^0x[0-9a-fA-F]{40}$', source) or
                    any(v['name'] == source and v['is_trusted_role'] for v in state_vars)):
                return True, f"Local variable from trusted source ({source})"

    # 4. Check if it's a parameter but belongs to a known role (e.g., user's own address)
    param = next((p for p in func_params if p['name'] == target and p['type'] == 'address'), None)
    if param:
        return False, "Function parameter (potential unknown address)"

    # 5. Check if it's a dynamically generated but trusted address (e.g., new contract)
    if re.search(r'address\(new\s+[A-Z]', target):
        return True, "Address of newly created contract"

    # Unknown address
    return False, "Potentially unknown address"


def has_strong_validation(target, func_code, func_modifiers, contract_code):
    """Check if there is strong validation logic (key to reduce false positives)"""
    # 1. Check validation inside the function
    validation_patterns = [
        # Non-zero address check
        rf'require\s*\(\s*{target}\s*!=?\s*address\(0\)\s*(,\s*"[^"]*")?\s*\)',
        # Whitelist check
        rf'require\s*\(\s*whitelist\s*\[\s*{target}\s*\]\s*(,\s*"[^"]*")?\s*\)',
        rf'require\s*\(\s*isWhitelisted\s*\(\s*{target}\s*\)\s*(,\s*"[^"]*")?\s*\)',
        # Role validation (e.g., only owner)
        rf'require\s*\(\s*{target}\s*==\s*[a-zA-Z_]+(owner|admin)\s*(,\s*"[^"]*")?\s*\)',
        # Complex condition validation
        rf'require\s*\(\s*[^)]*?{target}[^)]*?\s*(,\s*"[^"]*")?\s*\)'
    ]

    # 2. Check validation in modifiers
    for modifier in func_modifiers:
        mod_pattern = rf'modifier\s+{modifier}\s*\([^)]*\)\s*{{[^}}]*?require\s*\([^)]*?{target}[^)]*?\)'
        if re.search(mod_pattern, contract_code, flags=re.DOTALL):
            return True, "Modifier-based validation"

    # 3. Check external validation functions
    if re.search(rf'isValid\s*\(\s*{target}\s*\)', func_code) or \
            re.search(rf'validateAddress\s*\(\s*{target}\s*\)', func_code):
        return True, "External validation function"

    # 4. Check for multiple validations
    validation_count = sum(1 for p in validation_patterns if re.search(p, func_code))
    if validation_count >= 2:
        return True, f"Multiple validations ({validation_count} checks)"
    if validation_count == 1:
        return True, "Basic validation"

    return False, "No validation"


def is_zero_amount(amount_expr):
    """Check if the transfer amount is zero (no actual risk)"""
    return re.search(r'^\s*0\s*$', amount_expr) or \
        re.search(r'^\s*0x0\s*$', amount_expr) or \
        re.search(r'amount\s*==\s*0', amount_expr)


def check_swc103(solidity_code):
    """Optimized SWC-103 detection logic"""
    vulnerabilities = []
    cleaned_code = remove_comments_and_strings(solidity_code)
    if not cleaned_code:
        return vulnerabilities

    contracts = extract_contracts_and_functions(cleaned_code)
    for contract in contracts:
        state_vars = extract_state_variables(contract)
        for func in contract['functions']:
            func_code = func['code']
            func_start = func['start']
            func_name = func['name']
            func_modifiers = func['modifiers']

            # Extract function parameters and local variables
            func_params, func_locals = get_function_parameters_and_locals(func_code)

            # Analyze all transfer operations
            transfers = extract_ether_transfers(func_code)
            for transfer in transfers:
                target = transfer['target']
                amount = transfer['amount']
                transfer_type = transfer['type']

                # Exclude zero amount transfers (no actual risk)
                if is_zero_amount(amount):
                    continue

                # Analyze address safety
                is_safe, safety_reason = analyze_address_safety(
                    target, state_vars, func_params, func_locals, contract['code']
                )

                # Analyze validation strength
                has_validation, validation_reason = has_strong_validation(
                    target, func_code, func_modifiers, contract['code']
                )

                # Risk judgment (core rules to reduce false positives)
                if not is_safe:
                    # High risk: unknown address with no validation or only basic validation
                    # Medium risk: unknown address but with strong validation
                    if has_validation:
                        if "Basic" in validation_reason:
                            risk = "Medium"
                        else:
                            risk = "Low"  # Low risk for unknown address with strong validation
                    else:
                        risk = "High"

                    # Calculate line number
                    line = solidity_code[:func_start + transfer['start']].count('\n') + 1
                    code_snippet = func_code[transfer['start']:transfer['end']].strip()

                    vulnerabilities.append({
                        'type': 'SWC-103',
                        'function': func_name,
                        'target': target,
                        'transfer_type': transfer_type,
                        'risk': risk,
                        'line': line,
                        'code': code_snippet,
                        'description': (f"Ether transfer to {safety_reason.lower()} using {transfer_type}(), "
                                        f"{validation_reason.lower()}. Risk level: {risk}")
                    })

    return vulnerabilities


def check_solidity_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            code = f.read()
        return check_swc103(code)
    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")
        return []


def batch_check(input_dir, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for filename in os.listdir(input_dir):
        if filename.endswith('.sol'):
            file_path = os.path.join(input_dir, filename)
            print(f"Checking {filename}...")
            vulns = check_solidity_file(file_path)

            with open(os.path.join(output_dir, f"{filename}.swc103.txt"), 'w') as f:
                if vulns:
                    f.write(f"Found {len(vulns)} SWC-103 issues in {filename}:\n")
                    for i, v in enumerate(vulns, 1):
                        f.write(f"\nVulnerability #{i}\n")
                        f.write(f"Line: {v['line']}\n")
                        f.write(f"Function: {v['function']}\n")
                        f.write(f"Target: {v['target']}\n")
                        f.write(f"Method: {v['transfer_type']}()\n")
                        f.write(f"Risk: {v['risk']}\n")
                        f.write(f"Code: {v['code']}\n")
                        f.write(f"Description: {v['description']}\n")
                        f.write("-" * 60)
                else:
                    f.write(f"No SWC-103 vulnerabilities detected in {filename}")


if __name__ == "__main__":
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-103'))

    if not os.path.exists(input_dir):
        print(f"Input directory not found: {input_dir}")
    else:
        batch_check(input_dir, output_dir)
        print("Done.")
