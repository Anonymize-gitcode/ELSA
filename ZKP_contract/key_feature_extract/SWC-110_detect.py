import os
import re

# Define regex patterns related to common external calls and fund transfers
external_call_pattern = re.compile(r"\.(call|delegatecall|callcode|send|transfer)\{.*\}\(.*\);", re.DOTALL)
state_update_pattern = re.compile(r"\s*[\w\[\w\]\(\)\.\$]+\s*[\+\-\*/\=\<\>\!\&\|\^]+\s*[\w\[\w\]\(\)\.\$]+;", re.DOTALL)
require_pattern = re.compile(r"\brequire\(")
delegate_call_pattern = re.compile(r"\.delegatecall\{.*\}\(.*\);", re.DOTALL)
event_pattern = re.compile(r"\bevent\b")

def detect_reentrancy_vulnerabilities(file_path):
    """
    Detect reentrancy vulnerabilities in the given Solidity file,
    based on the pattern of updating state variables after external calls.

    :param file_path: Path to the Solidity file to analyze
    :return: List of detected vulnerabilities
    """
    vulnerabilities = []

    with open(file_path, 'r', encoding='utf-8') as file:
        sol_code = file.readlines()

        # Find matches for external calls, delegatecalls, and state variable modifications
        external_calls = []
        delegate_calls = []
        state_updates = []
        requires = []

        # Iterate over each line of code to capture matches and line numbers
        for i, line in enumerate(sol_code):
            if external_call_pattern.search(line):
                external_calls.append((i + 1, line.strip()))  # Store line number and match
            if delegate_call_pattern.search(line):
                delegate_calls.append((i + 1, line.strip()))
            if state_update_pattern.search(line):
                state_updates.append((i + 1, line.strip()))
            if require_pattern.search(line):
                requires.append((i + 1, line.strip()))

        # Check for cases where state variables are updated after external calls
        for call_line, call_code in external_calls + delegate_calls:
            for update_line, update_code in state_updates:
                if call_line < update_line:  # Ensure external call comes before state update
                    # If a require statement exists and state update comes after the external call,
                    # it may indicate a reentrancy vulnerability
                    if any(call_line < require_line < update_line for require_line, _ in requires):
                        vulnerabilities.append({
                            "vulnerability_type": "PotentialReentrancyWithoutMutex",  # Vulnerability type
                            "line": update_line,  # Line number
                            "code": update_code.strip()  # Relevant code
                        })

        # Check if event logging is associated with external calls and state updates
        for call_line, call_code in external_calls:
            for match in event_pattern.finditer("".join(sol_code)):  # Modified to single match object
                event_line = match.start()  # Get start position of the event
                event_code = match.group()  # Get matched event code
                if call_line < event_line:  # External call happens before the event
                    vulnerabilities.append({
                        "vulnerability_type": "PotentialReentrancyWithoutMutex",  # Vulnerability type
                        "line": event_line + 1,  # Line number
                        "code": event_code.strip()  # Relevant code
                    })

    return vulnerabilities


def process_directory(directory_path):
    """
    Process all Solidity files in a directory to detect reentrancy vulnerabilities.

    :param directory_path: Path to the directory containing Solidity files
    :return: List of detected vulnerabilities
    """
    all_vulnerabilities = []

    # Traverse all files in the directory
    for filename in os.listdir(directory_path):
        if filename.endswith(".sol"):
            file_path = os.path.join(directory_path, filename)
            vulnerabilities = detect_reentrancy_vulnerabilities(file_path)
            if vulnerabilities:
                all_vulnerabilities.append((filename, vulnerabilities))
            else:
                all_vulnerabilities.append((filename, None))  # No vulnerabilities found

    return all_vulnerabilities


def save_vulnerabilities(vulnerabilities, output_directory):
    """
    Save detected vulnerabilities to individual files corresponding to each Solidity file.

    :param vulnerabilities: List of vulnerabilities for each file
    :param output_directory: Path to the output folder
    """
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    # Traverse vulnerabilities for each file and save to separate files
    for filename, file_vulnerabilities in vulnerabilities:
        output_file = os.path.join(output_directory, f"{filename}.txt")

        with open(output_file, 'w', encoding='utf-8') as file:
            if file_vulnerabilities:
                # If vulnerabilities exist, write vulnerability details
                for vulnerability in file_vulnerabilities:
                    file.write(f"Potential vulnerability type (SWC-110): {vulnerability['vulnerability_type']}\n")
                    file.write(f"Line number: {vulnerability['line']}\n")
                    file.write(f"Relevant code: {vulnerability['code']}\n")
                    file.write("-" * 50 + "\n")
            else:
                # If no vulnerabilities, write a message indicating no detection
                file.write("No SWC-110 related vulnerabilities detected\n")


# Set Solidity file directory and output path
solidity_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/ZKP_contract'))  # Set your Solidity file directory path
output_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-110'))  # Set output path
# Detect vulnerabilities in the directory
vulnerabilities = process_directory(solidity_directory)

# Save each file's vulnerabilities to separate files
save_vulnerabilities(vulnerabilities, output_directory)

print(f"Detected vulnerabilities saved to {output_directory}")
