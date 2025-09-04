import os
import re


def remove_comments_and_strings(solidity_code):
    """Remove comments and strings to avoid interference with detection"""
    # Remove strings (single and double quotes, handling escape characters)
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', solidity_code)
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)

    # Remove single-line comments
    code = re.sub(r'//.*', '', code)

    # Remove multi-line comments (handle nesting)
    while re.search(r'/\*.*?\*/', code, flags=re.DOTALL):
        code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)

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


def get_contract_info(cleaned_code):
    """Extract contract information (name, inheritance, scope), excluding interfaces"""
    contracts = []
    # Match contracts and libraries (excluding interfaces, as interfaces have no state variables)
    contract_pattern = r'(contract|library)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(is\s+([a-zA-Z_,\s]+))?\s*\{?'
    matches = re.finditer(contract_pattern, cleaned_code)

    for match in matches:
        contract_type = match.group(1)
        contract_name = match.group(2)
        inherit_str = match.group(4) or ""
        inherits = [i.strip() for i in inherit_str.split(',') if i.strip()]

        start = match.start()
        end = find_matching_delimiter(cleaned_code, start, '{', '}')
        if end:
            contracts.append({
                'name': contract_name,
                'type': contract_type,
                'start': start,
                'end': end,
                'inherits': inherits,
                'code': cleaned_code[start:end + 1]
            })

    return contracts


def extract_state_variables(contract):
    """Extract state variables from the contract, excluding constants and immutable variables"""
    variables = []
    contract_code = contract['code']
    contract_start = contract['start']

    # Match state variable definitions (with visibility modifiers, excluding variables inside functions)
    var_pattern = r'(?:(public|private|internal)\s+)?(?!function|constructor)([a-zA-Z_][a-zA-Z0-9_]*\s*(?:\[\s*\])?)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:=|;)'
    matches = re.finditer(var_pattern, contract_code)

    for match in matches:
        var_decl = contract_code[match.start():match.end()].strip()
        # Exclude constants and immutable variables (they cannot be modified)
        if 'constant' in var_decl or 'immutable' in var_decl:
            continue

        # Ensure variables are outside functions (state variables have functions or other variables following them)
        var_end_in_contract = match.end()
        remaining_code = contract_code[var_end_in_contract:var_end_in_contract + 100]
        if not re.search(r'(function|contract|library|struct|enum)', remaining_code):
            continue

        visibility = match.group(1) or 'internal'
        var_type = match.group(2).strip()
        var_name = match.group(3).strip()

        variables.append({
            'name': var_name,
            'type': var_type,
            'visibility': visibility,
            'abs_pos': contract_start + match.start(),
            'declaration': var_decl
        })

    return variables


def extract_functions(contract):
    """Extract function information (parameters, local variables, code range)"""
    functions = []
    contract_code = contract['code']
    contract_start = contract['start']

    # Match functions and constructors
    func_pattern = r'(function\s+([a-zA-Z_][a-zA-Z0-9_]*)|constructor)\s*\([^)]*\)\s*(external|public|internal|private)?\s*\{?'
    matches = re.finditer(func_pattern, contract_code)

    for match in matches:
        func_name = match.group(2) or 'constructor'
        func_start_in_contract = match.start()
        func_abs_start = contract_start + func_start_in_contract

        # Find function end position
        func_end_in_contract = find_matching_delimiter(contract_code, func_start_in_contract, '{', '}')
        if not func_end_in_contract:
            continue

        func_code = contract_code[func_start_in_contract:func_end_in_contract + 1]
        func_abs_end = contract_start + func_end_in_contract

        # Extract function parameters
        params = []
        param_match = re.search(r'\(([^)]*)\)', func_code)
        if param_match:
            param_str = param_match.group(1).strip()
            if param_str:
                # Handle complex parameters with brackets (e.g., tuple, array)
                param_parts = []
                bracket_count = 0
                current_part = []
                for c in param_str:
                    if c == ',' and bracket_count == 0:
                        param_parts.append(''.join(current_part).strip())
                        current_part = []
                    else:
                        current_part.append(c)
                        if c == '(':
                            bracket_count += 1
                        elif c == ')':
                            bracket_count -= 1
                if current_part:
                    param_parts.append(''.join(current_part).strip())

                for part in param_parts:
                    part = part.strip()
                    if part and ' ' in part:
                        # Split type and parameter name (take the last space)
                        split_idx = part.rfind(' ')
                        param_name = part[split_idx + 1:].strip()
                        params.append({
                            'name': param_name,
                            'type': 'parameter',
                            'abs_pos': func_abs_start + param_match.start() + 1 + part.find(param_name)
                        })

        # Extract local variables (excluding variables with the same name as parameters)
        local_vars = []
        param_names = [p['name'] for p in params]
        # Match local variable definitions (excluding parameters)
        local_pattern = r'(?:(uint|int|bool|address|string|bytes|mapping|struct)\s+|(?:[A-Z][a-zA-Z0-9_]*)\s+)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*='
        local_matches = re.finditer(local_pattern, func_code)

        for lm in local_matches:
            var_name = lm.group(2)
            if var_name and var_name not in param_names:
                local_vars.append({
                    'name': var_name,
                    'type': 'local',
                    'abs_pos': func_abs_start + lm.start()
                })

        functions.append({
            'name': func_name,
            'params': params,
            'locals': local_vars,
            'code': func_code,
            'abs_start': func_abs_start,
            'abs_end': func_abs_end
        })

    return functions


