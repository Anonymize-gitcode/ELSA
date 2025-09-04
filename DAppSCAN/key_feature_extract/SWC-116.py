import os
import re
import time
from collections import defaultdict

# Enable debug mode and progress indication
DEBUG_MODE = True
MAX_BRACE_SEARCH = 10000  # Limit the maximum iterations for brace matching to prevent infinite loops

# SWC-116: Block property as a time proxy risk model
BLOCK_TIME_PROXIES = {
    'block.timestamp': {
        'risk_note': 'Can be manipulated by miners within ±15 seconds',
        'high_risk_keywords': ['expire', 'deadline', 'lock', 'unlock', 'claim', 'withdraw', 'rate']
    },
    'block.number': {
        'risk_note': 'Block intervals are unstable (10-20 seconds/block), making precise time mapping impossible',
        'high_risk_keywords': ['period', 'duration', 'interval', 'delay', 'after', 'countdown']
    }
}

# Safe usage patterns (to reduce false positives)
SAFE_USAGE_PATTERNS = [
    r'block\.(timestamp|number)\s*[+-]\s*\d{4,}',  # Large time windows
    r'emit\s+\w+\(.*block\.(timestamp|number).*\)',  # Event logs
    r'(?:uint256|bytes32)\s+\w+\s*=\s*keccak256\(abi\.encodePacked\(.*block\.(timestamp|number).*\)\)',  # Unique identifiers
    r'require\(.*block\.timestamp\s*<=\s*\w+\s*\+\s*\d{3,}.*\)',  # Defensive checks
    r'function\s+\w+\s*\([^)]*\)\s+(view|pure)\s+returns?\s*\([^)]*\)\s*\{[^}]*block\.(timestamp|number)[^}]*\}',  # View functions
    r'return\s+block\.(timestamp|number)\s*;',  # Frontend display
]

# High-risk scenario keywords
HIGH_RISK_CONTEXT = [
    'transfer', 'mint', 'burn', 'approve', 'balance', 'fund', 'reward',
    'admin', 'owner', 'role', 'permission', 'vault', 'treasury'
]

# Patterns for cleaning code
STRING_PATTERNS = [r'"(?:\\.|[^"\\])*"', r"'(?:\\.|[^'\\])*'", r'`(?:\\.|[^`\\])*`']
COMMENT_PATTERNS = [r'//.*', r'/\*.*?\*/']


def clean_code(code):
    """Clean code, remove comments and strings"""
    cleaned = code
    for pattern in COMMENT_PATTERNS:
        cleaned = re.sub(pattern, '', cleaned, flags=re.DOTALL)
    for pattern in STRING_PATTERNS:
        cleaned = re.sub(pattern, '', cleaned)
    return re.sub(r'\s+', ' ', cleaned).strip()


def find_matching_brace(code, start_pos):
    """Find matching braces (with iteration limit to prevent infinite loops)"""
    if start_pos >= len(code) or code[start_pos] != '{':
        return None
    count, pos = 1, start_pos + 1
    iterations = 0
    while pos < len(code) and iterations < MAX_BRACE_SEARCH:
        if code[pos] == '{':
            count += 1
        elif code[pos] == '}':
            count -= 1
            if count == 0:
                return pos
        pos += 1
        iterations += 1
    if DEBUG_MODE and iterations >= MAX_BRACE_SEARCH:
        print(f"Warning: Brace matching reached maximum iterations ({MAX_BRACE_SEARCH}), potential mismatched braces")
    return None  # Return None if the maximum iterations are exceeded


