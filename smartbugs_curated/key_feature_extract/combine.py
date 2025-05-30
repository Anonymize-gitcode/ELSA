import os

# Set the source folder path
source_dir = os.path.dirname(__file__)
# Set the path to store the merged results
merge_dir = os.path.join(source_dir, '../../result/key_feature_extract/combine')
# Create the target directory (if it doesn't exist)
if not os.path.exists(merge_dir):
    os.makedirs(merge_dir)

# Define the subfolders to be merged
subfolders = ["SWC-100", "SWC-101", "SWC-102", "SWC-103", "SWC-104", "SWC-105", "SWC-106", "SWC-107", "SWC-108", "SWC-109" ]

# Get detection results of all .sol files
sol_files = {}

# Traverse the .txt files in each subfolder
for subfolder in subfolders:
    subfolder_path = os.path.join(source_dir, subfolder)
    if os.path.exists(subfolder_path):
        for file_name in os.listdir(subfolder_path):
            if file_name.endswith(".txt"):  # Assume the detection result files are .txt files
                sol_file_name = file_name.replace(".txt", ".txt")  # Assume file names match: .txt files correspond to .sol files
                sol_file_path = os.path.join(subfolder_path, file_name)
                if sol_file_name not in sol_files:
                    sol_files[sol_file_name] = []  # Create an empty list for a new sol file
                with open(sol_file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    sol_files[sol_file_name].append(content)  # Add the file content to the corresponding sol file content

# Merge the results and save them to the target folder
for sol_file_name, contents in sol_files.items():
    # Merge file contents
    # merged_content = f"Detection results merged - {sol_file_name}\n"
    merged_content = "\n\n".join(contents)  # Merge all contents into a single string

    # Only generate one merged result file per sol file
    merged_file_path = os.path.join(merge_dir, sol_file_name + ".txt")

    # If the merged file already exists, delete it before creating a new one
    if os.path.exists(merged_file_path):
        os.remove(merged_file_path)

    # Write the merged content into the file
    with open(merged_file_path, 'w', encoding='utf-8') as f:
        f.write(merged_content)

print(f"All results have been merged and saved to {merge_dir}")
