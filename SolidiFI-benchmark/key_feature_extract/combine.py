import os

# Set the source folder path
source_dir = os.path.dirname(__file__)
# Set the path to store merged results
merge_dir = os.path.join(source_dir, '../../result/key_feature_extract/combine')
# Create the target directory if it doesn't exist
if not os.path.exists(merge_dir):
    os.makedirs(merge_dir)

# Define subfolders to be merged
subfolders = ["SWC-101", "SWC-104", "SWC-105", "SWC-107", "SWC-115", "SWC-116", "SWC-136"]

# Get detection results of all .sol files
sol_files = {}

# Iterate through .txt files in each subfolder
for subfolder in subfolders:
    subfolder_path = os.path.join(source_dir, subfolder)
    if os.path.exists(subfolder_path):
        for file_name in os.listdir(subfolder_path):
            if file_name.endswith(".txt"):  # Assume detection result files are .txt
                sol_file_name = file_name.replace(".txt", ".sol")  # Assume matching filenames: .txt files correspond to .sol files
                sol_file_path = os.path.join(subfolder_path, file_name)
                if sol_file_name not in sol_files:
                    sol_files[sol_file_name] = []  # Create an empty list for a new .sol file
                with open(sol_file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    sol_files[sol_file_name].append(content)  # Add the file content to the corresponding .sol entry

# Merge results and save to target folder
for sol_file_name, contents in sol_files.items():
    # Merge file content
    #merged_content = f"Detection results merged - {sol_file_name}\n"
    merged_content = "\n\n".join(contents)  # Merge all content into one string

    # Only generate one merged result file per .sol file
    merged_file_path = os.path.join(merge_dir, sol_file_name + ".txt")

    # If the merged file already exists, delete it first
    if os.path.exists(merged_file_path):
        os.remove(merged_file_path)

    # Write the merged file
    with open(merged_file_path, 'w', encoding='utf-8') as f:
        f.write(merged_content)

print(f"All results have been merged and saved to {merge_dir}")
