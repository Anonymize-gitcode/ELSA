import os
import openai

# Set openai API key
openai.api_key = '...'  # Please replace with your API key

# Enter the folder path (.Sol\u analysis.txt file location)
input_folder_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/ZKP_LLAMA'))

# Output folder path (save the cleaning results)
output_folder_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/ZKP_LLAMA_filter'))

# Ensure that the output folder exists
if not os.path.exists(output_folder_path):
    os.makedirs(output_folder_path)

def extract_info_from_gpt(content):
    """
    Using GPT to extract vulnerability information in contract analysis
    """
    prompt = f"""
    The following is a vulnerability analysis of a Solidity contract:

    {content}

    From the above contract analysis, extract the following information:
    1. Vulnerability type and SWC code
    2. Vulnerability description

    Return in the following format:
    Vulnerability Type and SWC Code: [Vulnerability type and SWC code]
    Vulnerability Description: [Description]
    Omit all other information such as contract identifiers, etc.

    Example:
    Vulnerability Type and SWC Code: [Reentrancy Vulnerability (SWC: Unknown SWC ID)]
    Vulnerability Description: The vulnerability exists in multiple contracts and lacks proper protection against reentrancy attacks. 
    This may allow an attacker to exploit reentrancy to disrupt the normal logic and flow of the contract. 
    A recommended fix is to add the `nonReentrant` modifier and use it in critical functions to ensure they cannot be re-entered, thereby preventing reentrancy attacks.
    """

    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",  # use GPT-3.5 Turbo
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": prompt}
        ]
    )

    # Extract the content returned by GPT
    return response['choices'][0]['message']['content'].strip()

def process_contract_files(input_folder_path):
    """
     Process each.Sol_analysis.txt file in the folder, extract information and save
    """
    # Traverse each file in the folder
    for filename in os.listdir(input_folder_path):
        if filename.endswith(".sol_zkp_analysis.txt"):
            file_path = os.path.join(input_folder_path, filename)
            output_file_path = os.path.join(output_folder_path, filename)

            # if exist
            if os.path.exists(output_file_path):
                print(f"The file '{filename}' already exists, skipping processing.")
                continue

            # read
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()

            # extract
            extracted_info = extract_info_from_gpt(content)

            # save
            with open(output_file_path, 'w', encoding='utf-8') as output_file:
                output_file.write(extracted_info)

            print(f"File '{filename}' processed and saved to '{output_file_path}'")

if __name__ == "__main__":
    process_contract_files(input_folder_path)
