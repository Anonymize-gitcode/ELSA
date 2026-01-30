import os
import re

# Input and output directories
input_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/honeybadger_tool_analysis'))
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/honeybadger_tool_analysis_filter'))

# Create output directory
os.makedirs(output_dir, exist_ok=True)


def process_line(line):
    """
    Process each line:
    1. Replace path with line + line number
    2. Remove content inside single quotes
    3. Remove entire line starting with Reference:
    4. Remove redundant information but keep useful lines prefixed with '-'
    """

    # Remove unused code hints
    if "root:Contract " in line:
        return None

    if "Running, please wait" in line:
        return None

    if "An analysis technique" in line:
        return None

    # Replace path and line number, e.g., ../../file.sol#123 -> line 123
    line = re.sub(r"[a-zA-Z0-9_./\\:-]+\.(sol)#(\d+)", r"line \2", line)

    # Remove content inside single quotes
    line = re.sub(r"'[^']*'", "", line)

    if line.strip() == "running":
        return None
    return line.strip()


def process_content(content):
    """
    Process file content, apply process_line to each line
    """
    lines = content.splitlines()
    processed_lines = [process_line(line) for line in lines if process_line(line) is not None]
    return "\n".join(processed_lines)


# Traverse files
for filename in os.listdir(input_dir):
    input_file_path = os.path.join(input_dir, filename)
    output_file_path = os.path.join(output_dir, filename)

    if filename.endswith(".txt"):
        with open(input_file_path, "r", encoding="utf-8") as infile:
            content = infile.read()

        # Process content
        processed_content = process_content(content)

        # Write result
        with open(output_file_path, "w", encoding="utf-8") as outfile:
            outfile.write(processed_content)

print("File processing complete, results saved to:", output_dir)
