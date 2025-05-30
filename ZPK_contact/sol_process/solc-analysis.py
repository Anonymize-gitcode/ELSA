import os
import json
import subprocess


def windows_to_wsl_path(windows_path):
    """
    Convert Windows path to WSL path.
    """
    wsl_path = windows_path.replace('C:', '/mnt/c').replace('\\', '/')
    return wsl_path


def compile_solidity(file_path):
    """
    Compile the Solidity file using solc version 0.8.0 and return the AST output.
    """
    try:
        wsl_path = windows_to_wsl_path(file_path)
        command = f"wsl solc --combined-json ast {wsl_path}"

        result = subprocess.run(command, shell=True, capture_output=True)

        # Check for encoding issues and decode manually as UTF-8
        stdout = result.stdout.decode('utf-8', errors='ignore')
        stderr = result.stderr.decode('utf-8', errors='ignore')

        if result.returncode != 0:
            print(f"Compilation error: {stderr if stderr else 'Unknown error'}")
            return None, stderr

        print(f"Compilation succeeded, output content: {stdout[:500]}")  # Print first 500 chars for inspection

        return stdout, None
    except subprocess.CalledProcessError as e:
        print(f"Compilation error: {e.output}")
        return None, e.output


def remove_unwanted_content(data):
    """
    Recursively traverse AST data to remove content related to paths, filenames, comments, and documentation fields.
    """
    if isinstance(data, dict):
        # Remove fields related to file paths and comments
        keys_to_remove = [
            'overloadedDeclarations',
            'typeDescriptions',
            'contracts',
            'text',
            'sourceList',
            'src','id',
            'absolutePath',
            'version',
            'isConstant',
            'isLValue','lValueRequested',
            'isPure','value','expression',
            'indexExpression',
            'leftHandSide',
            'rightHandSide',
            'baseType','arguments',
            'parameters',
            'condition',
            'block',
            'body',
            'functionReturnParameters',
            'eventCall',
            'rightExpression',
            'leftExpression',
            'operator',
            'memberName'
            'lValueRequested',
            'nodeType',
            'kind',
            'commonType',
            'baseExpression',
            'referencedDeclaration',
            'hexValue','scope','abstract','license','fullyImplemented','functionSelector',
            'modifiers','storageLocation','constant','literals','typeName','virtual','exportedSymbols'
        ]

        for key in keys_to_remove:
            data.pop(key, None)
        # Recursively process nested dictionaries
        for key, value in data.items():
            remove_unwanted_content(value)
    elif isinstance(data, list):
        # Recursively process each item in the list
        for item in data:
            remove_unwanted_content(item)


def save_key_info(ast_data, output_file):
    """
    Save AST data as a TXT file, keeping all relevant entries.
    """
    with open(output_file, 'w') as f:
        json.dump(ast_data, f, indent=4)
    print(f"AST data saved to: {output_file}")


def process_sol_file(file_path, result_dir):
    """
    Compile the Solidity file, extract AST information, and save to the specified directory.
    """
    if not os.path.exists(file_path):
        print(f"File does not exist: {file_path}")
        return

    ast_output, error_output = compile_solidity(file_path)

    if ast_output is None or not ast_output.strip():
        print(f"Failed to extract key information: {file_path}")
        error_log_file = os.path.join(result_dir, os.path.basename(file_path).replace('.sol', '.txt'))
        with open(error_log_file, 'w') as f:
            f.write(error_output or "Unknown compilation error")
        print(f"Compilation error log saved to: {error_log_file}")
        return

    try:
        ast_data = json.loads(ast_output)

        # Remove content related to paths, filenames, comments, and documentation
        remove_unwanted_content(ast_data)

        output_file = os.path.join(result_dir, os.path.basename(file_path).replace('.sol', '.txt'))
        save_key_info(ast_data, output_file)
    except json.JSONDecodeError:
        print(f"Invalid solc output, not in JSON format: {file_path}")
        output_file = os.path.join(result_dir, os.path.basename(file_path).replace('.sol', '.txt'))
        with open(output_file, 'w') as f:
            f.write(ast_output)
        print(f"AST info saved to: {output_file}")


def process_all_sol_files(directory, result_dir):
    """
    Process all Solidity files in the specified directory using the fixed solc 0.8.0 version.
    """
    if not os.path.exists(result_dir):
        os.makedirs(result_dir)

    for file_name in os.listdir(directory):
        if file_name.endswith('.sol'):
            file_path = os.path.join(directory, file_name)
            print(f"Processing file: {file_path}")
            process_sol_file(file_path, result_dir)


def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/ZPK_contact'))
    result_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/solc-analysis'))

    process_all_sol_files(root_dir, result_dir)


if __name__ == "__main__":
    main()