def extract_contracts_and_functions(code):
    """Extract contract and function information"""
    contracts = []
    contract_pattern = r'(contract|library)\s+(\w+)\s*(?:is\s+[\w\s,]+)?\s*{'
    for cm in re.finditer(contract_pattern, code):
        c_start = cm.start()
        c_end = find_matching_brace(code, cm.end() - 1)
        if not c_end:
            if DEBUG_MODE:
                print(f"Warning: Contract {cm.group(2)}'s braces do not match, skipping processing")
            continue
        c_code = code[c_start:c_end + 1]
        functions = []
        func_pattern = r'(function\s+\w+|constructor)\s*\([^)]*\)\s*(?:\w+\s*)*\s*(external|public|internal|private|view|pure)?\s*{'
        for fm in re.finditer(func_pattern, c_code):
            f_start = fm.start()
            f_end = find_matching_brace(c_code, f_start)
            if not f_end:
                if DEBUG_MODE:
                    print(f"Warning: Function {fm.group(1)}'s braces do not match, skipping processing")
                continue
            f_code = c_code[f_start:f_end + 1]
            f_name = fm.group(1).split(' ')[1] if 'function' in fm.group(1) else 'constructor'
            functions.append({
                'name': f_name,
                'code': f_code,
                'visibility': fm.group(2) or 'public',
                'start': f_start,
                'end': f_end
            })
        contracts.append({
            'name': cm.group(2),
            'code': c_code,
            'functions': functions,
            'start': c_start,
            'end': c_end
        })
    return contracts


def get_line_number(original_code, pos):
    """Calculate the line number"""
    return original_code[:pos].count('\n') + 1 if pos >= 0 else 1


def is_safe_usage(context_code):
    """Check if it is a safe usage scenario"""
    for pattern in SAFE_USAGE_PATTERNS:
        if re.search(pattern, context_code, re.IGNORECASE | re.DOTALL):
            return True
    return False


def get_risk_level(block_prop, func_code, func_name, contract_code):
    """Dynamically calculate the risk level"""
    risk = 'Low'
    if any(kw in func_code.lower() for kw in HIGH_RISK_CONTEXT):
        risk = 'High'
    time_keywords = BLOCK_TIME_PROXIES[block_prop]['high_risk_keywords']
    if any(kw in func_name.lower() for kw in time_keywords):
        risk = 'High'
    if (risk != 'High' and
            'view' not in func_code and 'pure' not in func_code and
            not re.search(r'(onlyOwner|onlyAdmin|accessControl)', func_code)):
        risk = 'Medium'
    if 'view' in func_code or 'pure' in func_code or re.search(r'require\(.*block\.(timestamp|number)', func_code):
        risk = 'Low'
    return risk


def detect_swc116(file_path):
    """Detect SWC-116 vulnerabilities (with debugging information)"""
    if DEBUG_MODE:
        print(f"Processing file: {os.path.basename(file_path)}")
    start_time = time.time()
    vulnerabilities = []
    try:
        # Limit file size (to prevent memory overflow from extremely large files)
        if os.path.getsize(file_path) > 1024 * 1024 * 5:  # 5MB
            if DEBUG_MODE:
                print(f"Skipping large file ({os.path.getsize(file_path) / 1024 / 1024:.2f}MB): {file_path}")
            return vulnerabilities

        with open(file_path, 'r', encoding='utf-8') as f:
            original_code = f.read()
        cleaned_code = clean_code(original_code)
        contracts = extract_contracts_and_functions(cleaned_code)

        for contract in contracts:
            c_name = contract['name']
            c_code = contract['code']
            c_start = contract['start']

            # Detect contract-level variables
            for prop in BLOCK_TIME_PROXIES:
                for match in re.finditer(r'\b' + re.escape(prop) + r'\b', c_code):
                    context = c_code[max(0, match.start() - 100):min(len(c_code), match.end() + 100)]
                    if is_safe_usage(context):
                        continue
                    line = get_line_number(original_code, c_start + match.start())
                    snippet = original_code[max(0, c_start + match.start() - 50):min(len(original_code),
                                                                                     c_start + match.end() + 50)].replace(
                        '\n', ' ')
                    vulnerabilities.append({
                        'contract': c_name,
                        'function': 'contract-level',
                        'block_prop': prop,
                        'risk': 'Low',
                        'line': line,
                        'snippet': snippet,
                        'desc': f"Contract-level use of {prop}, {BLOCK_TIME_PROXIES[prop]['risk_note']}."
                    })

            # Detect usage inside functions
            for func in contract['functions']:
                f_name = func['name']
                f_code = func['code']
                f_start_in_contract = func['start']
                for prop in BLOCK_TIME_PROXIES:
                    for match in re.finditer(r'\b' + re.escape(prop) + r'\b', f_code):
                        context = f_code[max(0, match.start() - 200):min(len(f_code), match.end() + 200)]
                        if is_safe_usage(context) or is_safe_usage(f_code):
                            continue
                        risk = get_risk_level(prop, f_code, f_name, c_code)
                        abs_pos = c_start + f_start_in_contract + match.start()
                        line = get_line_number(original_code, abs_pos)
                        snippet = original_code[max(0, abs_pos - 50):min(len(original_code), abs_pos + 50)].replace(
                            '\n', ' ')
                        risk_note = BLOCK_TIME_PROXIES[prop]['risk_note']
                        vulnerabilities.append({
                            'contract': c_name,
                            'function': f_name,
                            'block_prop': prop,
                            'risk': risk,
                            'line': line,
                            'snippet': snippet,
                            'desc': f"Function {f_name} uses {prop}, {risk_note}. Risk level: {risk}"
                        })

        if DEBUG_MODE:
            print(
                f"Completed processing {os.path.basename(file_path)} (Time taken: {time.time() - start_time:.2f} seconds, found {len(vulnerabilities)} issues)")
    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")
    return vulnerabilities