def build_inheritance_chain(contracts):
    """Build an accurate inheritance chain, excluding circular inheritance and non-contract types"""
    inheritance_chain = {}
    contract_names = [c['name'] for c in contracts]

    for contract in contracts:
        chain = []
        current_parents = contract['inherits'].copy()
        visited = set()

        while current_parents:
            parent = current_parents.pop(0)
            if parent in visited or parent not in contract_names:
                continue

            visited.add(parent)
            chain.append(parent)

            # Find the parent contract's parent contract
            parent_contract = next(c for c in contracts if c['name'] == parent)
            current_parents.extend(parent_contract['inherits'])

        inheritance_chain[contract['name']] = chain

    return inheritance_chain


def is_high_risk_variable(var_name):
    """Determine if a variable is high-risk (involves assets, permissions, etc.)"""
    high_risk_patterns = [
        r'owner', r'admin', r'governor',  # Permissions related
        r'balance', r'fund', r'treasury',  # Asset related
        r'token', r'asset', r'collateral',  # Token/Asset related
        r'fee', r'rate', r'limit',  # Economic parameters
        r'paused', r'locked', r'active'  # State control related
    ]
    return any(pattern in var_name.lower() for pattern in high_risk_patterns)


def variable_used_in_function(var_name, func_code):
    """Check if a variable is used in a function (excluding declaration statements)"""
    # Exclude variable declaration lines
    lines = func_code.split('\n')
    for line in lines:
        stripped = line.strip()
        if var_name in stripped and not re.search(r'\b' + var_name + r'\s*=', stripped):
            # Check if there is a read or modify operation
            if re.search(r'\b' + var_name + r'\b', stripped) and \
                    (re.search(r'[+*/-]?=\s*' + var_name, stripped) or
                     re.search(var_name + r'\s*[+*/-]=', stripped) or
                     re.search(r'return\s+.*' + var_name, stripped) or
                     re.search(r'if\s*\(.*' + var_name, stripped)):
                return True
    return False


def get_line_number(abs_pos, cleaned_code):
    """Calculate the line number corresponding to the absolute position (by passing cleaned_code to avoid global variables)"""
    return cleaned_code[:abs_pos].count('\n') + 1


