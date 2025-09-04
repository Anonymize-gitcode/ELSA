import os
import re


def remove_comments_and_strings(code):
    """Remove comments and strings to avoid interfering with syntax analysis"""
    # Remove multi-line comments
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    # Remove single-line comments
    code = re.sub(r'//.*', '', code)
    # Remove strings
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', code)
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)
    return code


def find_contracts_and_functions(cleaned_code):
    """Extract contracts and functions information"""
    contracts = []
    contract_pattern = r'(contract|library)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\{?'
    contract_matches = re.finditer(contract_pattern, cleaned_code)

    for cm in contract_matches:
        contract_start = cm.start()
        contract_end = find_matching_delimiter(cleaned_code, contract_start)
        if not contract_end:
            continue

        contract_code = cleaned_code[contract_start:contract_end + 1]
        functions = []
        # Match functions (including visibility and payable)
        func_pattern = r'function\s+([a-zA-Z_][a-zA-Z0-9_]*|constructor)\s*\([^)]*\)\s*(external|public|internal|private)?\s*(payable)?\s*\{?'
        func_matches = re.finditer(func_pattern, contract_code)

        for fm in func_matches:
            func_start_in_contract = fm.start()
            func_end_in_contract = find_matching_delimiter(contract_code, func_start_in_contract)
            if not func_end_in_contract:
                continue

            func_code = contract_code[func_start_in_contract:func_end_in_contract + 1]
            functions.append({
                'name': fm.group(1) or 'constructor',
                'code': func_code,
                'start': contract_start + func_start_in_contract,
                'visibility': fm.group(2) or 'public',
                'is_payable': fm.group(3) == 'payable'
            })

        contracts.append({
            'name': cm.group(2),
            'functions': functions
        })

    return contracts


def find_matching_delimiter(code, start_pos, opening='{', closing='}'):
    """Find matching delimiters (supports nesting)"""
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


def extract_low_level_calls(func_code):
    """Extract low-level calls (call/delegatecall/staticcall) and Gas settings"""
    calls = []
    # Match low-level calls with Gas settings (e.g., addr.call{gas: 1000}(...), addr.delegatecall{gas: x}(...))
    call_patterns = [
        r'([a-zA-Z_$][a-zA-Z0-9_$]*)\s*\.\s*(call|delegatecall|staticcall)\s*\{[^}]*gas\s*:\s*([^,}]+)[^}]*\}\s*\([^)]*\)',
        # Calls without Gas settings but may have risks
        r'([a-zA-Z_$][a-zA-Z0-9_$]*)\s*\.\s*(call|delegatecall|staticcall)\s*\([^)]*\)'
    ]

    for pattern in call_patterns:
        for match in re.finditer(pattern, func_code):
            target = match.group(1)
            call_type = match.group(2)
            gas_value = match.group(3) if len(match.groups()) > 2 else None

            # Parse Gas value (handling variables or constants)
            gas_amount = None
            if gas_value:
                # Remove spaces and comments
                gas_value_clean = re.sub(r'\s+', '', gas_value)
                # Match numbers
                if re.match(r'^\d+$', gas_value_clean):
                    gas_amount = int(gas_value_clean)
                else:
                    gas_amount = gas_value_clean  # Variable name

            calls.append({
                'target': target,
                'type': call_type,
                'gas': gas_amount,
                'code_snippet': match.group(0).strip(),
                'start_pos': match.start(),
                'end_pos': match.end()
            })

    return calls


def is_external_target(target, func_code, contract_functions):
    """Determine if the call target is an external contract (not within the current contract functions)"""
    # Internal contract function calls usually use this.func() or directly func(), exclude these cases
    if re.search(rf'this\s*\.\s*{target}', func_code):
        # Check if it is a function of the current contract
        if any(f['name'] == target for f in contract_functions):
            return False

    # Exclude known internal variables (e.g., local variables or state variables pointing to this contract)
    if re.search(rf'address\s+{target}\s*=\s*address\(this\)', func_code):
        return False

    return True


def check_return_value_handling(func_code, call_start, call_end):
    """Check if the return value of a low-level call is handled"""
    # Extract the code snippet after the call
    post_call_code = func_code[call_end:]

    # Check if there is a return value check (e.g., if (!call()) revert;)
    has_check = (
            re.search(r'\!\s*' + re.escape(func_code[call_start:call_end]), post_call_code[:100]) or
            re.search(r'require\s*\(\s*' + re.escape(func_code[call_start:call_end]), post_call_code[:100]) or
            re.search(r'if\s*\(\s*' + re.escape(func_code[call_start:call_end]) + r'\s*\)\s*\{', post_call_code[:100])
    )

    # Check if the return value is ignored (direct call without checking)
    if has_check:
        return 'handled'
    else:
        return 'ignored'


