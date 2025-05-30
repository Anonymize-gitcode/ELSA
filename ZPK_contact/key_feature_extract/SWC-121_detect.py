import re
import os

# Acceptable visibility modifiers
valid_visibility = ['public', 'internal', 'private']


# Check functions and state variables in a Solidity file
def check_visibility_in_solidity_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    errors = []

    # 1. Check if function declarations are missing visibility modifiers
    function_pattern = re.compile(r'function\s+(\w+)\s*\(.*\)\s*{')
    for line_num, line in enumerate(lines, start=1):
        functions = function_pattern.findall(line)
        for func in functions:
            if not any(visibility in line for visibility in valid_visibility):
                errors.append({
                    "VulnerabilityType": "FunctionWithoutVisibility",
                    "LineNumber": line_num,
                    "CodeSnippet": line.strip()
                })

    # 2. Check if sensitive functions are exposed as public
    sensitive_functions = [
        'resetBalance', 'withdraw', 'resetAllBalances', 'modifyTotalSupply',  # Example sensitive functions
    ]

    for line_num, line in enumerate(lines, start=1):
        for func in sensitive_functions:
            if func in line and 'public' in line:
                errors.append({
                    "VulnerabilityType": "SensitiveFunctionPublic",
                    "LineNumber": line_num,
                    "CodeSnippet": line.strip()
                })

    # 3. Check public setters of state variables
    state_variable_setter_pattern = re.compile(r'function\s+\w+\s*\(.*\)\s*public\s*{')
    for line_num, line in enumerate(lines, start=1):
        setter_functions = state_variable_setter_pattern.findall(line)
        for setter in setter_functions:
            if 'totalSupply' in setter or 'balance' in setter:  # If related to critical state variables
                errors.append({
                    "VulnerabilityType": "PublicStateVariablesSetter",
                    "LineNumber": line_num,
                    "CodeSnippet": line.strip()
                })

    # 4. Check if fallback or receive functions are public
    fallback_function_pattern = re.compile(r'fallback\(\)\s*external\s*payable\s*{')
    receive_function_pattern = re.compile(r'receive\(\)\s*external\s*payable\s*{')

    for line_num, line in enumerate(lines, start=1):
        if fallback_function_pattern.search(line):
            errors.append({
                "VulnerabilityType": "FallbackFunctionWithoutVisibility",
                "LineNumber": line_num,
                "CodeSnippet": line.strip()
            })
        if receive_function_pattern.search(line):
            errors.append({
                "VulnerabilityType": "ReceiveFunctionPublic",
                "LineNumber": line_num,
                "CodeSnippet": line.strip()
            })

    # 5. Check if constructor is missing visibility modifier
    constructor_pattern = re.compile(r'constructor\s*\(.*\)\s*{')
    for line_num, line in enumerate(lines, start=1):
        if constructor_pattern.search(line):
            if not any(visibility in line for visibility in valid_visibility):
                errors.append({
                    "VulnerabilityType": "ConstructorWithoutVisibility",
                    "LineNumber": line_num,
                    "CodeSnippet": line.strip()
                })

    # 6. Check if pure and view functions are exposed as public
    pure_view_pattern = re.compile(r'(function\s+\w+.*)\s*(view|pure)\s*\(.*\)\s*{')
    for line_num, line in enumerate(lines, start=1):
        pure_view_functions = pure_view_pattern.findall(line)
        for func, visibility in pure_view_functions:
            if visibility == 'view' or visibility == 'pure':
                if 'public' in func:
                    errors.append({
                        "VulnerabilityType": "PublicModifierFunction",
                        "LineNumber": line_num,
                        "CodeSnippet": line.strip()
                    })

    # 7. Check if private variables are exposed via public getter
    private_variable_pattern = re.compile(r'uint256\s+private\s+(\w+)\s*;\s*')
    getter_pattern = re.compile(r'function\s+\w+\s*\(.*\)\s*public\s+view\s*returns\s*\(.*\)\s*{')

    for line_num, line in enumerate(lines, start=1):
        if private_variable_pattern.search(line):
            variable = private_variable_pattern.search(line).group(1)
            getter_match = getter_pattern.search(line)
            if getter_match and variable in getter_match.group(0):
                errors.append({
                    "VulnerabilityType": "PrivateVariablePublicGetter",
                    "LineNumber": line_num,
                    "CodeSnippet": line.strip()
                })

    # 8. Check if initialization function is exposed as public
    initialize_function_pattern = re.compile(r'function\s+initialize\s*\(.*\)\s*public\s*{')
    for line_num, line in enumerate(lines, start=1):
        if initialize_function_pattern.search(line):
            errors.append({
                "VulnerabilityType": "PublicInitializationFunction",
                "LineNumber": line_num,
                "CodeSnippet": line.strip()
            })

    return errors


# Process all Solidity files in a directory
def process_directory(solidity_dir):
    results = {}

    # Traverse all .sol files in the folder
    for filename in os.listdir(solidity_dir):
        if filename.endswith('.sol'):
            file_path = os.path.join(solidity_dir, filename)
            errors = check_visibility_in_solidity_file(file_path)
            if errors:
                results[filename] = errors
            else:
                results[filename] = "No SWC-121 related vulnerabilities detected."

    return results


# Save detection results to the specified folder
def save_results(results, output_dir):
    # Create directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Save results as TXT files
    for file_name, errors in results.items():
        output_path = os.path.join(output_dir, f"{file_name}.txt")
        with open(output_path, 'w', encoding='utf-8') as txt_file:
            if isinstance(errors, str):
                txt_file.write(errors)  # If no vulnerabilities, write the message directly
            else:
                for error in errors:
                    txt_file.write(f"Potential vulnerability type (SWC-121): {error['VulnerabilityType']}\n")
                    txt_file.write(f"Line number: {error['LineNumber']}\n")
                    txt_file.write(f"Code snippet: {error['CodeSnippet']}\n")
                    txt_file.write("-" * 50 + "\n")

    print(f"Results saved to {output_dir}")


# Display check results
def display_results(results):
    if not results:
        print("No visibility issues found.")
    else:
        for file_name, errors in results.items():
            print(f"File: {file_name}")
            if isinstance(errors, str):
                print(errors)  # If no vulnerabilities, print the message
            else:
                for error in errors:
                    print(f"VulnerabilityType: {error['VulnerabilityType']}")
                    print(f"LineNumber: {error['LineNumber']}")
                    print(f"CodeSnippet: {error['CodeSnippet']}")
                    print()


# Main program
if __name__ == "__main__":
    solidity_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/ZPK_contact'))  # Set your Solidity file directory path
    output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-121'))  # Set output path
    results = process_directory(solidity_directory)
    save_results(results, output_directory)  # Save results
    display_results(results)  # Print results
