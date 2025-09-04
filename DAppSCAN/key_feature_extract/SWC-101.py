import os
import re


def remove_comments_and_strings(code):
    """Remove comments and strings to avoid interference with syntax analysis"""
    # Remove multi-line comments
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    # Remove single-line comments
    code = re.sub(r'//.*', '', code)
    # Remove strings
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', code)
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)
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
    """Extract contracts and function information (including state variables and modifiers)"""
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
        state_vars = []
        modifiers = []

        # Extract state variables (used to check if address is a trusted storage variable)
        var_pattern = r'(address|address\[\])\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(=|;)'
        for var_match in re.finditer(var_pattern, contract_code):
            var_name = var_match.group(2)
            # Exclude local variables inside functions
            in_function = any(
                f['start'] - contract_start <= var_match.start() <= f['end'] - contract_start
                for f in functions
            )
            if not in_function:
                # Check if it's a trusted role (e.g., implementation, trusted)
                is_trusted = any(kw in var_name.lower() for kw in ['impl', 'trusted', 'whitelist'])
                state_vars.append({'name': var_name, 'is_trusted': is_trusted})

        # Extract modifiers (used to check for access control)
        mod_pattern = r'modifier\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\([^)]*\)\s*\{.*?\}'
        for mod_match in re.finditer(mod_pattern, contract_code, flags=re.DOTALL):
            modifiers.append({
                'name': mod_match.group(1),
                'code': mod_match.group(0)
            })

        # Extract functions
        func_pattern = r'function\s+([a-zA-Z_][a-zA-Z0-9_]*|constructor)\s*\([^)]*\)\s*(external|public|internal|private)?\s*([^({]*)?\{'
        func_matches = re.finditer(func_pattern, contract_code)

        for fm in func_matches:
            func_name = fm.group(1) or 'constructor'
            func_start_in_contract = fm.start()
            func_end_in_contract = find_matching_delimiter(contract_code, func_start_in_contract)
            if not func_end_in_contract:
                continue

            func_code = contract_code[func_start_in_contract:func_end_in_contract + 1]
            # Extract function modifiers
            mod_str = fm.group(3).strip() if fm.group(3) else ''
            func_modifiers = [m.strip() for m in mod_str.split() if m.strip()]

            functions.append({
                'name': func_name,
                'code': func_code,
                'start': contract_start + func_start_in_contract,
                'end': contract_start + func_end_in_contract,
                'visibility': fm.group(2) or 'public',
                'modifiers': func_modifiers
            })

        contracts.append({
            'name': cm.group(2),
            'code': contract_code,
            'functions': functions,
            'state_vars': state_vars,
            'modifiers': modifiers
        })

    return contracts


def extract_delegatecalls(func_code):
    """Extract delegatecall calls from a function (including various syntax forms)"""
    delegatecalls = []
    # Match delegatecall with gas/value arguments: target.delegatecall{gas: ...}(...)
    pattern_with_options = r'([a-zA-Z_$][a-zA-Z0-9_$]*)\s*\.\s*delegatecall\s*\{[^}]*\}\s*\([^)]*\)'
    # Match basic form of delegatecall: target.delegatecall(...)
    pattern_basic = r'([a-zA-Z_$][a-zA-Z0-9_$]*)\s*\.\s*delegatecall\s*\([^)]*\)'

    for pattern in [pattern_with_options, pattern_basic]:
        for match in re.finditer(pattern, func_code):
            target = match.group(1)
            code_snippet = match.group(0).strip()
            delegatecalls.append({
                'target': target,
                'code': code_snippet,
                'start_pos': match.start(),
                'end_pos': match.end()
            })

    return delegatecalls


def is_target_trusted(target, state_vars, func_code, contract_code):
    """Determine if the delegatecall target is a trusted contract (core logic to reduce false positives)"""
    # 1. Hardcoded addresses (e.g., 0x123...) are considered trusted (typically predefined implementation contracts)
    if re.match(r'^0x[0-9a-fA-F]{40}$', target):
        return True, "Hardcoded address (assumed trusted)"

    # 2. Trusted state variables (e.g., implementation, trustedContract)
    trusted_var = next((v for v in state_vars if v['name'] == target and v['is_trusted']), None)
    if trusted_var:
        # Check if the variable has a fixed initialization value
        if re.search(rf'{target}\s*=\s*0x[0-9a-fA-F]{40}', contract_code):
            return True, f"Trusted state variable ({target}) with fixed address"

    # 3. Local variables but from trusted sources (e.g., returned by trusted functions)
    if re.search(rf'address\s+{target}\s*=', func_code):
        # Find the assignment source
        assign_pattern = rf'{target}\s*=\s*([^;]+);'
        assign_match = re.search(assign_pattern, func_code)
        if assign_match:
            source = assign_match.group(1).strip()
            # Source is a hardcoded address or trusted variable
            if (re.match(r'^0x[0-9a-fA-F]{40}$', source) or
                    any(v['name'] == source and v['is_trusted'] for v in state_vars)):
                return True, f"Local variable from trusted source ({source})"

    # 4. The target is the address created by a known trusted factory contract
    if re.search(rf'{target}\s*=\s*[A-Za-z_]+\.create\(', func_code):
        # Check if the factory is a trusted contract
        if re.search(r'trustedFactory\s*=\s*0x', contract_code) or \
                re.search(r'Factory\s+public\s+constant\s+trustedFactory', contract_code):
            return True, "Address created by trusted factory"

    # Untrusted target types
    if target == 'msg.sender':
        return False, "Target is msg.sender (user-controlled)"
    if re.search(r'^_', target):  # Function parameters (usually start with an underscore)
        return False, f"Target is function parameter ({target})"
    if re.search(r'mapping', func_code) and re.search(r'{target}\s*=\s*mapping', func_code):
        return False, "Target is from untrusted mapping"

    # Unknown target (default untrusted)
    return False, f"Unknown target ({target}) with no trust verification"


