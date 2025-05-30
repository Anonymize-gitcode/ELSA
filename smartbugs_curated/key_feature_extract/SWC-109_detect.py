import re
import os

# Define vulnerability detection patterns: low-level calls
VULNERABLE_PATTERNS = [
    r'\.call\(',                    # Normal call
    r'\.call\.value\([^\)]*\)\(',   # call.value with parameter
    r'\.delegatecall\(',            # delegatecall
    r'\.staticcall\(',              # staticcall
    r'\.send\(',                    # send
    r'selfdestruct\(',              # selfdestruct
]

# Define safe handling patterns
SAFE_PATTERNS = [
    r'require\(',                   # require check
    r'assert\(',                    # assert check
    r'if\s*\(!?\s*\w+\s*\)\s*',      # if condition check
    r'try\s*\{',                    # try-catch check
    r'revert\(',                    # revert check
]

# Define return value assignment patterns
RETURN_ASSIGN_PATTERNS = [
    r'\b(bool|var|uint|int)\s+\w+\s*=\s*\w+\.(call|delegatecall|staticcall|send)\(',  # return value assignment
]

# Define excluded safe library function calls (e.g., OpenZeppelin safe transfer)
SAFE_LIBRARIES = [
    r'openZeppelin.*safe.*Transfer\(',  # OpenZeppelin safe transfer function
    r'openZeppelin.*safe.*Approve\(',  # OpenZeppelin safe approve function
    r'openZeppelin.*safe.*Call\(',  # OpenZeppelin safe call
]

# Exclude some common known safe contexts
def is_known_safe_context(line):
    """
    Check if the low-level call is in a known safe context
    """
    # Ignore known safe contexts (e.g., `onlyOwner` access control, `constructor`, `fallback`, `receive`)
    if re.search(r'onlyOwner', line) and "function" in line:  # onlyOwner may be safe
        return True
    if re.search(r'public\s+function\s+fallback\(', line):  # skip fallback function
        return True
    if re.search(r'constructor\(', line):  # skip constructor
        return True
    if re.search(r'receive\(', line):  # skip receive function
        return True
    if re.search(r'function\s+\w+\s*\(.*\)\s*(public|private|internal|external)', line):  # skip public functions
        return True
    if re.search(r'modifier\s+\w+', line):  # skip modifier functions
        return True
    return False

def detect_low_level_calls(line, vulnerable_patterns):
    """
    Detect whether the current line contains low-level call patterns, optimized to reduce false positives
    """
    for pattern in vulnerable_patterns:
        if re.search(pattern, line):
            return True
    return False

def is_safely_handled(lines, line_num, safe_patterns):
    """
    Determine whether the current line and its context contain safe handling, optimized to reduce false positives
    """
    # Optimization: check context lines
    for safe_pattern in safe_patterns:
        if re.search(safe_pattern, lines[line_num - 1]):  # current line
            return True
        if line_num > 1 and re.search(safe_pattern, lines[line_num - 2]):  # previous line
            return True
        if line_num < len(lines) and re.search(safe_pattern, lines[line_num]):  # next line
            return True

    # Enhanced: skip known safe library functions like safeLowLevelCall
    if any(re.search(safe_lib, lines[line_num - 1]) for safe_lib in SAFE_LIBRARIES):
        return True

    return False

def check_return_value_usage(lines, line_num, return_assign_patterns, safe_patterns):
    """
    Detect whether the return value assignment is used afterwards to reduce false positives
    """
    for pattern in return_assign_patterns:
        if re.search(pattern, lines[line_num - 1]):
            # If the return value is a flag and has no subsequent processing, skip
            if "bool success = " in lines[line_num - 1] and "call.value" in lines[line_num - 1]:
                return True  # flag return value, no further processing needed

            # Check if subsequent lines have safe handling
            for i in range(line_num, len(lines)):
                for safe_pattern in safe_patterns:
                    if re.search(safe_pattern, lines[i]):
                        return True  # safe handling exists in subsequent lines

    return False

def should_skip_line(line):
    """
    Determine whether to skip checking the current line, enhanced for edge cases
    """
    return (
        line.strip().startswith("//") or
        "/*" in line or
        "*/" in line or
        not line.strip() or
        "constructor" in line or    # skip constructor
        "fallback" in line or       # skip fallback
        "receive" in line or        # skip receive
        re.match(r'\s*//.*', line)  # skip comment lines
    )

def analyze_file(file_path, output_path):
    """
    Analyze Solidity file for SWC-109 vulnerability
    """
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    vulnerabilities = []
    for line_num, line in enumerate(lines, start=1):
        if should_skip_line(line):
            continue  # skip irrelevant lines

        # Check for known safe contexts
        if is_known_safe_context(line):
            continue  # skip calls in known safe contexts

        # Detect low-level calls
        if detect_low_level_calls(line, VULNERABLE_PATTERNS):
            # Check for safe handling
            if not is_safely_handled(lines, line_num, SAFE_PATTERNS):
                # Check if return value is assigned and handled
                if not check_return_value_usage(lines, line_num, RETURN_ASSIGN_PATTERNS, SAFE_PATTERNS):
                    vulnerabilities.append(
                        f"Potential Vulnerability (SWC-109): Unchecked low-level call\n"
                        f"Location: Line {line_num}\n"
                        f"Code: {line.strip()}\n"
                        f"--------------------------------------------------"
                    )

    # Save detection result
    file_name = os.path.splitext(os.path.basename(file_path))[0] + '.txt'
    output_file_path = os.path.join(output_path, file_name)
    if vulnerabilities:
        with open(output_file_path, 'w', encoding='utf-8') as output_file:
            output_file.write("\n".join(vulnerabilities))
        return True
    else:
        with open(output_file_path, 'w', encoding='utf-8') as output_file:
            output_file.write("No SWC-109 related vulnerabilities detected.\n")
        return False

def scan_directory(input_dir, output_dir):
    """
    Scan all Solidity files in the directory
    """
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    total_files = 0
    no_vulnerabilities = 0

    for root, _, files in os.walk(input_dir):
        for file in files:
            if file.endswith(".sol"):
                total_files += 1
                file_path = os.path.join(root, file)
                if not analyze_file(file_path, output_dir):
                    no_vulnerabilities += 1

    print(f"Scanned {total_files} files in total.")
    print(f"Number of files with no vulnerabilities detected: {no_vulnerabilities}.")

# Set scan directory and result output directory
solidity_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/smartbugs_curated'))
# Set output directory for detection results
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-109'))  # Create if not exists

# Scan Solidity files in the directory, detect vulnerabilities and save results
scan_directory(solidity_directory, output_directory)
