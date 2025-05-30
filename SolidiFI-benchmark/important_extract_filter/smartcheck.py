import os
import re

# Input and output directories
input_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/smartcheck_tool_analysis'))
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/smartcheck_tool_analysis_filter'))

# Regular expressions to filter out unwanted information
exclude_patterns = [
    r"mismatched input.*",  # Remove lines containing 'mismatched input'
    r"extraneous input.*expecting",  # Remove lines containing 'extraneous input'
    r"jar:",  # Remove lines containing 'jar:'
    r"content:",  # Remove lines containing 'content:'
    r"missing ';'"  # Remove lines containing 'missing ';''
]

# Ensure the output directory exists
os.makedirs(output_dir, exist_ok=True)

# Get all files
for filename in os.listdir(input_dir):
    if filename.endswith(".txt"):
        input_file_path = os.path.join(input_dir, filename)

        # Modify output file path to ensure the filename ends with .sol.txt
        output_filename = filename.replace(".txt", ".sol.txt")
        output_file_path = os.path.join(output_dir, output_filename)

        try:
            with open(input_file_path, "r", encoding="utf-8-sig") as file:
                lines = file.readlines()

            if not lines:
                print(f"Skipping empty file: {filename}")
                continue  # Skip empty file

            # Remove the first line
            lines = lines[1:]

            # Used to store filtered lines
            filtered_lines = []

            # Process line by line
            for line in lines:
                # Check if line matches any exclusion pattern (e.g., compile errors)
                if not any(re.search(pattern, line) for pattern in exclude_patterns):
                    filtered_lines.append(line)
                else:
                    print(f"Skipping this line in file {filename}: {line.strip()}")

            # Notify if there's no valid content after filtering
            if not filtered_lines:
                print(f"Warning: No valid content after filtering file {filename}.")

            # Write the filtered result to a new file
            with open(output_file_path, "w", encoding="utf-8-sig") as output_file:
                output_file.writelines(filtered_lines)

            print(f"Filtered content written to: {output_file_path}")

        except Exception as e:
            print(f"Error processing file {filename}: {e}")

print("Filtering complete.")
