import os
import re

# Sensitive operations (graded by risk impact)
REENTRANCY_SENSITIVE_OPS = {
    # High-impact core financial operations (direct value transfer)
    'high': ['withdraw', 'transfer', 'send', 'payout', 'refund', 'sendValue'],
    # Medium-impact operations (affect financial state)
    'medium': ['deposit', 'claim', 'reward', 'distribute', 'rescue', 'transferFrom']
}

# State variables (focused on core financial relevance)
STATE_VARIABLE_PATTERNS = {
    # High-risk: directly related to balance and funds
    'high': [
        r'balance\s*\[', r'balances\s*\[',
        r'user_balance\s*\[', r'account_balance\s*\[',
        r'fund\s*\[', r'funds\s*\[', r'asset\s*\['
    ],
    # Medium-risk: affect authorization or debt
    'medium': [
        r'allowance\s*\[', r'allowances\s*\[',
        r'debt\s*\[', r'user_debt\s*\[',
    ]
}

# Reentrancy guard patterns (precise matching to avoid false negatives)
REENTRANCY_GUARD_PATTERNS = [
    # OpenZeppelin official protections
    r'\bnonReentrant\b',
    r'contract\s+\w+\s+is\s+ReentrancyGuard\b',
    # Strict custom locks (must have complete lock-call-unlock flow)
    r'(locked|reentrancyLock|_reentrancyLock)\s*=\s*true\s*;[^}]*\.(call|transfer|send)\(.*\)\s*;[^}]*\1\s*=\s*false',
    # Pre-check patterns
    r'require\s*\(\s*!(locked|reentrancyLock)\s*,\s*"[^"]+"\s*\);[^}]*\.(call|transfer)\('
]

# External call patterns (risk graded, exclude internal calls)
EXTERNAL_CALL_PATTERNS = {
    # High-risk: low-level calls with value
    'high': [
        r'\.\s*(call|delegatecall)\s*\{[^}]*value\s*:\s*[^}]*\}\s*\(',
        r'\.\s*call\s*\(\s*value\s*,\s*[^)]*\)\s*'
    ],
    # Medium-risk: external contract calls (exclude internal calls)
    'medium': [
        r'\s*I\w+\s*\(\s*\w+\s*\)\s*\.\s*[a-zA-Z0-9_]+\s*\(',  # Interface calls
        r'\s*address\s+\w+\s*=\s*[^;]+;\s*\w+\s*\.\s*[a-zA-Z0-9_]+\s*\('  # External address calls
    ]
}

# Access control patterns (precise matching)
ACCESS_CONTROL_PATTERNS = [
    r'onlyOwner\b', r'onlyAdmin\b', r'onlyGovernance\b',
    r'hasRole\s*\([^,]+,\s*msg\.sender\s*\)',
    r'require\s*\(\s*msg\.sender\s*==\s*owner\s*\)',
    r'require\s*\(\s*isAuthorized\s*\(\s*msg\.sender\s*\)\s*\)'
]


def remove_comments_and_strings(code):
    """Remove comments and strings to avoid analysis interference"""
    code = re.sub(r'//.*', '', code)
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', code)
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)
    return code


def find_matching_brace(code, start_pos):
    """Precisely match braces"""
    if start_pos >= len(code) or code[start_pos] != '{':
        return None
    count = 1
    pos = start_pos + 1
    while pos < len(code):
        if code[pos] == '{':
            count += 1
        elif code[pos] == '}':
            count -= 1
            if count == 0:
                return pos
        pos += 1
    return None


def get_line_number(original_code, abs_pos):
    """Calculate line number"""
    return original_code[:abs_pos].count('\n') + 1 if abs_pos >= 0 else 1


def extract_functions(cleaned_code):
    """Extract potentially risky functions (exclude view/pure)"""
    functions = []
    func_pattern = r'''
        (function\s+([a-zA-Z0-9_]+)|constructor)\s*  # Function name or constructor
        (?:\([^)]*\))?\s*                             # Parameters
        (?:(external|public|internal|private|payable)\s*)*  # Visibility
        (?:(view|pure)\s*)?                           # State modifiers
        \s*\{                                          # Start of function body
    '''
    for match in re.finditer(func_pattern, cleaned_code, re.VERBOSE | re.IGNORECASE):
        func_name = match.group(2) if match.group(2) else 'constructor'
        state_modifier = match.group(6)
        # Exclude view/pure (no state changes, no reentrancy risk)
        if state_modifier in ['view', 'pure']:
            continue
        # Extract function body
        start = match.start()
        brace_pos = match.group(0).rfind('{')
        if brace_pos == -1:
            continue
        end = find_matching_brace(cleaned_code, start + brace_pos)
        if end is None:
            continue
        func_code = cleaned_code[start:end + 1]
        functions.append({
            'name': func_name,
            'code': func_code,
            'start_pos': start,
            'visibility': 'external' if 'external' in func_code[:100].lower() else 'public'
        })
    return functions


def detect_external_calls(func_code, func_name):
    """Detect external calls with risk grading and exclude internal calls"""
    calls = []
    # High-risk calls (with value)
    for pattern in EXTERNAL_CALL_PATTERNS['high']:
        for match in re.finditer(pattern, func_code, re.IGNORECASE):
            calls.append({
                'snippet': match.group(0).strip(),
                'start': match.start(),
                'risk': 'high'
            })
    # Medium-risk calls (external contracts, exclude internal calls)
    for pattern in EXTERNAL_CALL_PATTERNS['medium']:
        for match in re.finditer(pattern, func_code, re.IGNORECASE):
            call_snippet = match.group(0).strip()
            # Exclude internal calls within the same contract (this.xxx())
            if 'this.' in call_snippet:
                continue
            calls.append({
                'snippet': call_snippet,
                'start': match.start(),
                'risk': 'medium'
            })
    return calls


