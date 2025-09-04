import os
import re
import time
from collections import defaultdict

# Debug configuration
DEBUG_MODE = True
MAX_ITERATION_LIMIT = 10000  # Prevent infinite loops during parsing
GAS_INTENSIVE_THRESHOLD = 50  # High-risk loop iteration threshold

# SWC-113: High-risk Gas-intensive operation patterns
GAS_INTENSIVE_PATTERNS = {
    # 1. Dynamic loops (Loop count depends on external inputs or dynamic data)
    'dynamic_loop': {
        'patterns': [
            r'for\s*\(\s*(?:uint|int)\s+\w+\s*=\s*\d+\s*;\s*\w+\s*<\s*\w+\s*;\s*\w++\s*\)',  # Loop limit is a variable
            r'while\s*\(\s*\w+\s*<\s*\w+\s*\)',  # while loop depends on variable condition
            r'for\s*\(\s*(?:uint|int)\s+\w+\s*=\s*\d+\s*;\s*\w+\s*<\s*\w+\s*\[\s*\w+\s*\]\s*;\s*\w++\s*\)'  # Depends on array length
        ],
        'risk_note': 'Loop count depends on dynamic data, may exceed block Gas limit due to large data volume'
    },

    # 2. Large array operations
    'large_array_operation': {
        'patterns': [
            r'for\s*\(.*\)\s*\{[^}]*\w+\s*\[\s*\w+\s*\]\s*=\s*[^;]+;',  # Writing to an array inside a loop
            r'for\s*\(.*\)\s*\{[^}]*delete\s+\w+\s*\[\s*\w+\s*\];',  # Deleting array elements inside a loop
            r'for\s*\(.*\)\s*\{[^}]*\w+\.push\([^)]*\);'  # Dynamically expanding arrays inside a loop
        ],
        'risk_note': 'Array write/delete operations inside loops cause Gas consumption to grow linearly with array length'
    },

    # 3. Recursion
    'recursion': {
        'patterns': [
            r'function\s+\w+\s*\([^)]*\)\s*[^}]*\w+\s*\([^)]*\)\s*;[^}]*\}'  # Function calls itself
        ],
        'risk_note': 'Recursive calls may cause stack overflow or Gas exhaustion due to deep recursion depth'
    },

    # 4. Batch external calls
    'batch_external_call': {
        'patterns': [
            r'for\s*\(.*\)\s*\{[^}]*\w+\s*\.\s*\w+\s*\([^)]*\)\s*;',  # Calling external contracts inside a loop
            r'for\s*\(.*\)\s*\{[^}]*address\s*\(\s*\w+\s*\)\s*\.call\([^)]*\)',  # Using call inside a loop
            r'for\s*\(.*\)\s*\{[^}]*transfer\s*\([^)]*\)'  # Performing transfers inside a loop
        ],
        'risk_note': 'Executing external calls/transfers inside loops consumes fixed Gas per call, total consumption may exceed limit'
    }
}

# Safe usage patterns (excluding low-risk scenarios)
SAFE_USAGE_PATTERNS = [
    # 1. Fixed number loops (Iteration count is clear and small)
    r'for\s*\(\s*(?:uint|int)\s+\w+\s*=\s*\d+\s*;\s*\w+\s*<\s*\d{1,2}\s*;\s*\w++\s*\)',  # e.g., i < 10

    # 2. Loops in view functions (No state change, Gas consumption doesn't affect on-chain transactions)
    r'function\s+\w+\s*\([^)]*\)\s+(view|pure)\s+[^}]*for\s*\([^)]*\)\s*\{[^}]*\}',

    # 3. Loops with Gas limit
    r'for\s*\(.*\)\s*\{[^}]*require\(\s*\w+\s*<\s*\d+\s*\);',  # Loop contains iteration count check
    r'for\s*\(\s*(?:uint|int)\s+\w+\s*=\s*\d+\s*;\s*\w+\s*<\s*\w+\s*&&\s*\w+\s*<\s*\d+\s*;\s*\w++\s*\)'  # Double limit conditions
]

# High-risk context keywords (related to core functionality)
HIGH_RISK_CONTEXT = [
    'withdraw', 'claim', 'distribute', 'refund', 'migrate',
    'liquidate', 'settle', 'update', 'sync', 'process'
]

# Code cleaning patterns (removing comments and strings)
STRING_PATTERNS = [r'"(?:\\.|[^"\\])*"', r"'(?:\\.|[^'\\])*'", r'`(?:\\.|[^`\\])*`']
COMMENT_PATTERNS = [r'//.*', r'/\*.*?\*/']


