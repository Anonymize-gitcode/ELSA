import os
import subprocess

# Define input and output folder paths
input_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/smartbugs_curated'))
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/honeybadger_tool_analysis'))

# Ensure the output directory exists
os.makedirs(output_dir, exist_ok=True)

# Iterate over all .sol files in the input directory
for file_name in os.listdir(input_dir):
    if file_name.endswith(".sol"):
        # Full path of the input file
        input_file_path = os.path.join(input_dir, file_name)
        # Output file path
        output_file_path = os.path.join(output_dir, f"{os.path.splitext(file_name)[0]}.txt")

        print(f"Analyzing file: {input_file_path} -> {output_file_path}")

        # Construct the Docker command
        command = [
            "docker", "run",
            "-v", f"{input_dir}:/solidity",
            "smartbugs/honeybadger:ff30c9a",
            "python2", "/root/honeybadger/honeybadger.py",
            f"/solidity/{file_name}"
        ]

        try:
            # Execute the Docker command and write the result to a file
            with open(output_file_path, "w") as output_file:
                subprocess.run(command, stdout=output_file, stderr=output_file, text=True)
            print(f"Analysis complete: {file_name}")
        except Exception as e:
            print(f"Analysis failed: {file_name}\nError: {str(e)}")

print(f"All files have been analyzed. Results are saved in {output_dir}")