def detect_state_updates(func_code, func_name):
    """Detect state updates, focusing on core variables"""
    updates = {'high': [], 'medium': []}
    # High-risk state updates (directly financial)
    for pattern in STATE_VARIABLE_PATTERNS['high']:
        for match in re.finditer(rf'{pattern}\s*[=+/-]\s*[^;]+;', func_code, re.IGNORECASE):
            updates['high'].append({'start': match.start()})
    # Medium-risk state updates
    for pattern in STATE_VARIABLE_PATTERNS['medium']:
        for match in re.finditer(rf'{pattern}\s*[=+/-]\s*[^;]+;', func_code, re.IGNORECASE):
            updates['medium'].append({'start': match.start()})
    return updates


def has_reentrancy_guard(func_code):
    """Precisely identify reentrancy protections"""
    for pattern in REENTRANCY_GUARD_PATTERNS:
        if re.search(pattern, func_code, re.IGNORECASE | re.DOTALL):
            return True
    return False


def get_sensitive_risk(func_name):
    """Calculate sensitive operation risk weight based on function name"""
    func_lower = func_name.lower()
    if any(op in func_lower for op in REENTRANCY_SENSITIVE_OPS['high']):
        return 3  # High weight
    if any(op in func_lower for op in REENTRANCY_SENSITIVE_OPS['medium']):
        return 2  # Medium weight
    return 0


def detect_swc107(file_path):
    """Risk-weighted vulnerability detection logic"""
    vulnerabilities = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_code = f.read()
        cleaned_code = remove_comments_and_strings(original_code)
        functions = extract_functions(cleaned_code)

        for func in functions:
            func_name = func['name']
            func_code = func['code']
            func_start = func['start_pos']

            # 1. Detect external calls
            external_calls = detect_external_calls(func_code, func_name)
            if not external_calls:
                continue

            # 2. Detect state updates
            state_updates = detect_state_updates(func_code, func_name)
            has_high_state = len(state_updates['high']) > 0
            has_any_state = has_high_state or len(state_updates['medium']) > 0
            if not has_any_state:
                continue  # No state updates, exclude

            # 3. Check for protection mechanisms (exclude if protected)
            if has_reentrancy_guard(func_code):
                continue

            # 4. Analyze call and state update order
            for call in external_calls:
                call_start = call['start']
                # External call before all state updates (core risk)
                is_early_call = all(
                    update['start'] > call_start
                    for update in state_updates['high'] + state_updates['medium']
                )
                # High-risk state updates after call (high risk)
                has_late_high_update = any(
                    update['start'] > call_start
                    for update in state_updates['high']
                )

                # Must meet risk order criteria
                if not (is_early_call or has_late_high_update):
                    continue

                # 5. Risk weight calculation (only report if total ≥4)
                risk_score = 0
                # Call risk (high=3, medium=2)
                risk_score += 3 if call['risk'] == 'high' else 2
                # Sensitive function weight
                risk_score += get_sensitive_risk(func_name)
                # Additional points for high-risk state updates
                if has_high_state:
                    risk_score += 1

                # Threshold control: only report risks with total score ≥4
                if risk_score < 4:
                    continue

                # Generate report
                abs_pos = func_start + call_start
                line = get_line_number(original_code, abs_pos)
                risk_level = "Critical" if risk_score >= 6 else "High"

                vulnerabilities.append({
                    'function': func_name,
                    'line': line,
                    'snippet': call['snippet'],
                    'risk_level': risk_level,
                    'score': risk_score,
                    'description': f"Reentrancy risk (Score: {risk_score}): {func_name} contains external calls with unsafe state update ordering"
                })

    except Exception as e:
        print(f"Error processing file {file_path}: {str(e)}")

    return vulnerabilities


def batch_analyze(input_dir, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    total_files = 0
    vulnerable_files = 0

    for root, _, files in os.walk(input_dir):
        for filename in files:
            if not filename.endswith('.sol'):
                continue
            total_files += 1
            file_path = os.path.join(root, filename)

            issues = detect_swc107(file_path)
            output_file = os.path.join(output_dir, f"{os.path.splitext(filename)[0]}_report.txt")

            with open(output_file, 'w', encoding='utf-8') as f:
                if issues:
                    vulnerable_files += 1
                    f.write(f"SWC-107 Vulnerability Report: {filename}\n")
                    f.write("=" * 80 + "\n")
                    f.write(f"High-confidence issues: {len(issues)}\n\n")

                    for i, issue in enumerate(issues, 1):
                        f.write(f"Issue #{i} ({issue['risk_level']})\n")
                        f.write(f"Function: {issue['function']}\n")
                        f.write(f"Line: {issue['line']}\n")
                        f.write(f"Code: {issue['snippet']}\n")
                        f.write(f"Risk Score: {issue['score']}\n")
                        f.write(f"Description: {issue['description']}\n\n")
                        f.write("-" * 80 + "\n\n")
                else:
                    f.write(f"No high-confidence reentrancy risks found in {filename}\n")

    print(f"Analysis complete: Processed {total_files} files, {vulnerable_files} contained high-confidence issues")


if __name__ == "__main__":
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-107'))

    if not os.path.exists(input_directory_path):
        print(f"Error: Input directory does not exist - {input_directory_path}")
    else:
        batch_analyze(input_directory_path, output_directory_path)
