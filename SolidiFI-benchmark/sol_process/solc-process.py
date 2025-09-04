import os
import openai

openai.api_key = ('...')  # Replace with your GPT API key

MAX_TOKENS = 4096  # Limit max length of each chunk to 4096 tokens (safer value)
OUTPUT_DIRECTORY = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/solc-process'))  # Target output directory


def split_content(content, max_tokens=MAX_TOKENS):
    """
    Split content into smaller chunks to fit within the model's context length.
    Estimate token count based on word count (characters) and ensure each chunk doesn't exceed max_tokens.
    """
    words = content.split()  # Split content into word list using space
    chunks = []
    current_chunk = []

    current_length = 0

    for word in words:
        # Estimate tokens per word (average 1.33 tokens per word), ensure it does not exceed max_tokens
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
    Use GPT to compress file content, keeping only important parts.
    """
    try:
        # Call OpenAI's chat API to compress content
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",  # Or use "gpt-4"
            messages=[
                {"role": "system", "content": "You are an expert in smart contract code distillation, focusing on summarizing the most critical information to inspire GPT."},
                {"role": "user",
                 "content": f"Please summarize the following contract code content, preserving key functions, variable definitions, and important logic structures to inspire GPT. "
                            f"Extract important information by contract definition (contract name, functions [visibility, mutability, parameters]) and logic structure:\n"
                            f"Sample template:\nKey functions and variable definitions:\n"
                            f"- **Contract Definition**:\n"
                            f"  - Contract Name: CALLER\n"
                            f"  - Function: CALLADDRESS\n"
                            f"      - Visibility: PUBLIC\n"
                            f"      - State Mutability: NONPAYABLE\n"
                            f"      - Parameters: A (Type ADDRESS)\n"
                            f"- **Logic Structure**:\n"
                            f"  - The contract defines a function called CALLADDRESS, which has public visibility and non-payable mutability. The function takes a parameter A of type ADDRESS.\n"
                            f"  - Inside the function is an expression statement that calls the CALL function to access address A.\n"
                            f"\n\n{content}"}
            ],
            temperature=0.5,
            max_tokens=1024,  # Adjust max tokens generated as needed
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
    Process a single txt file, compress the content using GPT, and save the result to the specified directory.
    Skip if file has already been processed.
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

        # Split content into chunks to fit model's max context length
        content_chunks = split_content(content)
        compressed_chunks = []

        # Compress each chunk
        for chunk in content_chunks:
            compressed_chunk = summarize_content(chunk)
            if compressed_chunk:
                compressed_chunks.append(compressed_chunk)

        if compressed_chunks:
            # Combine all compressed chunks
            compressed_content = '\n\n'.join(compressed_chunks)

            # Ensure output directory exists, create if not
            if not os.path.exists(output_directory):
                os.makedirs(output_directory)

            # Save compressed content to new file
            with open(new_file_path, 'w', encoding='utf-8') as new_file:
                new_file.write(compressed_content)
            print(f"File compression complete: {new_file_path}")
        else:
            print(f"File compression failed: {file_path}")

    except Exception as e:
        print(f"Error reading or processing file: {file_path}, Error: {e}")


def process_directory(directory, output_directory):
    """
    Traverse the specified directory, process each txt file, and save compressed results to new output directory.
    Skip if file already processed.
    """
    print(f"Starting to process directory: {directory}")
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

    # Call function to start processing and save to new directory
    process_directory(txt_directory, OUTPUT_DIRECTORY)
