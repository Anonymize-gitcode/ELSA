import os
import re
from collections import defaultdict

# SWC-111: Using deprecated Solidity functions/keywords
# Deprecated function mapping: {deprecated item: (replacement, version deprecated, version removed)}
DEPRECATED_ITEMS = {
    # Functions/Operators
    'suicide': ('selfdestruct', '0.4.21', '0.5.0'),
    'throw': ('revert()', '0.4.13', '0.5.0'),
    'msg.gas': ('gasleft()', '0.4.21', '0.5.0'),
    'block.blockhash': ('blockhash()', '0.4.22', '0.5.0'),
    'callcode': ('delegatecall', '0.4.17', '0.5.0'),
    'sha3': ('keccak256', '0.4.0', '0.5.0'),

    # Keywords
    'var': ('specific type declaration', '0.4.20', '0.5.0'),
    'constant': ('view', '0.4.17', '0.5.0'),
    'now': ('block.timestamp', '0.5.0', None),

    # Old access control
    'tx.origin': ('msg.sender (use with caution)', 'not recommended', None),
}

# Regular expressions for excluding strings and comments
STRING_PATTERNS = [
    r'"(?:\\.|[^"\\])*"',  # Double-quoted string
    r"'(?:\\.|[^'\\])*'",  # Single-quoted string
    r'`(?:\\.|[^`\\])*`'  # Backtick string
]

COMMENT_PATTERNS = [
    r'//.*',  # Single-line comment
    r'/\*.*?\*/'  # Multi-line comment
]


def extract_solidity_version(code):
    """Extract the Solidity version declared in the contract"""
    version_pattern = r'pragma\s+solidity\s+([^;]+);'
    match = re.search(version_pattern, code)
    if not match:
        return None

    version_str = match.group(1).strip()
    # Handle complex version declarations like ^0.8.0 or >=0.7.0 <0.9.0
    version_numbers = re.findall(r'\d+\.\d+\.\d+', version_str)
    return version_numbers[0] if version_numbers else None


def parse_version(version):
    """Convert the version string to a tuple for comparison"""
    if not version:
        return (0, 0, 0)
    parts = list(map(int, version.split('.')))
    while len(parts) < 3:
        parts.append(0)
    return tuple(parts)


def is_version_affected(version, deprecated_since, removed_in):
    """Check if the given version is affected by deprecated items"""
    if not version:
        return True  # Unknown version is assumed to be affected

    ver = parse_version(version)
    since = parse_version(deprecated_since)

    if removed_in:
        removed = parse_version(removed_in)
        return since <= ver < removed
    return ver >= since


def clean_code(code):
    """Clean the code by removing comments and strings to avoid interference with detection"""
    cleaned = code

    # Remove comments
    for pattern in COMMENT_PATTERNS:
        cleaned = re.sub(pattern, '', cleaned, flags=re.DOTALL)

    # Remove strings
    for pattern in STRING_PATTERNS:
        cleaned = re.sub(pattern, '', cleaned)

    # Compress whitespace
    cleaned = re.sub(r'\s+', ' ', cleaned).strip()
    return cleaned


def find_matching_brace(code, start_pos):
    """Find the matching brace position"""
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


def extract_contracts(code):
    """Extract contract information"""
    contracts = []
    contract_pattern = r'(contract|library|interface)\s+(\w+)\s*(?:is\s+[\w\s,]+)?\s*{'

    for match in re.finditer(contract_pattern, code):
        contract_type = match.group(1)
        contract_name = match.group(2)
        start_pos = match.start()
        end_pos = find_matching_brace(code, match.end() - 1)

        if not end_pos:
            continue

        contract_code = code[start_pos:end_pos + 1]
        contracts.append({
            'name': contract_name,
            'type': contract_type,
            'code': contract_code,
            'start': start_pos,
            'end': end_pos
        })

    return contracts


