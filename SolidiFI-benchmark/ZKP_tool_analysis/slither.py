import os
import subprocess

def windows_to_wsl_path(windows_path):
    """
    Convert a Windows path to a WSL path.
    """
    wsl_path = windows_path.replace("\\", "/").replace(":", "").lower()
    return f"/mnt/{wsl_path}"

def analyze_sol_files(input_folder, output_folder):
    """
    Traverse all .sol files under input_folder, analyze them using Slither, and store results in output_folder.
    """
    # Ensure the output directory exists
    os.makedirs(output_folder, exist_ok=True)

    # Traverse all .sol files
    for root, _, files in os.walk(input_folder):
        for file in files:
            if file.endswith(".sol"):
                # Get the full file path
                sol_file_path = os.path.join(root, file)
                # Convert to WSL path
                sol_file_path_wsl = windows_to_wsl_path(sol_file_path)
                # Output result path
                output_file_path = os.path.join(output_folder, f"{file}.txt")

                command = ["wsl", "slither", sol_file_path_wsl]
                try:
                    # Capture stdout and stderr, handle encoding issues
                    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, encoding='utf-8', errors='replace')

                    # Write stdout and stderr to the output file
                    with open(output_file_path, "w", encoding="utf-8") as output_file:
                        output_file.write("STDOUT:\n")
                        output_file.write(result.stdout if result.stdout else "No stdout output\n")
                        output_file.write("\nSTDERR:\n")
                        output_file.write(result.stderr if result.stderr else "No stderr output\n")

                    print(f"Analysis completed: {sol_file_path} -> {output_file_path}")

                except subprocess.CalledProcessError as e:
                    print(f"Analysis failed: {sol_file_path}\nError message: {e.stderr}")

if __name__ == "__main__":
    # Input and output paths
    input_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/SolidiFI-benchmark'))
    output_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/slither_tool_analysis'))

    # Check if the input folder exists
    if not os.path.exists(input_folder):
        print(f"Input folder does not exist: {input_folder}")
    else:
        # Execute batch analysis
        analyze_sol_files(input_folder, output_folder)