def check_shadowing(contracts, cleaned_code):
    """Detect state variable shadowing, add context filtering to reduce false positives"""
    vulnerabilities = []
    if not contracts:
        return vulnerabilities

    # Build inheritance chain
    inheritance_chain = build_inheritance_chain(contracts)

    # Extract state variables from all contracts
    contract_vars = {}
    for contract in contracts:
        contract_vars[contract['name']] = extract_state_variables(contract)

    # Analyze each contract
    for contract in contracts:
        contract_name = contract['name']
        current_vars = contract_vars[contract_name]
        if not current_vars:
            continue

        functions = extract_functions(contract)
        inherited_chain = inheritance_chain.get(contract_name, [])

        # 1. Detect inherited variables being shadowed (only high-risk variables)
        for parent_name in inherited_chain:
            parent_vars = contract_vars.get(parent_name, [])
            for parent_var in parent_vars:
                # Find a state variable with the same name in the current contract
                shadow_var = next((v for v in current_vars if v['name'] == parent_var['name']), None)
                if shadow_var:
                    # Only report high-risk variables (low-risk shadowing is often intentional)
                    if is_high_risk_variable(parent_var['name']):
                        vulnerabilities.append({
                            'type': 'SWC-119',
                            'category': 'Inherited variable shadowing',
                            'variable': shadow_var['name'],
                            'shadowed_from': parent_name,
                            'risk': 'High',
                            'code': shadow_var['declaration'],
                            'line': get_line_number(shadow_var['abs_pos'], cleaned_code),
                            'description': f"State variable '{shadow_var['name']}' shadows inherited variable from {parent_name} (high-risk variable)"
                        })

        # 2. Detect function parameters shadowing state variables
        for func in functions:
            func_code = func['code']
            for param in func['params']:
                # Find shadowed state variables
                shadowed_var = next((v for v in current_vars if v['name'] == param['name']), None)
                if shadowed_var:
                    # Check if the shadowed variable is used in the function (not used means no risk)
                    if variable_used_in_function(shadowed_var['name'], func_code):
                        risk = 'High' if is_high_risk_variable(shadowed_var['name']) else 'Medium'
                        vulnerabilities.append({
                            'type': 'SWC-119',
                            'category': 'Parameter shadowing',
                            'variable': param['name'],
                            'function': func['name'],
                            'risk': risk,
                            'code': f"function {func['name']}(..., {param['name']}, ...)",
                            'line': get_line_number(param['abs_pos'], cleaned_code),
                            'description': f"Function parameter '{param['name']}' shadows state variable (variable is used in function logic)"
                        })

        # 3. Detect local variables shadowing state variables
        for func in functions:
            func_code = func['code']
            for local in func['locals']:
                # Find shadowed state variables
                shadowed_var = next((v for v in current_vars if v['name'] == local['name']), None)
                if shadowed_var:
                    # Filtering conditions:
                    # - Local variable is not temporary (e.g., i, j, temp)
                    # - Shadowed variable is used in the function
                    if (len(local['name']) > 3 or local['name'] not in ['i', 'j', 'k', 'tmp', 'temp']) and \
                            variable_used_in_function(shadowed_var['name'], func_code):
                        risk = 'High' if is_high_risk_variable(shadowed_var['name']) else 'Medium'
                        vulnerabilities.append({
                            'type': 'SWC-119',
                            'category': 'Local variable shadowing',
                            'variable': local['name'],
                            'function': func['name'],
                            'risk': risk,
                            'code': f"{local['name']} = ...",
                            'line': get_line_number(local['abs_pos'], cleaned_code),
                            'description': f"Local variable '{local['name']}' shadows state variable (variable is used in function logic)"
                        })

    return vulnerabilities


def check_solidity_file(file_path):
    """Check a single Solidity file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            original_code = file.read()

        cleaned_code = remove_comments_and_strings(original_code)
        contracts = get_contract_info(cleaned_code)
        vulnerabilities = check_shadowing(contracts, cleaned_code)

        # Map to original code line numbers
        for vuln in vulnerabilities:
            cleaned_line = vuln['line']
            # Build the mapping between cleaned code and original code line numbers
            original_line = None
            cleaned_lines = cleaned_code.split('\n')
            original_lines = original_code.split('\n')
            cleaned_idx = 0

            for orig_idx, orig_line in enumerate(original_lines):
                processed_orig = remove_comments_and_strings(orig_line).strip()
                if cleaned_idx < len(cleaned_lines) and processed_orig == cleaned_lines[cleaned_idx].strip():
                    cleaned_idx += 1
                    if cleaned_idx == cleaned_line:
                        original_line = orig_idx + 1
                        break
            vuln['line'] = original_line

        return vulnerabilities
    except Exception as e:
        print(f"Error processing file {file_path}: {str(e)}")
        return []


def check_all_files_in_directory(input_dir, output_dir):
    """Batch check Solidity files in the directory"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for filename in os.listdir(input_dir):
        if filename.endswith(".sol"):
            file_path = os.path.join(input_dir, filename)
            print(f"Checking {filename}...")
            vulns = check_solidity_file(file_path)

            output_path = os.path.join(output_dir, f"{filename}.swc119.txt")
            with open(output_path, 'w', encoding='utf-8') as f:
                if vulns:
                    f.write(f"Found {len(vulns)} SWC-119 vulnerabilities in {filename}:\n")
                    f.write("=" * 80 + "\n")
                    for i, v in enumerate(vulns, 1):
                        f.write(f"Vulnerability #{i}\n")
                        f.write(f"Type: {v['type']} ({v['category']})\n")
                        f.write(f"Variable: {v['variable']}\n")
                        f.write(f"Line: {v['line'] or 'Unknown'}\n")
                        f.write(f"Risk: {v['risk']}\n")
                        f.write(f"Code: {v['code']}\n")
                        f.write(f"Description: {v['description']}\n")
                        f.write("-" * 80 + "\n")
                else:
                    f.write(f"No SWC-119 vulnerabilities detected in {filename}\n")


if __name__ == "__main__":
    # Configure paths
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-119'))

    if not os.path.exists(input_dir):
        print(f"Error: Input directory not found - {input_dir}")
    else:
        print("Starting optimized SWC-119 detection...")
        check_all_files_in_directory(input_dir, output_dir)
        print("Detection completed.")