def clean_code(code):
    """Clean code by removing comments and strings to avoid interference with detection"""
    cleaned = code
    # Remove comments
    for pattern in COMMENT_PATTERNS:
        cleaned = re.sub(pattern, '', cleaned, flags=re.DOTALL)
    # Remove strings
    for pattern in STRING_PATTERNS:
        cleaned = re.sub(pattern, '', cleaned)
    # Compress whitespace
    return re.sub(r'\s+', ' ', cleaned).strip()


def find_matching_brace(code, start_pos):
    """Find the matching brace (with iteration limit)"""
    if start_pos >= len(code) or code[start_pos] != '{':
        return None
    count, pos = 1, start_pos + 1
    iterations = 0
    while pos < len(code) and iterations < MAX_ITERATION_LIMIT:
        if code[pos] == '{':
            count += 1
        elif code[pos] == '}':
            count -= 1
            if count == 0:
                return pos
        pos += 1
        iterations += 1
    if DEBUG_MODE and iterations >= MAX_ITERATION_LIMIT:
        print(f"Warning: Matching braces reached max iteration limit ({MAX_ITERATION_LIMIT})")
    return None


def extract_contracts_and_functions(code):
    """Extract contract and function information"""
    contracts = []
    contract_pattern = r'(contract|library)\s+(\w+)\s*(?:is\s+[\w\s,]+)?\s*{'
    for cm in re.finditer(contract_pattern, code):
        c_start = cm.start()
        c_end = find_matching_brace(code, cm.end() - 1)
        if not c_end:
            if DEBUG_MODE:
                print(f"Warning: Contract {cm.group(2)} braces do not match, skipping")
            continue
        c_code = code[c_start:c_end + 1]
        functions = []
        # Match functions (including constructors)
        func_pattern = r'(function\s+\w+|constructor)\s*\([^)]*\)\s*(?:\w+\s*)*\s*(external|public|internal|private|view|pure)?\s*{'
        for fm in re.finditer(func_pattern, c_code):
            f_start = fm.start()
            f_end = find_matching_brace(c_code, f_start)
            if not f_end:
                if DEBUG_MODE:
                    print(f"Warning: Function {fm.group(1)} braces do not match, skipping")
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
    """Calculate the line number corresponding to the code position"""
    return original_code[:pos].count('\n') + 1 if pos >= 0 else 1


def is_safe_usage(context_code):
    """Determine if the usage is safe (exclude false positives)"""
    for pattern in SAFE_USAGE_PATTERNS:
        if re.search(pattern, context_code, re.IGNORECASE | re.DOTALL):
            return True
    # Check if loop has a clear iteration limit (e.g., i < 50)
    if re.search(r'for\s*\(.*\s*\w+\s*<\s*\d+\s*\)', context_code) and \
            re.search(r'\d+', context_code) and \
            int(re.findall(r'\d+', context_code)[-1]) < GAS_INTENSIVE_THRESHOLD:
        return True
    return False


def get_risk_level(pattern_type, func_code, func_name):
    """Dynamically calculate the risk level"""
    risk = 'Low'
    # High-risk scenario 1: Core function contains Gas-intensive operations
    if any(kw in func_name.lower() for kw in HIGH_RISK_CONTEXT):
        risk = 'High'
    # High-risk scenario 2: External functions without access control
    if 'external' in func_code or 'public' in func_code:
        if not re.search(r'(onlyOwner|onlyAdmin|accessControl|modifier)', func_code):
            risk = 'High'
    # Medium-risk scenario: Internal function but operates on large data
    if risk != 'High' and 'large_array_operation' in pattern_type:
        if re.search(r'\w+\s*\[\s*\]', func_code) and re.search(r'length\s*>', func_code):
            risk = 'Medium'
    # Low-risk scenario: View function or explicit Gas control
    if 'view' in func_code or 'pure' in func_code or re.search(r'require\(.*gasleft\(\)', func_code):
        risk = 'Low'
    return risk


