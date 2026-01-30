import os
import json
import subprocess
import re
from packaging import version

# Define available major versions with their latest release
AVAILABLE_VERSIONS = {
    '0.4': '0.4.26',  # Latest in the 0.4.x series
    '0.5': '0.5.17',  # Latest in the 0.5.x series
    '0.6': '0.6.12',  # Latest in the 0.6.x series
    '0.7': '0.7.6',   # Latest in the 0.7.x series
    '0.8': '0.8.30'   # Latest in the 0.8.x series
}

def windows_to_wsl_path(windows_path):
    """
    Convert Windows path to WSL path.
    """
    wsl_path = windows_path.replace('C:', '/mnt/c').replace('\\', '/')
    return wsl_path


def get_sol_version(file_path):
    """
    Extract Solidity version from the provided .sol file.
    Supports version ranges like >=0.5.0 <0.7.0.
    """
    with open(file_path, 'r') as f:
        lines = f.readlines()

    for line in lines:
        if line.startswith("pragma solidity"):
            version_line = line.strip().split(" ")
            print(version_line)
            print(len(version_line))
            if 2 < len(version_line) <= 3:
                version_str = version_line[2]
            else: version_str = version_line[3]
            print(version_str)
            print(f"Extracted version: {version_str}")  # Debugging line
            return version_str  # Return the version or version range (e.g., >=0.5.0 <0.7.0)
    return None


def install_and_use_solc_version(version):
    """
    Install and switch to the required solc version using solc-select utility.
    """
    print(version)
    try:
        # If the version starts with ^ or >=, only then check AVAILABLE_VERSIONS
        if version.startswith(('^', '>=')):
            major_version = version[1:].split('.')[0]  # Extract the major version (x)
            print(major_version)

            # Check if the major version exists in available versions
            if major_version not in AVAILABLE_VERSIONS:
                print(f"Warning: No available versions for major version {major_version}. Using the latest available version.")
                version = AVAILABLE_VERSIONS['0.8']  # Default fallback version to 0.8.x
            else:
                # For the requested version, select the latest available minor version within that major version
                version = AVAILABLE_VERSIONS[major_version]

        # Install and use the correct solc version
        print(f"Installing solc version {version} using solc-select...")
        install_command = f"wsl /home/.../bin/solc-select install {version}"
        subprocess.run(install_command, shell=True, check=True)

        print(f"Switching to solc version {version}...")
        use_command = f"wsl /home/.../bin/solc-select use {version}"
        subprocess.run(use_command, shell=True, check=True)

        print(f"Successfully switched to solc {version}.")
    except subprocess.CalledProcessError as e:
        print(f"Error while installing or switching to solc version {version}: {e}")


def parse_version(version_str):
    """
    Parse the version string to get the appropriate solc version.
    Supports exact versions, and caret versions (e.g., ^0.8.0) or greater than/equal versions (e.g., >=0.8.0).
    """
    version_str = version_str.strip()
    print(version_str)
    # Handle exact version (e.g., 0.8.0 or 0.8.12)
    if re.match(r"^\d+\.\d+\.\d+$", version_str):
        print(version_str)
        return version_str

    elif ' ' in version_str:
        # Split version range
        constraints = version_str.split(' ')
        versions = []

        for constraint in constraints:
            if constraint.startswith('>='):
                min_version = constraint[2:]
                versions.append(('>=', min_version))
            elif constraint.startswith('<'):
                max_version = constraint[1:]
                versions.append(('<', max_version))

        # Parse version range
        selected_version = None
        for operator, ver in versions:
            if operator == '>=':
                # Check if it meets the greater than or equal condition
                if version.parse(ver) > version.parse(selected_version if selected_version else '0.0.0'):
                    selected_version = ver
            elif operator == '<':
                # Check if it meets the less than condition
                if version.parse(ver) < version.parse(selected_version if selected_version else '9999.9.9'):
                    selected_version = ver

        print(f"Selected version from range: {selected_version}")
        return selected_version

    # Handle caret version (e.g., ^0.8.0) or greater than/equal version (e.g., >=0.8.0)
    elif version_str.startswith(('^', '>=')):
        version_prefix = version_str[1:]
        major = version_prefix.split('.')[1]
        #print(version_prefix,major)
        # Return the latest available version for the major version
        return AVAILABLE_VERSIONS.get(f"0.{major}")  # Default to 0.8.x

        # Handle exact equality version (e.g., =0.8.12)
    elif version_str.startswith('='):
        # Return the exact version without any modification
        return version_str[1:]  # Remove the '=' sign

    return version_str  # Return the original version if no special handling is needed


