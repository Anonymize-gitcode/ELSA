import os
import re
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed

# Input and output directories
input_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/SolidiFI-benchmark'))
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/securify_tool_analysis'))

# Convert Windows path to WSL path
def convert_to_wsl_path(windows_path):
    return windows_path.replace("C:\\", "/mnt/c/").replace("\\", "/")

# Extract Solidity version from file
def extract_solidity_version(file_path):
    version_pattern = r"pragma solidity\s+([^;\s]+);"

    with open(file_path, 'r') as file:
        content = file.read()
        match = re.search(version_pattern, content)
        if match:
            # Remove '^' symbol from version string
            return match.group(1).replace("^", "")
        else:
            raise ValueError(f"Cannot extract Solidity version from file {file_path}")

# Check if version is supported
def is_version_supported(version):
    major, minor, patch = map(int, version.split('.'))
    if major == 0 and minor == 4 and patch < 0:
        return False
    return True

# Install and switch to the specified solc version
def install_and_switch_solc(version):
    if not is_version_supported(version):
        print(f"Solidity version {version} is not supported, skipping this file.")
        return False
    try:
        subprocess.run(["wsl", "solc-select", "install", version], check=True)
        subprocess.run(["wsl", "solc-select", "use", version], check=True)
        print(f"Successfully switched to Solidity version {version}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Failed to switch to Solidity version {version}: {e}")
        return False

# Function to run Securify analysis
def run_securify(file_name):
    input_file_path = os.path.join(input_dir, file_name)
    output_file_path = os.path.join(output_dir, f"{os.path.splitext(file_name)[0]}.txt")

    # If the output file already exists, skip this file
    if os.path.exists(output_file_path):
        print(f"Analysis result for file {file_name} already exists, skipping analysis.")
        return

    # Extract Solidity version
    try:
        version = extract_solidity_version(input_file_path)
        print(f"Solidity version used in file {file_name}: {version}")
    except ValueError as e:
        print(e)
        return

    # Install and switch to corresponding solc version
    if not install_and_switch_solc(version):
        return

    # Dynamically set LD_LIBRARY_PATH if needed
    # os.environ['LD_LIBRARY_PATH'] = '/usr/lib/python3.10/lib-dynload:' + os.environ.get('LD_LIBRARY_PATH', '')

    # Construct Securify command
    command = [
        "wsl", "python3", "/mnt/c/.../securify2/securify",  # Use the latest version of Securify
        convert_to_wsl_path(input_file_path)  # Input file path
    ]

    try:
        # Execute command and save results to file
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)

        # Output stdout and stderr
        print(f"Standard Output: {result.stdout}")
        print(f"Error Output: {result.stderr}")

        # Save output file
        with open(output_file_path, "w") as output_file:
            output_file.write("Standard Output:\n")
            output_file.write(result.stdout)
            output_file.write("\nError Output:\n")
            output_file.write(result.stderr)

        print(f"Analysis completed: {file_name}")

    except subprocess.CalledProcessError as e:
        print(f"Command execution failed, error: {e}")
        print(f"Standard Output: {e.stdout}")
        print(f"Error Output: {e.stderr}")

        # Even if command fails, write stdout and stderr to file
        with open(output_file_path, "w") as output_file:
            output_file.write("Standard Output:\n")
            output_file.write(e.stdout)
            output_file.write("\nError Output:\n")
            output_file.write(e.stderr)

    except Exception as e:
        print(f"Unexpected error occurred: {e}")
        with open(output_file_path, "w") as output_file:
            output_file.write("Unexpected Error:\n")
            output_file.write(str(e))

# Get all .sol files
sol_files = [file for file in os.listdir(input_dir) if file.endswith(".sol")]

# Set maximum number of concurrent threads
max_workers = 1  # Set max concurrency to 1

# Use multithreading to analyze Solidity files in parallel
with ThreadPoolExecutor(max_workers=max_workers) as executor:
    futures = {executor.submit(run_securify, file): file for file in sol_files}

    # Wait for threads to complete and handle results
    for future in as_completed(futures):
        try:
            future.result()  # Get return value from thread (if any)
        except Exception as e:
            print(f"Error occurred while analyzing file: {e}")

print(f"All files have been analyzed, results are saved in {output_dir}")