def extract_functions(contract_code):
    """Extract functions from the contract"""
    functions = []
    func_pattern = r'function\s+(\w+)\s*\([^)]*\)\s*(?:modifier\d*\s*)*[^{]*{'

    for match in re.finditer(func_pattern, contract_code):
        func_name = match.group(1)
        start_pos = match.start()
        end_pos = find_matching_brace(contract_code, match.end() - 1)

        if not end_pos:
            continue

        func_code = contract_code[start_pos:end_pos + 1]
        functions.append({
            'name': func_name,
            'code': func_code,
            'start': start_pos,
            'end': end_pos
        })

    # Handle constructor functions
    constructor_pattern = r'constructor\s*\([^)]*\)\s*(?:modifier\d*\s*)*[^{]*{'
    for match in re.finditer(constructor_pattern, contract_code):
        start_pos = match.start()
        end_pos = find_matching_brace(contract_code, match.end() - 1)

        if not end_pos:
            continue

        func_code = contract_code[start_pos:end_pos + 1]
        functions.append({
            'name': 'constructor',
            'code': func_code,
            'start': start_pos,
            'end': end_pos
        })

    return functions


def get_line_number(original_code, position):
    """Get the line number based on position"""
    if position < 0:
        return 1
    return original_code[:position].count('\n') + 1


def detect_deprecated_usage(code, original_code, version):
    """Detect the usage of deprecated items in the code"""
    issues = []
    cleaned_code = clean_code(code)

    # Check each deprecated item
    for deprecated, (replacement, since, removed) in DEPRECATED_ITEMS.items():
        # Check if the current version is affected
        if not is_version_affected(version, since, removed):
            continue

        # Use different matching patterns based on the deprecated item type
        if '.' in deprecated:  # e.g., block.blockhash
            parts = deprecated.split('.')
            pattern = r'\b' + re.escape(parts[0]) + r'\s*\.\s*' + re.escape(parts[1]) + r'\b'
        else:  # e.g., suicide, throw, etc.
            # Special handling for function calls and keywords
            if deprecated in ['suicide', 'throw', 'sha3', 'callcode']:
                pattern = r'\b' + re.escape(deprecated) + r'\s*\('  # Function call
            else:
                pattern = r'\b' + re.escape(deprecated) + r'\b'  # Keyword

        # Find all matches
        for match in re.finditer(pattern, cleaned_code):
            # Ensure the match is not inside a string or comment (double check)
            start = match.start()
            end = match.end()

            # Get the original position in the code
            original_pos = code.find(cleaned_code[:start], 0) + start
            line = get_line_number(original_code, original_pos)

            # Extract code snippet for the report
            snippet_start = max(0, original_pos - 30)
            snippet_end = min(len(original_code), original_pos + 50)
            snippet = original_code[snippet_start:snippet_end].replace('\n', ' ')

            # Determine risk level
            risk_level = "High" if removed and is_version_affected(version, removed, None) else "Medium"

            issues.append({
                'deprecated': deprecated,
                'replacement': replacement,
                'since': since,
                'removed': removed,
                'line': line,
                'snippet': snippet,
                'risk_level': risk_level
            })

    return issues