def batch_analyze(input_dir, output_dir):
    """Batch analyze (with progress indication)"""
    os.makedirs(output_dir, exist_ok=True)
    total, vulnerable = 0, 0
    stats = defaultdict(int)
    sol_files = [f for f in os.listdir(input_dir) if f.endswith('.sol')]

    if DEBUG_MODE:
        print(f"Found {len(sol_files)} Solidity files, starting batch processing...")

    for i, fname in enumerate(sol_files, 1):
        fpath = os.path.join(input_dir, fname)
        total += 1
        # Show progress
        if DEBUG_MODE:
            print(f"\n===== Processing file {i}/{len(sol_files)} =====")

        issues = detect_swc116(fpath)

        if issues:
            vulnerable += 1
            for issue in issues:
                stats[issue['block_prop']] += 1

        # Generate report
        report_name = f"{os.path.splitext(fname)[0]}_swc116_report.txt"
        with open(os.path.join(output_dir, report_name), 'w', encoding='utf-8') as f:
            f.write(f"SWC-116 Report: {fname}\n")
            f.write("=" * 80 + "\n")
            if issues:
                f.write(f"Found {len(issues)} issues (sorted by risk level):\n\n")
                sorted_issues = sorted(issues, key=lambda x: {'High': 3, 'Medium': 2, 'Low': 1}[x['risk']],
                                       reverse=True)
                for idx, issue in enumerate(sorted_issues, 1):
                    f.write(f"Issue {idx} ({issue['risk']})\n")
                    f.write(f"Contract: {issue['contract']} Function: {issue['function']}\n")
                    f.write(f"Risk property: {issue['block_prop']}\n")
                    f.write(f"Line number: {issue['line']}\n")
                    f.write(f"Code snippet: {issue['snippet']}\n")
                    f.write(f"Description: {issue['desc']}\n\n")
                    f.write("-" * 80 + "\n")
            else:
                f.write("No high-risk SWC-116 issues found.\n")

    print("\n" + "=" * 50)
    print(f"Analysis complete: processed {total} files, {vulnerable} containing risks")
    print(f"Reports saved to: {os.path.abspath(output_dir)}")
    print("Usage statistics:", dict(stats))


if __name__ == "__main__":
    # Configure paths
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-116'))

    if not os.path.exists(input_directory):
        print(f"Error: Input directory does not exist - {input_directory}")
        print("Please check the path or create the directory")
    else:
        batch_analyze(input_directory, output_directory)
