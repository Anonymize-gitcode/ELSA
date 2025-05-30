import os
import subprocess
import re
from web3 import Web3
import chardet

# Define input and output directories
input_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/SolidiFI-benchmark'))
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/manticore_tool_analysis'))

# Convert paths to WSL format
input_dir_wsl = input_dir.replace("C:\\", "/mnt/c/").replace("\\", "/")
output_dir_wsl = output_dir.replace("C:\\", "/mnt/c/").replace("\\", "/")


# Function to extract Solidity version
def extract_solidity_version(file_path):
    # Read file in binary mode to detect encoding
    with open(file_path, 'rb') as file:
        raw_data = file.read()
        result = chardet.detect(raw_data)  # Detect file encoding
        encoding = result['encoding']  # Get detected encoding

    # Open file using detected encoding
    with open(file_path, 'r', encoding=encoding) as file:
        content = file.read()
        match = re.search(r'pragma solidity\s*(>=|<=|\^)?(\d+\.\d+\.\d+)', content)
        if match:
            return match.group(2)
    return None


# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

# Connect to Ethereum node
w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))

# Check if connection to node was successful
if w3.is_connected():
    print("Successfully connected to Ethereum node!")
else:
    print("Failed to connect to Ethereum node.")
    exit()


# Check and ensure account balance is sufficient
def ensure_owner_balance(account, required_balance):
    balance = w3.eth.get_balance(account)
    balance_in_ether = balance / 10 ** 18  # Convert to ETH manually
    print(f"Current balance: {balance_in_ether} ETH")

    if balance < required_balance:
        print(f"Insufficient balance, recharging...")
        recharge_amount = required_balance - balance
        transaction = {
            'to': account,
            'from': account,
            'value': recharge_amount,  # Handle conversion directly
            'gas': 21000,
            'gasPrice': w3.toWei(20, 'gwei')  # Correct call for Web3 7.x
        }
        try:
            txn_hash = w3.eth.send_transaction(transaction)
            print(f"Recharge successful. Transaction hash: {txn_hash.hex()}")
        except Exception as e:
            print(f"Recharge failed: {str(e)}")
            return False
    return True


# Set Solidity compiler version
def set_solc_version(version):
    try:
        if version == '0.5.00':
            version = '0.5.0'
        print(f"Setting Solidity version to: {version}")
        subprocess.run(["wsl", "/home/.../.local/bin/solc-select", "use", version], check=True)
        result = subprocess.run(["wsl", "/home/.../.local/bin/solc", "--version"], capture_output=True, text=True,
                                check=True)
        print(f"Current Solidity version: {result.stdout}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to switch to Solidity version {version}: {str(e)}")


# Enhanced regex to match contracts
def extract_contracts(content):
    # Enhanced regex to match various contract definitions
    contracts = re.findall(r'contract\s+(\w+)', content)
    return contracts


# Process each .sol file
for file_name in os.listdir(input_dir):
    if file_name.endswith(".sol"):
        input_file_path = os.path.join(input_dir, file_name)

        # Ensure output directory structure mirrors input
        relative_path = os.path.relpath(input_file_path, input_dir)
        output_subfolder = os.path.join(output_dir, os.path.dirname(relative_path))

        # Create output subfolder if it doesn't exist
        os.makedirs(output_subfolder, exist_ok=True)

        # Set output file path
        output_file_path = os.path.join(output_subfolder, f"{os.path.splitext(file_name)[0]}.txt")

        # Skip analysis if result file already exists
        if os.path.exists(output_file_path):
            print(f"Result file already exists, skipping analysis: {output_file_path}")
            continue

        print(f"Analyzing file: {input_file_path} -> {output_file_path}")

        # Extract Solidity version
        sol_version = extract_solidity_version(input_file_path)
        if sol_version:
            print(f"Detected Solidity version: {sol_version}")
            # Switch to detected solc version
            set_solc_version(sol_version)
        else:
            print("No Solidity version detected, skipping this file.")
            continue

        # Check whether the file contains contracts
        with open(input_file_path, 'r', encoding='utf-8') as file:
            content = file.read()
            contracts = extract_contracts(content)

        # Print number and names of contracts extracted from each file
        print(f"Detected {len(contracts)} contract(s): {contracts}")

        if contracts:
            for contract_to_analyze in contracts:  # Analyze all contracts
                print(f"Analyzing contract: {contract_to_analyze}")

                # Ensure account balance is sufficient
                account = w3.eth.accounts[0]  # Assume using first Ganache account
                required_balance = 10 * 10 ** 18  # 10 ETH, convert to Wei
                if not ensure_owner_balance(account, required_balance):
                    print("Insufficient balance, skipping this contract.")
                    continue

                # Construct Manticore command
                command = [
                    "wsl", "/home/.../.local/bin/manticore", "-v", "--smt.solver", "z3",
                    "--smt.z3_bin", "/home/.../.local/bin/z3",
                    f"/mnt/.../{file_name}",
                    "--contract", contract_to_analyze
                ]

                # Print command to check if paths are correct
                print(f"Executing command: {command}")

                try:
                    # Run Manticore command and save output to file
                    with open(output_file_path, "w") as output_file:  # Use "w" to overwrite
                        subprocess.run(command, stdout=output_file, stderr=output_file, text=True)
                        output_file.flush()  # Ensure data is written immediately
                    print(f"Analysis completed: {contract_to_analyze}")
                except subprocess.CalledProcessError as e:
                    print(f"Analysis failed: {contract_to_analyze}. Error: {str(e)}")
                except Exception as e:
                    print(f"Unexpected error during analysis: {contract_to_analyze}. Error: {str(e)}")
        else:
            print(f"No contracts found in {file_name}, skipping this file.")

print(f"All files have been analyzed. Results saved to {output_dir}")
