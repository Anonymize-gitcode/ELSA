import os
import re


def remove_comments_and_strings(code):
    """Remove comments and strings to avoid interfering with syntax analysis"""
    # Remove strings
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', code)
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)
    # Remove single-line comments
    code = re.sub(r'//.*', '', code)
    # Remove multi-line comments
    while re.search(r'/\*.*?\*/', code, flags=re.DOTALL):
        code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    return code


def find_contracts_and_functions(cleaned_code):
    """Extract contract and function ranges and code"""
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
        func_pattern = r'function\s+([a-zA-Z_][a-zA-Z0-9_]*|constructor)\s*\([^)]*\)\s*(external|public|internal|private)?\s*\{?'
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
                'visibility': fm.group(2) or 'public'  # Default is public
            })

        contracts.append({
            'name': cm.group(2),
            'code': contract_code,
            'functions': functions
        })

    return contracts


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


def is_loop_with_safe_bound(loop_code):
    """Determine if the loop has safe bounds (core logic to reduce false positives)"""
    # 1. Exclude fixed iteration loops (e.g., for (uint i=0; i<10; i++))
    if re.search(r'i\s*<\s*\d+', loop_code) or re.search(r'i\s*<=\s*\d+', loop_code):
        return True, "Fixed iteration count (safe)"

    # 2. Exclude loops with clear upper limits (e.g., i < maxLimit and maxLimit has reasonable constraints)
    if re.search(r'i\s*<\s*([A-Za-z_]+)', loop_code):
        limit_var = re.search(r'i\s*<\s*([A-Za-z_]+)', loop_code).group(1)
        # Check if the limit variable has a safety constraint (e.g., limited within the function)
        if re.search(fr'{limit_var}\s*=\s*[^;]*min\(', loop_code) or \
                re.search(fr'{limit_var}\s*=\s*[^;]*\&\&\s*{limit_var}\s*<', loop_code) or \
                re.search(fr'require\s*\(\s*{limit_var}\s*<', loop_code):
            return True, f"Bound with safe limit ({limit_var})"

    # 3. Exclude loops with known-sized arrays (e.g., storage array but with fixed length)
    if re.search(r'for\s*\(.*\s*<\s*([A-Za-z_]+)\.length', loop_code):
        arr_name = re.search(r'([A-Za-z_]+)\.length', loop_code).group(1)
        # Check if the array has a fixed size (e.g., bytes32[10])
        if re.search(fr'{arr_name}\s+=\s*\[.*\]', loop_code) or \
                re.search(fr'{arr_name}\s+[A-Za-z_]+\s*\[\s*\d+\s*\]', loop_code):
            return True, f"Fixed-size array loop ({arr_name})"

    return False, "Unsafe or dynamic bound"


def detect_risky_loops(func_code, func_name):
    """Detect high-risk loops (may lead to gas limit overflow)"""
    risks = []
    # Match for loops (mainly detect loops iterating over dynamic arrays/maps)
    loop_patterns = [
        # Basic for loop pattern
        r'for\s*\(\s*uint\s+i\s*=\s*0\s*;\s*i\s*<\s*([^;]+)\s*;\s*i\s*\+\+\s*\)\s*\{',
        # Complex loop conditions (e.g., traversing mappings)
        r'for\s*\(\s*(uint|bytes32)\s+[a-zA-Z_]+\s*=\s*[^;]+;\s*[^;]+\s*;\s*[^)]+\s*\)\s*\{',
        # while loop
        r'while\s*\(\s*[^)]+\s*\)\s*\{',
    ]

    for pattern in loop_patterns:
        for match in re.finditer(pattern, func_code):
            loop_code = match.group(0)
            # Check if the loop is traversing dynamic data structures
            is_dynamic = (re.search(r'\.length', loop_code) or  # Dynamic arrays
                          re.search(r'mapping', loop_code) or  # Traversing mappings
                          re.search(r'keys\(\)', loop_code))  # Traversing key sets

            if is_dynamic:
                # Determine if the loop boundary is safe
                is_safe, reason = is_loop_with_safe_bound(func_code)
                if not is_safe:
                    risks.append({
                        'type': 'RiskyLoop',
                        'subtype': 'DynamicStructureTraversal',
                        'code': loop_code.strip(),
                        'reason': f"Loop traverses dynamic structure with {reason.lower()}"
                    })

    return risks


def detect_batch_operations(func_code, func_name):
    """Detect batch operations (e.g., transferring to multiple addresses)"""
    risks = []
    # Batch transfer patterns (loops containing transfer/send/call)
    batch_transfer_patterns = [
        r'for\s*\{[^}]*\.(transfer|send|call)\s*\([^)]*\)[^}]*\}',
        r'while\s*\{[^}]*\.(transfer|send|call)\s*\([^)]*\)[^}]*\}'
    ]

    for pattern in batch_transfer_patterns:
        if re.search(pattern, func_code, flags=re.DOTALL):
            # Check if there are any batch operation limits
            has_limit = re.search(r'limit\s*=\s*|max\s*\(|min\s*\(', func_code)
            risk_level = "Medium" if has_limit else "High"
            limit_desc = "with basic limit" if has_limit else "without limit"

            risks.append({
                'type': 'BatchOperation',
                'subtype': 'MassTransfer',
                'code': "Loop containing multiple ether transfers",
                'reason': f"Batch transfers {limit_desc} - may exceed block gas limit"
            })

    return risks