def is_gas_sufficient(gas_amount):
    """Determine if the Gas setting is sufficient (core logic to reduce false positives)"""
    if gas_amount is None:
        # No specified Gas, uses default (may be sufficient, but depends on EVM default behavior)
        return True, "No explicit gas limit (uses default)"

    if isinstance(gas_amount, int):
        # 2300 is the fixed Gas for transfer/send, below this value has high risk
        # 5000 is the safety threshold for simple external calls
        if gas_amount < 2300:
            return False, f"Explicit gas limit {gas_amount} is too low (below 2300)"
        elif gas_amount < 5000:
            return False, f"Explicit gas limit {gas_amount} is potentially insufficient (below 5000)"
        else:
            return True, f"Explicit gas limit {gas_amount} is sufficient"
    else:
        # Variable Gas value, check if there are safety constraints
        return None, f"Gas limit is variable ({gas_amount}) - need manual check"


def get_line_number(abs_pos, original_code):
    """Calculate the line number corresponding to the absolute position"""
    return original_code[:abs_pos].count('\n') + 1


def analyze_function(func, contract_functions, original_code):
    """Analyze a single function for SWC-126 risks"""
    risks = []
    func_code = func['code']
    func_name = func['name']
    func_start = func['start']

    # Extract low-level calls
    low_level_calls = extract_low_level_calls(func_code)
    for call in low_level_calls:
        # Only focus on external contract calls (internal calls have lower risk)
        if not is_external_target(call['target'], func_code, contract_functions):
            continue

        # Analyze Gas sufficiency
        gas_sufficient, gas_reason = is_gas_sufficient(call['gas'])

        # Analyze return value handling
        return_handling = check_return_value_handling(
            func_code, call['start_pos'], call['end_pos']
        )

        # Risk determination
        risk_level = "Low"
        if gas_sufficient is False:
            # Insufficient Gas and return value not handled → High risk
            if return_handling == 'ignored':
                risk_level = "High"
            # Insufficient Gas but return value handled → Medium risk
            else:
                risk_level = "Medium"
        elif gas_sufficient is None:
            # Variable Gas and return value not handled → Medium risk
            if return_handling == 'ignored':
                risk_level = "Medium"

        # Only record medium or high risk
        if risk_level in ["High", "Medium"]:
            # Calculate line number
            abs_pos = func_start + call['start_pos']
            line_number = get_line_number(abs_pos, original_code)

            # Build risk description
            handling_desc = "without checking return value" if return_handling == 'ignored' else "with return value checked"
            desc = (f"Low-level {call['type']}() to external target '{call['target']}' "
                    f"with {gas_reason.lower()}, {handling_desc}. "
                    f"This may allow griefing attacks by causing the call to fail.")

            risks.append({
                'type': 'SWC-126',
                'function': func_name,
                'call_type': call['type'],
                'target': call['target'],
                'gas': call['gas'],
                'risk_level': risk_level,
                'line': line_number,
                'code': call['code_snippet'],
                'description': desc
            })

    return risks


def detect_swc126(file_path):
    """Main function to detect SWC-126 vulnerabilities"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_code = f.read()

        cleaned_code = remove_comments_and_strings(original_code)
        contracts = find_contracts_and_functions(cleaned_code)
        all_risks = []

        for contract in contracts:
            contract_functions = contract['functions']
            for func in contract_functions:
                # External visible functions have higher risk, prioritize analysis
                if func['visibility'] in ['external', 'public']:
                    func_risks = analyze_function(func, contract_functions, original_code)
                    all_risks.extend(func_risks)

        return all_risks
    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")
        return []


def batch_process(input_dir, output_dir):
    """Batch process Solidity files in a directory"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    safe_files = 0
    for filename in os.listdir(input_dir):
        if filename.endswith('.sol'):
            file_path = os.path.join(input_dir, filename)
            print(f"Analyzing {filename}...")
            risks = detect_swc126(file_path)

            output_path = os.path.join(output_dir, f"{os.path.splitext(filename)[0]}.txt")
            with open(output_path, 'w', encoding='utf-8') as f:
                if risks:
                    f.write(f"Found {len(risks)} SWC-126 related risks in {filename}:\n")
                    f.write("=" * 80 + "\n")
                    for i, risk in enumerate(risks, 1):
                        f.write(f"Risk #{i}\n")
                        f.write(f"Function: {risk['function']}\n")
                        f.write(f"Line: {risk['line']}\n")
                        f.write(f"Call Type: {risk['call_type']}()\n")
                        f.write(f"Target: {risk['target']}\n")
                        f.write(f"Gas Limit: {risk['gas'] or 'default'}\n")
                        f.write(f"Risk Level: {risk['risk_level']}\n")
                        f.write(f"Code: {risk['code']}\n")
                        f.write(f"Description: {risk['description']}\n")
                        f.write("-" * 80 + "\n")
                else:
                    f.write(f"No SWC-126 related risks detected in {filename}.\n")
                    safe_files += 1

    print(f"Total files with no SWC-126 risks: {safe_files}")


if __name__ == "__main__":
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-126'))

    if not os.path.exists(input_directory):
        print(f"Error: Input directory not found - {input_directory}")
    else:
        batch_process(input_directory, output_directory)
        print(f"Results saved to: {output_directory}")