def detect_swc111(file_path):
    """Detect SWC-111 vulnerabilities"""
    vulnerabilities = []

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_code = f.read()

        # Extract Solidity version
        version = extract_solidity_version(original_code)

        # Extract contracts
        contracts = extract_contracts(original_code)

        for contract in contracts:
            contract_name = contract['name']
            contract_code = contract['code']
            contract_start = contract['start']

            # Extract functions
            functions = extract_functions(contract_code)

            # Detect deprecated usage at contract level
            contract_issues = detect_deprecated_usage(
                contract_code, original_code, version
            )
            for issue in contract_issues:
                # Handle version deprecation descriptions to avoid f-string nesting
                if issue['removed']:
                    version_desc = f"and fully removed in v{issue['removed']}"
                else:
                    version_desc = "not recommended"

                vulnerabilities.append({
                    'type': 'SWC-111',
                    'contract': contract_name,
                    'function': 'contract-level',
                    'deprecated': issue['deprecated'],
                    'replacement': issue['replacement'],
                    'since': issue['since'],
                    'removed': issue['removed'],
                    'risk_level': issue['risk_level'],
                    'line': issue['line'],
                    'code_snippet': issue['snippet'],
                    'description': f"Used deprecated '{issue['deprecated']}', should replace with '{issue['replacement']}'."
                                   f" This feature has been deprecated since v{issue['since']}, {version_desc}"
                })

            # Detect deprecated usage in functions
            for func in functions:
                func_name = func['name']
                func_code = func['code']
                func_start = contract_start + func['start']

                func_issues = detect_deprecated_usage(
                    func_code, original_code, version
                )
                for issue in func_issues:
                    # Handle version deprecation descriptions to avoid f-string nesting
                    if issue['removed']:
                        version_desc = f"and fully removed in v{issue['removed']}"
                    else:
                        version_desc = "not recommended"

                    vulnerabilities.append({
                        'type': 'SWC-111',
                        'contract': contract_name,
                        'function': func_name,
                        'deprecated': issue['deprecated'],
                        'replacement': issue['replacement'],
                        'since': issue['since'],
                        'removed': issue['removed'],
                        'risk_level': issue['risk_level'],
                        'line': issue['line'],
                        'code_snippet': issue['snippet'],
                        'description': f"Function '{func_name}' uses deprecated '{issue['deprecated']}', should replace with '{issue['replacement']}'."
                                       f" This feature has been deprecated since v{issue['since']}, {version_desc}"
                    })

    except Exception as e:
        print(f"Error processing file {file_path}: {str(e)}")

    return vulnerabilities


def batch_analyze(input_dir, output_dir):
    """Batch analyze contract files in the directory and generate reports"""
    os.makedirs(output_dir, exist_ok=True)
    total_files = 0
    vulnerable_files = 0
    issue_stats = defaultdict(int)

    for filename in os.listdir(input_dir):
        if not filename.endswith('.sol'):
            continue

        total_files += 1
        file_path = os.path.join(input_dir, filename)
        issues = detect_swc111(file_path)

        if issues:
            vulnerable_files += 1
            for issue in issues:
                issue_stats[issue['deprecated']] += 1

        # Generate report file
        output_file = os.path.join(output_dir, f"{os.path.splitext(filename)[0]}_swc111_report.txt")
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(f"SWC-111 Vulnerability Report: {filename}\n")
            f.write("=" * 80 + "\n")

            version = extract_solidity_version(open(file_path, 'r').read())
            f.write(f"Solidity Version: {version or 'Not specified'}\n\n")

            if issues:
                f.write(f"Found {len(issues)} issues:\n\n")
                for i, issue in enumerate(issues, 1):
                    f.write(f"Issue #{i} (Risk level: {issue['risk_level']})\n")
                    f.write(f"Contract: {issue['contract']}\n")
                    f.write(f"Function: {issue['function']}\n")
                    f.write(f"Deprecated item: {issue['deprecated']}\n")
                    f.write(f"Recommended replacement: {issue['replacement']}\n")
                    f.write(f"Line number: {issue['line']}\n")
                    f.write(f"Code snippet: {issue['code_snippet']}\n")
                    f.write(f"Description: {issue['description']}\n\n")
                    f.write("-" * 80 + "\n\n")
            else:
                f.write("No SWC-111 vulnerabilities found.\n")

    # Output statistics
    print("\nAnalysis complete:")
    print(f"Total files processed: {total_files}")
    print(f"Files with issues: {vulnerable_files}")
    print("\nDeprecated item usage statistics:")
    for item, count in sorted(issue_stats.items(), key=lambda x: x[1], reverse=True):
        print(f"  {item}: {count} times")
    print(f"\nReports saved to: {os.path.abspath(output_dir)}")


if __name__ == "__main__":
    # Configure input and output paths
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-111'))

    if not os.path.exists(input_directory):
        print(f"Error: Input directory does not exist - {input_directory}")
        print("Please create the directory or modify the path in the script.")
    else:
        batch_analyze(input_directory, output_directory)
