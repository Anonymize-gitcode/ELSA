import os
import subprocess
import re
from web3 import Web3

# Define input and output directories
input_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/smartbugs_curated'))
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/manticore_tool_analysis'))


# Convert paths to WSL format
input_dir_wsl = input_dir.replace("C:\\", "/mnt/c/").replace("\\", "/")
output_dir_wsl = output_dir.replace("C:\\", "/mnt/c/").replace("\\", "/")

# Extract Solidity version function
def extract_solidity_version(file_path):
    with open(file_path, 'r') as file:
        content = file.read()
        match = re.search(r'pragma solidity \^?(\d+\.\d+\.\d+)', content)
        if match:
            return match.group(1)
    return None

# Ensure the output directory exists
os.makedirs(output_dir, exist_ok=True)

# Connect to Ethereum node using Web3 (adjust provider accordingly)
w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))

# Check if Web3 is connected using the 'is_connected' method
if w3.is_connected():
    print("Successfully connected to the Ethereum node.")
else:
    print("Unable to connect to the Ethereum node.")
    exit()

# Function to check and ensure owner balance
def ensure_owner_balance(account, required_balance):
    balance = w3.eth.get_balance(account)
    # Manually convert Wei to Ether
    balance_in_ether = balance / 10**18  # Manually convert Wei to Ether
    print(f"Current balance: {balance_in_ether} ETH")

    if balance < required_balance:
        print(f"Balance is insufficient. Recharging...")
        # Specify a recharge amount in Ether (for example, 10 Ether)
        recharge_amount = required_balance - balance
        transaction = {
            'to': account,
            'from': account,
            'value': recharge_amount,  # Directly handle conversion
            'gas': 21000,
            'gasPrice': w3.toWei(20, 'gwei')  # Corrected method for Web3 7.x
        }
        try:
            txn_hash = w3.eth.send_transaction(transaction)
            print(f"Recharge successful. Transaction hash: {txn_hash.hex()}")
        except Exception as e:
            print(f"Failed to recharge account: {str(e)}")
            return False
    return True

# Set Solidity version function
def set_solc_version(version):
    try:
        print(f"Setting Solidity version to: {version}")
        subprocess.run(["wsl", "solc-select", "use", version], check=True)
        result = subprocess.run(["wsl", "solc", "--version"], capture_output=True, text=True, check=True)
        print(f"Current Solidity version: {result.stdout}")
    except subprocess.CalledProcessError as e:
        print(f"Unable to switch to Solidity version {version}: {str(e)}")

# Process each .sol file in the input directory
for file_name in os.listdir(input_dir):
    if file_name.endswith(".sol"):
        # Construct full input and output file paths
        input_file_path = os.path.join(input_dir, file_name)
        output_file_path = os.path.join(output_dir, f"{os.path.splitext(file_name)[0]}.txt")

        print(f"Analyzing file: {input_file_path} -> {output_file_path}")

        # Extract Solidity version
        sol_version = extract_solidity_version(input_file_path)
        if sol_version:
            print(f"Detected Solidity version: {sol_version}")
            # Switch to the detected solc version
            set_solc_version(sol_version)
        else:
            print("No Solidity version detected in the file.")
            continue

        # Check if the Solidity file contains contracts
        with open(input_file_path, 'r') as file:
            content = file.read()
            contracts = re.findall(r'contract (\w+)', content)

        if contracts:
            contract_to_analyze = contracts[0]  # Analyze only the first contract
            print(f"Analyzing contract: {contract_to_analyze}")
        else:
            print(f"No contracts found in {file_name}, skipping.")
            continue

        # Ensure the owner balance is sufficient
        account = w3.eth.accounts[0]  # Assuming the first account in Ganache
        required_balance = 10 * 10**18  # Direct number conversion for Wei
        if not ensure_owner_balance(account, required_balance):
            print("Insufficient balance, skipping this contract.")
            continue

        # Construct Manticore command for the selected contract
        command = [
            "wsl", ".../manticore", "-v", "--smt.solver", "z3",
            "--smt.z3_bin", ".../.local/bin/z3", f"/solidity/{file_name}", "--contract", contract_to_analyze
        ]

        try:
            # Run Manticore command and save output to file
            with open(output_file_path, "w") as output_file:
                subprocess.run(command, stdout=output_file, stderr=output_file, text=True)
            print(f"Analysis completed for: {file_name}")
        except subprocess.CalledProcessError as e:
            print(f"Analysis failed for {file_name}. Error: {str(e)}")
        except Exception as e:
            print(f"Unexpected error occurred during analysis of {file_name}. Error: {str(e)}")

print(f"All files analyzed, results saved in {output_dir}")
