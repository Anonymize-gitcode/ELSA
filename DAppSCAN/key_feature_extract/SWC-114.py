import os
import re

# SWC-114 related risk patterns: Typical characteristics dependent on transaction order
RISK_PATTERNS = {
    # Price-related operations (possibly manipulated by front-running)
    'price_manipulation': [
        r'price\s*=\s*[^;]+',  # Price assignment
        r'updatePrice\s*\([^)]*\)',  # Update price function
        r'getPrice\s*\(\s*\)\s*returns',  # Get price function
        r'calculatePrice\s*\([^)]*\)'  # Calculate price function
    ],
    # Liquidity-related operations (susceptible to front-running)
    'liquidity_operations': [
        r'addLiquidity\s*\([^)]*\)',  # Add liquidity
        r'removeLiquidity\s*\([^)]*\)',  # Remove liquidity
        r'swap\s*\([^)]*\)',  # Swap operation
        r'getReserves\s*\(\s*\)\s*returns'  # Get reserves
    ],
    # Operations depending on account balance (balance can be altered by front-running)
    'balance_dependence': [
        r'balanceOf\s*\([^)]*\)\s*([<>]=?|==|!=)\s*[^;]+',  # Balance comparison
        r'uint256\s+\w+\s*=\s*balanceOf\s*\([^)]*\)',  # Balance assignment
        r'if\s*\(\s*balanceOf\s*\([^)]*\)'  # Balance-based conditional check
    ],
    # Auction/crowdsale-related operations (time-sensitive and order-dependent)
    'auction_crowdsale': [
        r'bid\s*\([^)]*\)',  # Bid operation
        r'claim\s*\([^)]*\)',  # Claim operation
        r'finalizeAuction\s*\(\s*\)',  # End auction
        r'contribute\s*\([^)]*\)'  # Crowdfunding contribution
    ],
    # Unprotected state updates (can be exploited by front-running)
    'unprotected_state_update': [
        r'state\s*=\s*\w+',  # State update
        r'updateState\s*\([^)]*\)',  # Update state function
        r'set\w+\s*\([^)]*\)'  # Generic set function
    ]
}

# High-risk function list: Typically related to economic value transfer
HIGH_RISK_FUNCTIONS = [
    'swap', 'mint', 'burn', 'transfer', 'approve', 'deposit', 'withdraw',
    'bid', 'claim', 'stake', 'unstake', 'liquidate', 'flashLoan',
    'addLiquidity', 'removeLiquidity', 'buy', 'sell', 'exchange'
]

# Possible patterns to mitigate transaction order dependence
MITIGATION_PATTERNS = [
    # Time-lock mechanism
    r'timelock\s+',
    r'delay\s*=\s*\d+',
    r'after\s*\(\s*\d+\s*\)',
    # Batch processing mechanism
    r'batchProcess\s*\([^)]*\)',
    r'processAll\s*\(\s*\)',
    # Commit-Reveal mechanism
    r'commit\s*\([^)]*\)',
    r'reveal\s*\([^)]*\)',
    # Randomization mechanism
    r'random\s*\([^)]*\)',
    r'blockhash\s*\([^)]*\)',
    # Anti-front-running modifiers
    r'antiFrontRun\s*',
    r'noFrontRunning\s*'
]


def remove_comments_and_strings(code):
    """Remove comments and strings from code to avoid interfering with analysis"""
    # Remove multi-line comments
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    # Remove single-line comments
    code = re.sub(r'//.*', '', code)
    # Remove double-quoted strings
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', code)
    # Remove single-quoted strings
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)
    # Compress spaces
    code = re.sub(r'\s+', ' ', code).strip()
    return code


def find_matching_brace(code, start_pos, opening='{', closing='}'):
    """Find the matching brace"""
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
    """Calculate the line number based on absolute position"""
    if abs_pos < 0:
        return 1
    if abs_pos >= len(original_code):
        return original_code.count('\n') + 1
    return original_code[:abs_pos].count('\n') + 1


def extract_contracts_and_functions(cleaned_code):
    """Extract contracts and their internal functions"""
    contracts = []
    # Match contract definitions: Supports contracts with inheritance
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


def has_mitigation_mechanism(code_segment):
    """Check if there are mechanisms to mitigate transaction order dependence"""
    for pattern in MITIGATION_PATTERNS:
        if re.search(pattern, code_segment, re.IGNORECASE):
            return True
    return False


