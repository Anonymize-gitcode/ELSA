import os
import openai
import time
import logging
from dotenv import load_dotenv  # You need to install python-dotenv

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('extraction.log'),
        logging.StreamHandler()
    ]
)

# Load environment variables
load_dotenv()

# Get API key from environment variable
openai.api_key = ("...")
if not openai.api_key:
    logging.error("OpenAI API key not found, please set the environment variable OPENAI_API_KEY")
    raise ValueError("OpenAI API key not found")

# Input folder path (location of .sol_analysis.txt files)
input_folder_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/ZKP_LLAMA'))

# Output folder path (to save the filtered results)
output_folder_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/ZKP_LLAMA_filter'))

# Ensure the output folder exists
os.makedirs(output_folder_path, exist_ok=True)


def extract_info_from_gpt(content):
    """Use GPT to extract vulnerability information from contract analysis"""
    prompt = f"""
    The following is a vulnerability analysis of a Solidity contract:

    {content}

    Extract the following information from the above contract analysis:
    1. Vulnerability type and SWC code
    2. Vulnerability description

    Return in the following format:
    Vulnerability type and SWC code: [Vulnerability type and SWC code]
    Vulnerability description: [Description]
    Omit all other information, such as contract identifiers.

    Example:
    Vulnerability type and SWC code: [Reentrancy Vulnerability (SWC: Unknown SWC ID)]
    Vulnerability description: This vulnerability exists in multiple contracts and lacks proper protection against reentrancy attacks.
    This could allow an attacker to exploit reentrancy and disrupt the contract's normal logic and flow.
    The suggested fix is to add the `nonReentrant` modifier and use it in critical functions to ensure they cannot be re-entered, preventing reentrancy attacks.
    """

    max_retries = 3
    retry_delay = 5  # seconds

    for attempt in range(max_retries):
        try:
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a helpful assistant, proficient in analyzing Solidity contract vulnerabilities."},
                    {"role": "user", "content": prompt}
                ],
                timeout=30  # Timeout after 30 seconds
            )
            return response['choices'][0]['message']['content'].strip()
        except Exception as e:
            logging.warning(f"API call failed (Attempt {attempt + 1}/{max_retries}): {str(e)}")
            if attempt < max_retries - 1:
                time.sleep(retry_delay)
                retry_delay *= 2  # Exponential backoff
            else:
                logging.error(f"API call failed multiple times: {str(e)}")
                return f"Information extraction failed: {str(e)}"


def process_contract_files(input_folder_path):
    """Process each .sol_zkp_analysis.txt file in the folder, extract information, and save"""
    # Iterate through each file in the folder
    for filename in os.listdir(input_folder_path):
        if filename.endswith(".sol_analysis.txt"):
            file_path = os.path.join(input_folder_path, filename)
            output_file_path = os.path.join(output_folder_path, filename)

            # If the file already exists, ask if it should be overwritten
            if os.path.exists(output_file_path):
                logging.info(f"File '{filename}' already exists")
                # You can add a user prompt to ask if it should overwrite, or just skip
                continue

            try:
                # Read file content
                with open(file_path, 'r', encoding='utf-8') as file:
                    content = file.read()

                # Extract information
                logging.info(f"Start processing file: {filename}")
                extracted_info = extract_info_from_gpt(content)

                # Save the result
                with open(output_file_path, 'w', encoding='utf-8') as output_file:
                    output_file.write(extracted_info)

                logging.info(f"File '{filename}' processing completed, saved to '{output_file_path}'")

                # Add a delay to avoid API calls being too frequent
                time.sleep(1)

            except Exception as e:
                logging.error(f"Error processing file '{filename}': {str(e)}")


if __name__ == "__main__":
    try:
        process_contract_files(input_folder_path)
        logging.info("All files have been processed")
    except Exception as e:
        logging.critical(f"Program error: {str(e)}", exc_info=True)
