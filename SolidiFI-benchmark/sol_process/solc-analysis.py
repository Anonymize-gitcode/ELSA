import os
import json
import subprocess
import re


def windows_to_wsl_path(windows_path):
    """
    Convert Windows path to WSL path.
    """
    wsl_path = windows_path.replace('C:', '/mnt/c').replace('\\', '/')
    return wsl_path


def convert_to_wsl_path(windows_path):
    """
    Convert Windows path to WSL path.
    """
    return windows_path.replace("C:\\", "/mnt/c/").replace("\\", "/")


def compile_solidity(file_path):
    """
    Compile Solidity file using solc and return AST output.
    """
    try:
        wsl_path = windows_to_wsl_path(file_path)
        command = f"wsl solc --combined-json ast {wsl_path}"

        result = subprocess.run(command, shell=True, capture_output=True)

        # Check for encoding errors, decode manually as UTF-8
        stdout = result.stdout.decode('utf-8', errors='ignore')
        stderr = result.stderr.decode('utf-8', errors='ignore')

        if result.returncode != 0:
            print(f"Compilation error: {stderr if stderr else 'Unknown error'}")
            return None, stderr

        print(f"Compilation succeeded, output content: {stdout[:500]}")  # Print first 500 chars as preview

        return stdout, None
    except subprocess.CalledProcessError as e:
        print(f"Compilation error: {e.output}")
        return None, e.output


def remove_unwanted_content(data):
    """
    Recursively traverse AST data and remove path/filename-related content as well as comments/doc fields.
    """
    if isinstance(data, dict):
        # Remove fields related to file paths and comments
        keys_to_remove = [
            'overloadedDeclarations',
            'typeDescriptions',
            'contracts',
            'text',
            'sourceList',
            'src', 'id',
            'absolutePath',
            'version',
            'isConstant',
            'isLValue', 'lValueRequested',
            'isPure', 'value', 'expression',
            'indexExpression',
            'leftHandSide',
            'rightHandSide',
            'baseType', 'arguments',
            'parameters',
            'condition',
            'block',
            'body',
            'functionReturnParameters',
            'eventCall',
            'rightExpression',
            'leftExpression',
            'operator',
            'memberName',
            'lValueRequested',
            'nodeType',
            'kind',
            'commonType',
            'baseExpression',
            'referencedDeclaration',
            'hexValue', 'scope', 'abstract', 'license', 'fullyImplemented', 'functionSelector',
            'modifiers', 'storageLocation', 'constant', 'literals', 'typeName', 'virtual', 'exportedSymbols'
        ]

        for key in keys_to_remove:
            data.pop(key, None)
        # Recursively handle nested dicts
        for key, value in data.items():
            remove_unwanted_content(value)
    elif isinstance(data, list):
        # Recursively handle each element in list
        for item in data:
            remove_unwanted_content(item)


def save_key_info(ast_data, output_file):
    """
    Save AST data to TXT file, keeping all relevant entries.
    """
    with open(output_file, 'w') as f:
        json.dump(ast_data, f, indent=4)
    print(f"AST data saved to: {output_file}")


def extract_solidity_version(file_path):
    """
    Extract Solidity version from source file.
    """
    version_pattern = r"pragma solidity\s+([^;\s]+);"

    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
            match = re.search(version_pattern, content)
            if match:
                # Remove `^` from version
                return match.group(1).replace("^", "")
            else:
                raise ValueError(f"Unable to extract Solidity version from file {file_path}")
    except UnicodeDecodeError:
        print(f"File {file_path} encoding error, trying alternative encoding.")
        with open(file_path, 'r', encoding='ISO-8859-1') as file:
            content = file.read()
            match = re.search(version_pattern, content)
            if match:
                return match.group(1).replace("^", "")
            else:
                raise ValueError(f"Unable to extract Solidity version from file {file_path}")


def is_version_supported(version):
    """
    Check whether Solidity version is supported.
    """
    major, minor, patch = map(int, version.split('.'))
    if major == 0 and minor == 4 and patch < 5:
        return False
    return True


def install_and_switch_solc(version):
    """
    Install and switch to the specified solc version.
    """
    if not is_version_supported(version):
        print(f"Solidity version {version} is not supported, skipping this file.")
        return False
    try:
        subprocess.run(["wsl", "/home/.../.local/bin/solc-select", "install", version], check=True)
        subprocess.run(["wsl", "/home/.../.local/bin/solc-select", "use", version], check=True)
        print(f"Successfully switched to Solidity version {version}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Failed to switch to Solidity version {version}: {e}")
        return False


def process_sol_file(file_path, result_dir):
    """
    Compile Solidity file, extract AST info, and save to result directory.
    Skip if output file already exists.
    """
    if not os.path.exists(file_path):
        print(f"File does not exist: {file_path}")
        return

    output_file = os.path.join(result_dir, os.path.basename(file_path).replace('.sol', '.txt'))
    error_log_file = os.path.join(result_dir, os.path.basename(file_path).replace('.sol', '.txt'))

    if os.path.exists(output_file):
        print(f"Existing AST file found, skipping: {output_file}")
        return

    if os.path.exists(error_log_file):
        print(f"Existing error log found, skipping: {error_log_file}")
        return

    try:
        version = extract_solidity_version(file_path)
        if version == "0.5.00":
            version = "0.5.0"
        print(f"File {file_path} uses Solidity version {version}")
    except ValueError as e:
        print(f"Failed to extract Solidity version: {file_path}, error: {e}")
        return

    if not install_and_switch_solc(version):
        print(f"Unable to switch to Solidity {version}, skipping file: {file_path}")
        return

    ast_output, error_output = compile_solidity(file_path)

    if ast_output is None or not ast_output.strip():
        print(f"Unable to extract key information: {file_path}")
        with open(error_log_file, 'w') as f:
            f.write(error_output or "Unknown compilation error")
        print(f"Compilation error log saved to: {error_log_file}")
        return

    try:
        ast_data = json.loads(ast_output)
        remove_unwanted_content(ast_data)
        save_key_info(ast_data, output_file)
    except json.JSONDecodeError:
        print(f"Invalid solc output, not JSON format: {file_path}")
        with open(output_file, 'w') as f:
            f.write(ast_output)
        print(f"AST information saved to: {output_file}")


def process_all_sol_files(directory, result_dir):
    """
    Process all Solidity files in the specified directory.
    Skip if output file already exists.
    """
    if not os.path.exists(result_dir):
        os.makedirs(result_dir)

    for file_name in os.listdir(directory):
        if file_name.endswith('.sol'):
            file_path = os.path.join(directory, file_name)
            print(f"Processing file: {file_path}")

            output_file = os.path.join(result_dir, os.path.basename(file_path).replace('.sol', '.txt'))
            error_log_file = os.path.join(result_dir, os.path.basename(file_path).replace('.sol', '.txt'))

            if os.path.exists(output_file) or os.path.exists(error_log_file):
                print(f"File already processed, skipping: {file_path}")
                continue

            process_sol_file(file_path, result_dir)


def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/SolidiFI-benchmark'))
    result_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/solc-analysis'))

    process_all_sol_files(root_dir, result_dir)


if __name__ == "__main__":
    main()