def detect_recursive_calls(func_code, func_name):
    """Detect recursive calls (may lead to stack overflow and high gas consumption)"""
    risks = []
    # Detect if the function calls itself
    if re.search(fr'{func_name}\s*\(', func_code):
        # Check if there is a recursion depth limit
        has_depth_limit = re.search(r'depth\s*<\s*|level\s*<\s*', func_code)
        risk_level = "Medium" if has_depth_limit else "High"
        limit_desc = "with depth limit" if has_depth_limit else "without depth limit"

        risks.append({
            'type': 'RecursiveCall',
            'subtype': 'SelfRecursion',
            'code': f"Recursive call to {func_name}()",
            'reason': f"Recursive function {limit_desc} - may exceed gas limit"
        })

    return risks


def detect_large_storage_operations(func_code):
    """Detect large storage operations (e.g., copying large arrays)"""
    risks = []
    # Detect large array copying or modification
    large_array_ops = [
        r'([A-Za-z_]+)\s*=\s*([A-Za-z_]+);',  # Array assignment
        r'([A-Za-z_]+)\s*\.push\s*\(\s*([A-Za-z_]+)\s*\)',  # Batch push
        r'for\s*\{[^}]*push\s*\([^)]*\)[^}]*\}'  # Push inside a loop
    ]

    for pattern in large_array_ops:
        for match in re.finditer(pattern, func_code):
            # Check if it's a dynamic array
            if re.search(r'\[\s*\]', func_code) and not re.search(r'\[\s*\d+\s*\]', func_code):
                risks.append({
                    'type': 'LargeStorageOp',
                    'subtype': 'DynamicArrayManipulation',
                    'code': match.group(0).strip(),
                    'reason': "Large dynamic array manipulation - may consume excessive gas"
                })

    return risks


def get_line_number(abs_pos, original_code):
    """Calculate the line number corresponding to the absolute position"""
    return original_code[:abs_pos].count('\n') + 1


def analyze_function(func, original_code):
    """Analyze SWC-128 risks within a single function"""
    risks = []
    func_code = func['code']
    func_name = func['name']
    func_start = func['start']

    # 1. Detect high-risk loops
    loop_risks = detect_risky_loops(func_code, func_name)
    risks.extend(loop_risks)

    # 2. Detect batch operations
    batch_risks = detect_batch_operations(func_code, func_name)
    risks.extend(batch_risks)

    # 3. Detect recursive calls
    recursive_risks = detect_recursive_calls(func_code, func_name)
    risks.extend(recursive_risks)

    # 4. Detect large storage operations
    storage_risks = detect_large_storage_operations(func_code)
    risks.extend(storage_risks)

    # Add location info to risks
    for risk in risks:
        # Find the risk code location within the function
        code_snippet = risk['code']
        pos_in_func = func_code.find(code_snippet)
        if pos_in_func != -1:
            abs_pos = func_start + pos_in_func
            risk['line'] = get_line_number(abs_pos, original_code)
        else:
            risk['line'] = get_line_number(func_start, original_code)  # Function starting line
        risk['function'] = func_name
        # External visible functions are riskier
        risk['risk_level'] = "High" if func['visibility'] in ['external', 'public'] else "Medium"

    return risks


def detect_swc128(file_path):
    """Main function to detect SWC-128 vulnerabilities"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_code = f.read()

        cleaned_code = remove_comments_and_strings(original_code)
        contracts = find_contracts_and_functions(cleaned_code)
        all_risks = []

        for contract in contracts:
            for func in contract['functions']:
                func_risks = analyze_function(func, original_code)
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
            risks = detect_swc128(file_path)

            output_path = os.path.join(output_dir, f"{os.path.splitext(filename)[0]}.txt")
            with open(output_path, 'w', encoding='utf-8') as f:
                if risks:
                    f.write(f"Found {len(risks)} SWC-128 related risks in {filename}:\n")
                    f.write("=" * 80 + "\n")
                    for i, risk in enumerate(risks, 1):
                        f.write(f"Risk #{i}\n")
                        f.write(f"Function: {risk['function']}\n")
                        f.write(f"Line: {risk['line']}\n")
                        f.write(f"Type: {risk['type']} ({risk['subtype']})\n")
                        f.write(f"Risk Level: {risk['risk_level']}\n")
                        f.write(f"Code: {risk['code']}\n")
                        f.write(f"Reason: {risk['reason']}\n")
                        f.write("-" * 80 + "\n")
                else:
                    f.write(f"No SWC-128 related risks detected in {filename}.\n")
                    safe_files += 1

    print(f"Total files with no SWC-128 risks: {safe_files}")


if __name__ == "__main__":
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-128'))

    if not os.path.exists(input_directory):
        print(f"Error: Input directory not found - {input_directory}")
    else:
        batch_process(input_directory, output_directory)
        print(f"Results saved to: {output_directory}")
