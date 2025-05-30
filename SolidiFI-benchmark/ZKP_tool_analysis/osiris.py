import os
import subprocess

# Define paths
input_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/SolidiFI-benchmark'))
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/osiris_tool_analysis'))

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)


# Function: fix line endings
def convert_to_unix_line_endings(file_path):
    with open(file_path, "rb") as f:
        content = f.read()
    content = content.replace(b"\r\n", b"\n")  # Replace line endings
    with open(file_path, "wb") as f:
        f.write(content)


# Traverse all .sol files
for file_name in os.listdir(input_dir):
    if file_name.endswith(".sol"):
        input_file_path = os.path.join(input_dir, file_name)
        output_file_path = os.path.join(output_dir, f"{os.path.splitext(file_name)[0]}.txt")

        print(f"Analyzing file: {input_file_path} -> {output_file_path}")

        # Fix line endings
        convert_to_unix_line_endings(input_file_path)

        # Construct Docker command
        command = [
            "docker", "run",
            "-v", f"{input_dir}:/solidity",
            "smartbugs/osiris:d1ecc37",
            "python3", "-m", "osiris.cli", f"/solidity/{file_name}"
        ]

        try:
            # Execute command and save output
            with open(output_file_path, "w") as output_file:
                subprocess.run(command, stdout=output_file, stderr=output_file, text=True)
            print(f"Analysis completed: {file_name}")
        except Exception as e:
            print(f"Analysis failed: {file_name}\nError: {str(e)}")

print(f"All files have been analyzed. Results saved in {output_dir}")