def detect_swc113(file_path):
    """Detect SWC-113 vulnerabilities"""
    if DEBUG_MODE:
        print(f"Processing file: {os.path.basename(file_path)}")
    start_time = time.time()
    vulnerabilities = []
    try:
        # Skip oversized files
        if os.path.getsize(file_path) > 1024 * 1024 * 5:  # 5MB
            if DEBUG_MODE:
                print(f"Skipping oversized file ({os.path.getsize(file_path) / 1024 / 1024:.2f}MB): {file_path}")
            return vulnerabilities

        with open(file_path, 'r', encoding='utf-8') as f:
            original_code = f.read()
        cleaned_code = clean_code(original_code)
        contracts = extract_contracts_and_functions(cleaned_code)

        for contract in contracts:
            c_name = contract['name']
            c_code = contract['code']
            c_start = contract['start']

            # Detect high-risk operations inside functions
            for func in contract['functions']:
                f_name = func['name']
                f_code = func['code']
                f_start_in_contract = func['start']

                # Check all high-risk patterns
                for pattern_type, pattern_info in GAS_INTENSIVE_PATTERNS.items():
                    for pattern in pattern_info['patterns']:
                        for match in re.finditer(pattern, f_code, re.IGNORECASE | re.DOTALL):
                            # Extract context
                            context = f_code[max(0, match.start() - 200):min(len(f_code), match.end() + 200)]
                            # Exclude safe usage scenarios
                            if is_safe_usage(context) or is_safe_usage(f_code):
                                continue
                            # Calculate risk level
                            risk = get_risk_level(pattern_type, f_code, f_name)
                            # Locate line number and code snippet
                            abs_pos = c_start + f_start_in_contract + match.start()
                            line = get_line_number(original_code, abs_pos)
                            snippet = original_code[
                                      max(0, abs_pos - 50):min(len(original_code), abs_pos + 100)].replace('\n', ' ')
                            # Record vulnerabilities
                            vulnerabilities.append({
                                'contract': c_name,
                                'function': f_name,
                                'pattern_type': pattern_type,
                                'risk': risk,
                                'line': line,
                                'snippet': snippet,
                                'desc': f"Function {f_name} contains {pattern_info['risk_note']}. Risk level: {risk}"
                            })

        if DEBUG_MODE:
            print(
                f"Completed processing {os.path.basename(file_path)} (Time taken: {time.time() - start_time:.2f} seconds, {len(vulnerabilities)} issues found)")
    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")
    return vulnerabilities


def batch_analyze(input_dir, output_dir):
    """Batch analyze contract files in the directory"""
    os.makedirs(output_dir, exist_ok=True)
    total, vulnerable = 0, 0
    stats = defaultdict(int)
    sol_files = [f for f in os.listdir(input_dir) if f.endswith('.sol')]

    if DEBUG_MODE:
        print(f"Found {len(sol_files)} Solidity files, starting batch processing...")

    for i, fname in enumerate(sol_files, 1):
        fpath = os.path.join(input_dir, fname)
        total += 1
        if DEBUG_MODE:
            print(f"\n===== Processing file {i}/{len(sol_files)} =====")

        issues = detect_swc113(fpath)

        if issues:
            vulnerable += 1
            for issue in issues:
                stats[issue['pattern_type']] += 1

        # Generate report
        report_name = f"{os.path.splitext(fname)[0]}_swc113_report.txt"
        with open(os.path.join(output_dir, report_name), 'w', encoding='utf-8') as f:
            f.write(f"SWC-113 Report: {fname}\n")
            f.write("=" * 80 + "\n")
            if issues:
                f.write(f"Found {len(issues)} issues (sorted by risk):\n\n")
                sorted_issues = sorted(issues, key=lambda x: {'High': 3, 'Medium': 2, 'Low': 1}[x['risk']],
                                       reverse=True)
                for idx, issue in enumerate(sorted_issues, 1):
                    f.write(f"Issue {idx} ({issue['risk']})\n")
                    f.write(f"Contract: {issue['contract']} Function: {issue['function']}\n")
                    f.write(f"Risk type: {issue['pattern_type']}\n")
                    f.write(f"Line: {issue['line']}\n")
                    f.write(f"Code snippet: {issue['snippet']}\n")
                    f.write(f"Description: {issue['desc']}\n\n")
                    f.write("-" * 80 + "\n")
            else:
                f.write("No high-risk SWC-113 issues found.\n")

    print("\n" + "=" * 50)
    print(f"Analysis completed: {total} files processed, {vulnerable} with issues")
    print(f"Reports saved to: {os.path.abspath(output_dir)}")
    print("Risk type statistics:", dict(stats))


if __name__ == "__main__":
    # Configuration paths (using user-specified directory structure)
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-113'))

    if not os.path.exists(input_directory_path):
        print(f"Error: Input directory does not exist - {input_directory_path}")
        print("Please check if the path is correct or create the directory")
    else:
        batch_analyze(input_directory_path, output_directory_path)
