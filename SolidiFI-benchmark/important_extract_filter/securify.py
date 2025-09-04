import os
import re
import chardet

# Input and output directories
input_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/securify_tool_analysis'))
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/securify_tool_analysis_filter'))
# Create output directory
os.makedirs(output_dir, exist_ok=True)


def process_line(line):
    """
    Process each line:
    1. Replace file path with 'line + line number'
    2. Remove content inside single quotes
    3. Delete lines that start with 'Reference:'
    4. Remove redundant info but keep useful lines with '-' prefix
    """

    # Remove unused code hints
    if "Setting it up" in line:
        return None

    if "标准输出:" in line:  # "Standard Output:"
        return None

    if "File" in line:
        return None
    if "Traceback" in line:
        return None
    if "错误输出" in line:  # "Error Output"
        return None

    # Replace file path and line number, e.g. ../../file.sol#123 -> line 123
    line = re.sub(r"[a-zA-Z0-9_./\\:-]+\.(sol)#(\d+)", r"line \2", line)

    # Remove content inside single quotes
    line = re.sub(r"'[^']*'", "", line)

    if line.strip() == "running":
        return None
    return line.strip()


def process_content(content):
    """
    Process file content line by line using process_line
    """
    lines = content.splitlines()
    processed_lines = [process_line(line) for line in lines if process_line(line) is not None]
    return "\n".join(processed_lines)


def get_file_encoding(file_path):
    """
    Detect file encoding
    """
    with open(file_path, "rb") as file:
        raw_data = file.read(10000)  # Read the first 10,000 bytes
        result = chardet.detect(raw_data)
        return result['encoding']


# Traverse files
for filename in os.listdir(input_dir):
    input_file_path = os.path.join(input_dir, filename)
    output_file_path = os.path.join(output_dir, filename)

    if filename.endswith(".txt"):
        try:
            # Detect file encoding
            encoding = get_file_encoding(input_file_path)
            # Read file using detected encoding
            with open(input_file_path, "r", encoding=encoding) as infile:
                content = infile.read()

            # Process content
            processed_content = process_content(content)

            # Write result
            with open(output_file_path, "w", encoding="utf-8") as outfile:
                outfile.write(processed_content)

            print(f"Processed file {filename} successfully. Result saved to: {output_file_path}")

        except UnicodeDecodeError as e:
            print(f"Failed to read file {filename}: {e}")
        except Exception as e:
            print(f"Error occurred while processing file {filename}: {e}")

print("All files processed!")