def has_target_verification(target, func_code, func_modifiers, contract_modifiers):
    """Check if there is target address verification logic (reduces false positives)"""
    # 1. Verification inside the function (e.g., whitelist, access checks)
    verification_patterns = [
        rf'require\s*\(\s*isTrusted\s*\(\s*{target}\s*\)\s*\)',  # Trusted check function
        rf'require\s*\(\s*whitelist\s*\[\s*{target}\s*\]\s*\)',  # Whitelist validation
        rf'require\s*\(\s*{target}\s*==\s*[a-zA-Z_]+(Impl|Implementation)\s*\)',  # Compare with known implementation address
        rf'require\s*\(\s*isContract\s*\(\s*{target}\s*\)\s*\)'  # At least check if it's a contract address
    ]
    for pattern in verification_patterns:
        if re.search(pattern, func_code):
            return True, "Explicit verification in function"

    # 2. Verification in modifiers (e.g., onlyAdmin)
    for mod_name in func_modifiers:
        mod = next((m for m in contract_modifiers if m['name'] == mod_name), None)
        if mod:
            if any(re.search(p, mod['code']) for p in verification_patterns):
                return True, f"Verification in modifier ({mod_name})"

    return False, "No target verification found"


def get_line_number(abs_pos, original_code):
    """Calculate the line number corresponding to the absolute position"""
    return original_code[:abs_pos].count('\n') + 1


def analyze_function(func, contract, original_code):
    """Analyze a single function for SWC-101 risk"""
    risks = []
    func_code = func['code']
    func_name = func['name']
    func_start = func['start']
    state_vars = contract['state_vars']
    contract_code = contract['code']
    contract_modifiers = contract['modifiers']

    # Extract all delegatecall calls
    delegatecalls = extract_delegatecalls(func_code)
    for call in delegatecalls:
        target = call['target']

        # 1. Check if the target is trusted
        is_trusted, trust_reason = is_target_trusted(
            target, state_vars, func_code, contract_code
        )

        # 2. Check if there is target verification
        has_verification, verification_reason = has_target_verification(
            target, func_code, func['modifiers'], contract_modifiers
        )

        # 3. Risk level determination
        risk_level = "Low"
        if not is_trusted:
            if not has_verification:
                risk_level = "High"  # Untrusted target + no verification → high risk
            else:
                risk_level = "Medium"  # Untrusted target + verification → medium risk

        # 4. Record medium/high risk
        if risk_level in ["High", "Medium"]:
            abs_pos = func_start + call['start_pos']
            line_number = get_line_number(abs_pos, original_code)

            desc = (f"Delegatecall to {trust_reason.lower()}. "
                    f"{verification_reason.lower()}. "
                    f"Using delegatecall with untrusted targets can allow state manipulation.")

            risks.append({
                'type': 'SWC-101',
                'function': func_name,
                'target': target,
                'risk_level': risk_level,
                'line': line_number,
                'code': call['code'],
                'description': desc
            })

    return risks


def detect_swc101(file_path):
    """Main function to detect SWC-101 vulnerability"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_code = f.read()

        cleaned_code = remove_comments_and_strings(original_code)
        contracts = extract_contracts_and_functions(cleaned_code)
        all_risks = []

        for contract in contracts:
            for func in contract['functions']:
                # Prioritize analysis of externally visible functions
                if func['visibility'] in ['external', 'public']:
                    func_risks = analyze_function(func, contract, original_code)
                    all_risks.extend(func_risks)

        return all_risks
    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")
        return []


def batch_process(input_dir, output_dir):
    """Batch process Solidity files in the directory"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    safe_files = 0
    for filename in os.listdir(input_dir):
        if filename.endswith('.sol'):
            file_path = os.path.join(input_dir, filename)
            print(f"Analyzing {filename}...")
            risks = detect_swc101(file_path)

            output_path = os.path.join(output_dir, f"{os.path.splitext(filename)[0]}.txt")
            with open(output_path, 'w', encoding='utf-8') as f:
                if risks:
                    f.write(f"Found {len(risks)} SWC-101 related risks in {filename}:\n")
                    f.write("=" * 80 + "\n")
                    for i, risk in enumerate(risks, 1):
                        f.write(f"Risk #{i}\n")
                        f.write(f"Function: {risk['function']}\n")
                        f.write(f"Line: {risk['line']}\n")
                        f.write(f"Target: {risk['target']}\n")
                        f.write(f"Risk Level: {risk['risk_level']}\n")
                        f.write(f"Code: {risk['code']}\n")
                        f.write(f"Description: {risk['description']}\n")
                        f.write("-" * 80 + "\n")
                else:
                    f.write(f"No SWC-101 related risks detected in {filename}.\n")
                    safe_files += 1

    print(f"Total files with no SWC-101 risks: {safe_files}")


if __name__ == "__main__":
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-101'))

    if not os.path.exists(input_directory):
        print(f"Error: Input directory not found - {input_directory}")
    else:
        batch_process(input_directory, output_directory)
        print(f"Results saved to: {output_directory}")
