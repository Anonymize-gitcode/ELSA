import os
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed


def windows_to_wsl_path(windows_path):
    """
    Convert Windows path to WSL path
    """
    wsl_path = windows_path.replace("\\", "/").replace(":", "").lower()
    return f"/mnt/{wsl_path}"


def analyze_sol_file(sol_file_path, output_file_path):
    """
    Use Mythril to analyze a single .sol file and store the result to the specified path.
    """
    # Convert to WSL path
    sol_file_path_wsl = windows_to_wsl_path(sol_file_path)

    # Construct Mythril command
    command = [
        "wsl", "~/.local/bin/myth", "analyze", sol_file_path_wsl
    ]

    try:
        # Execute command and capture stdout and stderr
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        # Write result to file
        with open(output_file_path, "w") as output_file:
            output_file.write(result.stdout)
            output_file.write(result.stderr)
        print(f"Analysis completed: {sol_file_path} -> {output_file_path}")
    except subprocess.CalledProcessError as e:
        print(f"Analysis failed: {sol_file_path}\nError message: {e.stderr}")


def analyze_sol_files_with_mythril(input_folder, output_folder, max_workers=4):
    """
    Traverse all .sol files under input_folder, analyze with Mythril, and store results to output_folder.
    Supports multithreading.
    """
    # Ensure output directory exists
    os.makedirs(output_folder, exist_ok=True)

    # Create a thread pool
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = []
        for root, _, files in os.walk(input_folder):
            for file in files:
                if file.endswith(".sol"):
                    # Get full file path
                    sol_file_path = os.path.join(root, file)
                    # Output result path
                    output_file_path = os.path.join(output_folder, f"{file}.txt")

                    # Check if result file already exists
                    if os.path.exists(output_file_path):
                        print(f"Analysis result already exists, skipping: {output_file_path}")
                        continue

                    # Submit analysis task
                    futures.append(executor.submit(analyze_sol_file, sol_file_path, output_file_path))

        # Wait for all tasks to complete
        for future in as_completed(futures):
            # Catch possible exceptions
            try:
                future.result()
            except Exception as e:
                print(f"Error occurred during task execution: {e}")


if __name__ == "__main__":
    # Input and output paths
    input_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/smartbugs_curated'))
    output_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/mythril_tool_analysis'))

    # Check if input folder exists
    if not os.path.exists(input_folder):
        print(f"Input folder does not exist: {input_folder}")
    else:
        # Execute batch analysis with specified thread count
        analyze_sol_files_with_mythril(input_folder, output_folder, max_workers=16)
