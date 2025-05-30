import os
import re
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

# Load model and word breaker
model_path = "..."  # Replace with your model path
device_gpu = torch.device("cuda" if torch.cuda.is_available() else "cpu")
device_cpu = torch.device("cpu")

# Load word breaker
tokenizer = AutoTokenizer.from_pretrained(model_path, use_fast=False)
tokenizer.pad_token = tokenizer.eos_token  # Set pad_token as eos_token

# Load model to GPU
model = AutoModelForCausalLM.from_pretrained(model_path).to(device_gpu)


# Regular expressions for matching contracts
contract_pattern = r'contract\s+(\w+)\s*{([^}]+)}|interface\s+(\w+)\s*{([^}]+)}|library\s+(\w+)\s*{([^}]+)}|abstract\s+contract\s+(\w+)\s*{([^}]+)}'


def split_contracts_from_file(file_path):
    """
    Extract the contract code from the solid file and disassemble it into a separate contract part
    """
    with open(file_path, 'r', encoding='utf-8') as file:
        solidity_code = file.read()

    # Use regular expressions to match contracts, interfaces, libraries and other structures
    contracts = re.findall(contract_pattern, solidity_code)

    # Extract the name and content of each contract
    split_contracts = []
    for contract in contracts:
        contract_name = None
        contract_code = None

        # Match every possible contract structure
        if contract[0]:  # contract
            contract_name = contract[0]
            contract_code = contract[1]
        elif contract[2]:  # interface
            contract_name = contract[2]
            contract_code = contract[3]
        elif contract[4]:  # library
            contract_name = contract[4]
            contract_code = contract[5]
        elif contract[6]:  # abstract contract
            contract_name = contract[6]
            contract_code = contract[7]

        split_contracts.append({'contract_name': contract_name, 'contract_code': contract_code.strip()})

    return split_contracts


def save_contracts_to_files(contracts, output_dir):
    """
    Save the disassembled contract code to a file
    """
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for contract in contracts:
        file_name = f"{contract['contract_name']}.sol"
        file_path = os.path.join(output_dir, file_name)

        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(f"// {contract['contract_name']} contract\n")
            file.write(contract['contract_code'])

    print(f"Contracts have been saved to {output_dir}")


# Define the resolution and analysis functions of the solid file
def analyze_solidity_file(file_path, model, tokenizer, device_gpu, device_cpu, max_new_tokens=512, temperature=0.7):
    """
    Perform vulnerability analysis on the given solid file
    Args:
    File_path (STR): local solid file path
    Model: loaded model
    Tokenizer: loaded word breaker
    Device_gpu: reasoning with GPU
    Device_cpu: use CPU for data processing
    Max_new_tokens (int): maximum number of new characters generated
    Temperature (float): control the randomness of generation
    Returns:
    Str: analysis results
    """
    # Split all contracts in the file
    contracts = split_contracts_from_file(file_path)

    # Analyze each contract
    analysis_results = []
    for idx, contract in enumerate(contracts):
        contract_code = contract['contract_code']
        prompt = (f"Please analyze the vulnerabilities in the following solid contracts and return the list of SWC codes."
                  f"The detection range is: \n"
                  f"'SWC-101':'Integer_Overflow_and_Underflow', "
                  f"'SWC-105':'Unprotected_Ether_Withdrawal', "
                  f"'SWC-107':'Reentrancy', "
                  f"'SWC-110':'Assert_Violation', "
                  f"'SWC-121':'Missing_Protection_Against_Signature_Replay_Attacks', "
                  f"'SWC-124':'Write_to_Arbitrary_Storage_Location', "
                  f"'SWC-128':'DoS_with_Block_Gas_Limit_Gas'.\n"
                  f"Solidity Contract Code: {contract_code}\n\n")

        # Put the input data on the CPU for processing
        inputs = tokenizer(
            prompt,
            return_tensors="pt",
            truncation=True,
            max_length=1024,  # Increase input length
            padding=True
        ).to(device_cpu)  # Processing input data on the CPU

        # Transfer model input to GPU for reasoning
        inputs = {key: value.to(device_gpu) for key, value in inputs.items()}

        # Model generation analysis results (calculated on GPU)
        outputs = model.generate(
            input_ids=inputs["input_ids"],
            attention_mask=inputs["attention_mask"],  # Explicitly pass the attention_mask
            max_new_tokens=256,  # Control the length of the generated output
            temperature=temperature,
            top_k=50,
            top_p=0.95,
            do_sample=True
        )

        # Decode and save analysis results
        result = tokenizer.decode(outputs[0], skip_special_tokens=True)
        analysis_results.append(f"Contract {idx + 1} Analysis:\n{result}\n\n")

    # Summarize the analysis results of all contracts
    return "\n".join(analysis_results)


# Batch process all.Sol files and save analysis results
def process_and_save_analysis(input_folder, output_folder, model, tokenizer, device_gpu, device_cpu):
    """
    Batch process the solid files and save the analysis results
    Args:
    Input_folder (STR): the path to the folder containing the.Sol file
    Output_folder (STR): the path to the folder where the analysis results are saved
    """
    # Ensure that the output folder exists
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    # Traverse all .Sol files in the folder
    for filename in os.listdir(input_folder):
        if filename.endswith(".sol"):
            file_path = os.path.join(input_folder, filename)
            print(f"Analyzing file: {file_path}")
            try:
                # Analyze the Solidity file
                analysis_result = analyze_solidity_file(file_path, model, tokenizer, device_gpu, device_cpu)

                # Save the analysis results to the corresponding file
                result_file_path = os.path.join(output_folder, f"{filename}_zkp_analysis.txt")
                with open(result_file_path, "w", encoding="utf-8") as result_file:
                    result_file.write(analysis_result)
                print(f"Analysis result saved to: {result_file_path}")
            except Exception as e:
                print(f"Error during analysis of {filename}: {e}")


# Input and output folder paths
input_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/ZPK_contact'))
output_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/ZKP_LLAMA'))

# Perform batch processing
process_and_save_analysis(input_folder, output_folder, model, tokenizer, device_gpu, device_cpu)
