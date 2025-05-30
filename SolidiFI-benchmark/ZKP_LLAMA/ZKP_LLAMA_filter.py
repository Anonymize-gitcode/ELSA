import os
import openai

# Set OpenAI API key
openai.api_key = ('...')  # Please replace with your API key

# Input folder path (location of .sol_analysis.txt files)
input_folder_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/ZKP_LLAMA'))

# Output folder path (save the cleaning results)
output_folder_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/ZKP_LLAMA_filter'))

# Ensure the output folder exists
if not os.path.exists(output_folder_path):
    os.makedirs(output_folder_path)

def extract_info_from_gpt(content):
    """
    Use GPT to extract vulnerability information from contract analysis
    """
    prompt = f"""
    The following is a vulnerability analysis of a Solidity contract:

    {content}

    From the above contract analysis, extract the following:
    1. Vulnerability type and SWC code
    2. Vulnerability description

    Return in the following format:
    Vulnerability Type and SWC Code: [type and SWC code]
    Vulnerability Description: [description]
    Discard any other information such as contract IDs.
    Example:
    Vulnerability Type and SWC Code: [Reentrancy Vulnerability (SWC: Unknown SWC Code)]
    Vulnerability Description: The vulnerability exists in multiple contracts, lacking proper reentrancy protection. This may allow attackers to exploit reentrancy to disrupt the normal logic and flow of the contract. The recommended fix is to add a `nonReentrant` modifier and use it in critical functions to ensure they cannot be reentered, thereby preventing reentrancy attacks.
    """

    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",  # Using GPT-3.5 Turbo model
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": prompt}
        ]
    )

    # Extract GPT's response content
    return response['choices'][0]['message']['content'].strip()

def process_contract_files(input_folder_path):
    """
    Process each .sol_analysis.txt file in the folder, extract information and save it
    """
    # Iterate over each file in the folder
    for filename in os.listdir(input_folder_path):
        if filename.endswith(".sol_zkp_analysis.txt"):
            file_path = os.path.join(input_folder_path, filename)
            output_file_path = os.path.join(output_folder_path, filename)

            # Skip if output file already exists
            if os.path.exists(output_file_path):
                print(f"File '{filename}' already exists, skipping.")
                continue

            # Read file content
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()

            # Extract vulnerability info
            extracted_info = extract_info_from_gpt(content)

            # Save extracted information
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write(extracted_info)

            print(f"File '{filename}' has been processed and saved to '{output_file_path}'")

if __name__ == "__main__":
    process_contract_files(input_folder_path)
