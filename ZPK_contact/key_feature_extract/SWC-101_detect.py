import os
import re
import hashlib

def simplify_large_number(num_str):
    """
    Convert very large numbers into scientific notation string.
    Example: 12345678901234567890 -> 1.2345678901234568e+19
    """
    try:
        # Try converting the large number to scientific notation
        num = int(num_str)
        if num > 10**18:  # Only simplify numbers longer than 18 digits
            return f"{num:.16e}"
        else:
            return num_str  # Return original if condition not met
    except ValueError:
        return num_str  # Return original if conversion fails

def check_overflow_underflow_operations(solidity_code):
    vulnerabilities = []
    detected_lines = set()  # Store already detected line numbers
    seen_large_numbers = set()  # Store hashes of detected large numbers
    large_number_pattern = r"\d{18,}"  # Match very large numbers

    # Store range of continuous lines
    previous_line = None
    range_start = None
    last_large_number_line = None  # Record last line with large number

    # Helper function: merge line number range
    def merge_line_range(start, end):
        if start == end:
            return f"{start}"
        else:
            return f"{start}-{end}"

    # Merge overflow/underflow, division by zero, modulo error lines
    def process_match(type_, match, line_number):
        nonlocal previous_line, range_start
        if previous_line is None or line_number != previous_line + 1:
            if previous_line is not None:
                vulnerabilities[-1]["line"] = merge_line_range(range_start, previous_line)
            range_start = line_number
            vulnerabilities.append({
                "type": type_,
                "line": line_number,
                "code": match.group(0).strip()
            })
            detected_lines.add(line_number)
        previous_line = line_number

    # Overflow/underflow risk check (e.g., +=, -=, *=, /=, %=)
    overflow_pattern = r"(\+=|\-=|\*=|\/=|\%=).*"
    overflow_matches = re.finditer(overflow_pattern, solidity_code)

    for match in overflow_matches:
        line_number = solidity_code.count('\n', 0, match.start()) + 1
        process_match("Potential overflow/underflow risk", match, line_number)

    # Unchecked operation check
    unchecked_pattern = r"unchecked\s*{[\s\S]*?}"
    unchecked_matches = re.finditer(unchecked_pattern, solidity_code)
    for match in unchecked_matches:
        if re.search(r"\+|\-|\*|\/|\%", match.group(0)):  # Check unchecked operation
            line_number = solidity_code.count('\n', 0, match.start()) + 1
            process_match("Unchecked operation with potential overflow/underflow", match, line_number)

    # Division by zero check
    division_by_zero_pattern = r"\/\s*0"
    division_matches = re.finditer(division_by_zero_pattern, solidity_code)
    for match in division_matches:
        line_number = solidity_code.count('\n', 0, match.start()) + 1
        process_match("Division by zero risk", match, line_number)

    # Modulo by zero check
    modulo_by_zero_pattern = r"\%\s*0"
    modulo_matches = re.finditer(modulo_by_zero_pattern, solidity_code)
    for match in modulo_matches:
        line_number = solidity_code.count('\n', 0, match.start()) + 1
        process_match("Modulo by zero risk", match, line_number)

    # Boundary check (avoid overflow or underflow)
    large_number_matches = re.finditer(large_number_pattern, solidity_code)
    for match in large_number_matches:
        line_number = solidity_code.count('\n', 0, match.start()) + 1
        num_str = match.group(0).strip()

        # Hash the number to avoid duplicate reports
        num_hash = hashlib.md5(num_str.encode()).hexdigest()

        # Skip if already reported
        if num_hash not in seen_large_numbers:
            if last_large_number_line is None or line_number != last_large_number_line + 1:
                # If not continuous, record current line
                if last_large_number_line is not None:
                    vulnerabilities[-1]["line"] = merge_line_range(range_start, last_large_number_line)
                range_start = line_number
                vulnerabilities.append({
                    "type": "Potential risk of overflow or underflow with large numbers",
                    "line": line_number,
                    "code": num_str
                })
            seen_large_numbers.add(num_hash)
            last_large_number_line = line_number  # Update last large number line

    # Final merge of line ranges
    if last_large_number_line is not None:
        vulnerabilities[-1]["line"] = merge_line_range(range_start, last_large_number_line)

    # Simplify all large numbers
    for vulnerability in vulnerabilities:
        if "large numbers" in vulnerability["type"]:
            vulnerability["code"] = simplify_large_number(vulnerability["code"])

    return vulnerabilities


def check_solidity_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        solidity_code = file.read()

    return check_overflow_underflow_operations(solidity_code)


def check_all_files_in_directory(input_directory, output_directory):
    # Ensure the output directory exists
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    # Iterate over all Solidity files in the directory
    for filename in os.listdir(input_directory):
        if filename.endswith(".sol"):  # Only process .sol files
            file_path = os.path.join(input_directory, filename)
            print(f"Checking file: {filename}")
            vulnerabilities = check_solidity_file(file_path)

            # Save results to file
            output_file_path = os.path.join(output_directory, f"{filename}.txt")
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                if vulnerabilities:
                    for vulnerability in vulnerabilities:
                        output_file.write(f"Potential vulnerability type (SWC-101): {vulnerability['type']}\n")
                        output_file.write(f"Line: {vulnerability['line']}\n")
                        output_file.write(f"Code: {vulnerability['code']}\n")
                        output_file.write("-" * 50 + "\n")
                else:
                    output_file.write("No SWC-101 related vulnerabilities detected\n")


if __name__ == "__main__":
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/ZPK_contact'))  # Set your Solidity file directory path
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-101'))  # Set output path

    check_all_files_in_directory(input_directory_path, output_directory_path)