def compile_solidity(file_path, solc_version):
    """
    Compile the Solidity file using the specified solc version and return AST output.
    """
    try:
        # Install and switch to the required solc version
        install_and_use_solc_version(solc_version)

        # Prepare the command to compile the Solidity file
        wsl_path = windows_to_wsl_path(file_path)
        # Add double quotes to the file path to handle spaces and special characters
        command = f"wsl /home/.../bin/solc --combined-json ast \"{wsl_path}\""

        result = subprocess.run(command, shell=True, capture_output=True)

        # Check for encoding issues and manually decode to UTF-8
        stdout = result.stdout.decode('utf-8', errors='ignore')
        stderr = result.stderr.decode('utf-8', errors='ignore')

        if result.returncode != 0:
            print(f"Compilation error: {stderr if stderr else 'Unknown error'}")
            return None, stderr

        return stdout, None
    except subprocess.CalledProcessError as e:
        print(f"Compilation error: {e.output}")
        return None, e.output


def remove_unwanted_content(data):
    """
    Recursively traverse AST data to remove content related to paths, filenames, comments, and documentation fields.
    """
    if isinstance(data, dict):
        keys_to_remove = [
            'overloadedDeclarations', 'typeDescriptions', 'contracts', 'text', 'sourceList', 'src', 'id',
            'absolutePath', 'version', 'isConstant', 'isLValue', 'lValueRequested', 'isPure', 'value', 'expression',
            'indexExpression', 'leftHandSide', 'rightHandSide', 'baseType', 'arguments', 'parameters', 'condition',
            'block', 'body', 'functionReturnParameters', 'eventCall', 'rightExpression', 'leftExpression', 'operator',
            'memberName', 'lValueRequested', 'nodeType', 'kind', 'commonType', 'baseExpression', 'referencedDeclaration',
            'hexValue', 'scope', 'abstract', 'license', 'fullyImplemented', 'functionSelector', 'modifiers', 'storageLocation',
            'constant', 'literals', 'typeName', 'virtual', 'exportedSymbols'
        ]

        for key in keys_to_remove:
            data.pop(key, None)

        for key, value in data.items():
            remove_unwanted_content(value)
    elif isinstance(data, list):
        for item in data:
            remove_unwanted_content(item)


def save_key_info(ast_data, output_file):
    """
    Save AST data as a TXT file, keeping all relevant entries.
    Ensure that the target directory exists.
    """
    # Ensure the target directory exists
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

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

    # Get the solc version from the file
    solc_version_str = get_sol_version(file_path)
    if not solc_version_str:
        print(f"Could not extract solc version from: {file_path}")
        return

    # Parse and select the correct version
    solc_version = parse_version(solc_version_str)
    print(solc_version)
    if not solc_version:
        print(f"Invalid version specifier in: {file_path}")
        return

    ast_output, error_output = compile_solidity(file_path, solc_version)

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
    Process all .sol files in the given directory and compare the number of processed files
    with the successfully generated .txt files.
    """
    if not os.path.exists(directory):
        print(f"Directory does not exist: {directory}")
        return

    sol_files = [f for f in os.listdir(directory) if f.endswith('.sol')]
    print(f"Found {len(sol_files)} .sol files.")  # Print the number of .sol files found
    if not sol_files:
        print(f"No .sol files found in the directory: {directory}")
        return

    total_sol_files = len(sol_files)
    successful_files = 0
    failed_files = []

    for sol_file in sol_files:
        sol_file_path = os.path.join(directory, sol_file)
        print(f"Processing file: {sol_file_path}")
        try:
            process_sol_file(sol_file_path, result_dir)
            # Check if the corresponding .txt file was created
            output_file = os.path.join(result_dir, sol_file.replace('.sol', '.txt'))
            if os.path.exists(output_file):
                successful_files += 1
            else:
                failed_files.append(sol_file)
        except Exception as e:
            print(f"Error processing file {sol_file_path}: {e}")
            failed_files.append(sol_file)

    # Print the comparison of processed files
    print(f"\nProcessing complete: {successful_files}/{total_sol_files} files successfully processed.")
    if failed_files:
        print(f"Failed to generate .txt files for the following .sol files: {failed_files}")
    else:
        print("All .sol files were successfully processed.")


def main():
    # Specify the directory containing the .sol files and the result directory
    sol_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    result_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/solc-analysis'))

    # Process all .sol files in the specified directory
    process_all_sol_files(sol_directory, result_dir)


if __name__ == "__main__":
    main()
