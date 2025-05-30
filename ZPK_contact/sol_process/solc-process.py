import os
import openai

openai.api_key = ('...')  # Replace with your GPT API key

MAX_TOKENS = 4096  # Limit the maximum length of each chunk to 4096 tokens (a safer value)
OUTPUT_DIRECTORY = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/solc-process'))


def split_content(content, max_tokens=MAX_TOKENS):
    """
    Split the content into smaller chunks to fit the model's context length limit.
    Estimate the number of tokens roughly by character count and ensure each chunk does not exceed max_tokens.
    """
    words = content.split()  # Split content into a list of words by spaces
    chunks = []
    current_chunk = []

    current_length = 0

    for word in words:
        # Estimate tokens (average 1.33 tokens per word) and ensure not exceeding max_tokens
        current_length += len(word) / 1.33
        if current_length > max_tokens:
            chunks.append(' '.join(current_chunk))
            current_chunk = [word]
            current_length = len(word) / 1.33
        else:
            current_chunk.append(word)

    # Final chunk
    if current_chunk:
        chunks.append(' '.join(current_chunk))

    return chunks


def summarize_content(content):
    """
    Use GPT to condense file content while retaining important parts.
    """
    try:
        # Call OpenAI's chat API to condense the content
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",  # Or use "gpt-4"
            messages=[
                {"role": "system", "content": "You are an expert in smart contract code distillation, focused on extracting the most critical information from the code to guide GPT."},
                {"role": "user",
                 "content": f"Please summarize the following smart contract code content, keeping key functions, variable definitions, and important logic structures to guide GPT."
                            f"Summarize according to contract definition (contract name, function [visibility, mutability, parameters]) and logical structure:"
                            f"Sample template: Key function and variable definitions:"
                            f"- **Contract Definition**:"
                            f"  - Contract Name: CALLER"
                            f"  - Function: CALLADDRESS"
                            f"      - Visibility: PUBLIC"
                            f"      - Mutability: NONPAYABLE"
                            f"      - Parameters: A (type ADDRESS)"
                            f"- **Logical Structure**:"
                            f"  - The contract definition includes a function named CALLADDRESS, which has public visibility and is nonpayable. The function has one parameter A of type ADDRESS."
                            f"  - The function contains an expression statement that calls the CALL function to access address A."
                            f"\n\n{content}"}
            ],
            temperature=0.5,
            max_tokens=1024,  # Adjust as needed for generation
            top_p=1.0,
            frequency_penalty=0.0,
            presence_penalty=0.0
        )
        return response['choices'][0]['message']['content']
    except Exception as e:
        print(f"Error calling OpenAI API: {e}")
        return None


def process_txt_file(file_path, output_directory):
    """
    Process a single txt file, compress content using GPT, and save the result to the specified directory.
    Skip if the file has already been processed.
    """
    # Generate output file path
    output_file_name = os.path.basename(file_path).replace('.txt', '_compressed.txt')
    new_file_path = os.path.join(output_directory, output_file_name)

    # Skip processing if file already exists in output directory
    if os.path.exists(new_file_path):
        print(f"File already exists, skipping: {new_file_path}")
        return

    print(f"Processing file: {file_path}")

    try:
        # Read file content
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Split content into chunks that fit the model's max context length
        content_chunks = split_content(content)
        compressed_chunks = []

        # Compress each chunk
        for chunk in content_chunks:
            compressed_chunk = summarize_content(chunk)
            if compressed_chunk:
                compressed_chunks.append(compressed_chunk)

        if compressed_chunks:
            # Combine all compressed chunks together
            compressed_content = '\n\n'.join(compressed_chunks)

            # Check if output directory exists, create if not
            if not os.path.exists(output_directory):
                os.makedirs(output_directory)

            # Save compressed content to new file
            with open(new_file_path, 'w', encoding='utf-8') as new_file:
                new_file.write(compressed_content)
            print(f"File compression completed: {new_file_path}")
        else:
            print(f"File compression failed: {file_path}")

    except Exception as e:
        print(f"Error reading or processing file: {file_path}, error: {e}")


def process_directory(directory, output_directory):
    """
    Traverse the specified directory, process each txt file, and save the compressed results to a new output directory.
    Skip files that are already processed.
    """
    print(f"Start processing directory: {directory}")
    if not os.path.exists(directory):
        print(f"Directory not found: {directory}")
        return

    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.txt'):
                file_path = os.path.join(root, file)
                process_txt_file(file_path, output_directory)

    print("All files processed.")


if __name__ == "__main__":
    # Set the path of the directory to process and the output directory
    txt_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/solc-analysis'))

    # Call the function to start processing and save to new directory
    process_directory(txt_directory, OUTPUT_DIRECTORY)