def is_high_risk_function(func_name):
    """Check if it's a high-risk function"""
    return any(func_name.lower() == risk_func.lower() for risk_func in HIGH_RISK_FUNCTIONS)


def detect_swc114(file_path):
    """Detect SWC-114 vulnerabilities (transaction order dependence)"""
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
                visibility = func['visibility']

                # External functions are riskier
                if visibility not in ['external', 'public', 'payable']:
                    continue

                # Collect all detected risk patterns
                detected_patterns = []
                for pattern_type, patterns in RISK_PATTERNS.items():
                    for pattern in patterns:
                        if re.search(pattern, func_code, re.IGNORECASE):
                            detected_patterns.append({
                                'type': pattern_type,
                                'pattern': pattern
                            })

                if not detected_patterns:
                    continue  # No risk patterns, skip

                # Check for mitigation mechanisms
                has_mitigation = has_mitigation_mechanism(func_code)

                # Check if it's a high-risk function
                high_risk = is_high_risk_function(func_name)

                # Determine risk level
                if high_risk and not has_mitigation and len(detected_patterns) >= 2:
                    risk_level = "Critical"
                elif (high_risk and not has_mitigation) or len(detected_patterns) >= 2:
                    risk_level = "High"
                elif high_risk or (not has_mitigation and len(detected_patterns) >= 1):
                    risk_level = "Medium"
                else:
                    risk_level = "Low"

                # Calculate line number
                abs_func_start = contract_start + func_start_in_contract
                line_number = get_line_number(original_code, abs_func_start)

                # Extract code snippet as evidence
                code_snippet = func_code[:200] + ('...' if len(func_code) > 200 else '')

                # Build description
                pattern_types = ', '.join(list(set([p['type'] for p in detected_patterns])))
                desc_parts = [
                    f"Function `{func_name}` contains patterns indicating potential transaction order dependence vulnerability (SWC-114). "
                    f"Detected risk patterns: {pattern_types}."
                ]
                if high_risk:
                    desc_parts.append(
                        f"Function is categorized as high-risk due to its name matching known sensitive operations.")
                if not has_mitigation:
                    desc_parts.append(
                        "No mitigation mechanisms (e.g., timelock, commit-reveal) detected to prevent front-running.")
                else:
                    desc_parts.append(
                        "Some mitigation mechanisms detected, but may not fully prevent transaction order manipulation.")

                vulnerabilities.append({
                    'type': 'SWC-114',
                    'contract': contract['name'],
                    'function': func_name,
                    'risk_level': risk_level,
                    'line': line_number,
                    'code_snippet': code_snippet,
                    'description': ' '.join(desc_parts),
                    'detected_patterns': pattern_types,
                    'has_mitigation': has_mitigation
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
        issues = detect_swc114(file_path)

        output_file = os.path.join(output_dir, f"{os.path.splitext(filename)[0]}_swc114_report.txt")
        with open(output_file, 'w', encoding='utf-8') as f:
            if issues:
                vulnerable_files += 1
                f.write(f"SWC-114 Vulnerability Report for {filename}\n")
                f.write("=" * 80 + "\n")
                f.write(f"Total issues found: {len(issues)}\n\n")

                for i, issue in enumerate(issues, 1):
                    f.write(f"Issue #{i} (Risk: {issue['risk_level']})\n")
                    f.write(f"Contract: {issue['contract']}\n")
                    f.write(f"Function: {issue['function']}\n")
                    f.write(f"Line: {issue['line']}\n")
                    f.write(f"Detected Patterns: {issue['detected_patterns']}\n")
                    f.write(f"Has Mitigation: {'Yes' if issue['has_mitigation'] else 'No'}\n")
                    f.write(f"Code Snippet: {issue['code_snippet']}\n")
                    f.write(f"Description: {issue['description']}\n\n")
                    f.write("-" * 80 + "\n\n")
            else:
                f.write(f"No SWC-114 issues detected in {filename}.\n")

    print(f"\nAnalysis Complete:")
    print(f"Total files processed: {total_files}")
    print(f"Files with SWC-114 issues: {vulnerable_files}")
    print(f"Reports saved to: {os.path.abspath(output_dir)}")


if __name__ == "__main__":
    # Configure input and output paths (modify as needed)
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-114'))


    if not os.path.exists(input_directory_path):
        print(f"Error: Input directory not found - {input_directory_path}")
        print("Please create the directory or update the path in the script.")
    else:
        batch_analyze(input_directory_path, output_directory_path)
