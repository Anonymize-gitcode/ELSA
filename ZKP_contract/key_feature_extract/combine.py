import os

# Set the source folder path
source_dir = os.path.dirname(__file__)
# Set the path to store the merge results
merge_dir = os.path.join(source_dir, '../../result/key_feature_extract/combine')
# Create the target directory if it does not exist
if not os.path.exists(merge_dir):
    os.makedirs(merge_dir)

# Define the subfolders to be merged
subfolders = ["SWC-101", "SWC-105", "SWC-107", "SWC-110", "SWC-121", "SWC-124", "SWC-128"]

# Get detection results of all .sol files
sol_files = {}
encodings = ['gbk', 'latin-1', 'iso-8859-1']

for subfolder in subfolders:
    subfolder_path = os.path.join(source_dir, f'../../result/key_feature_extract/{subfolder}')
    if os.path.exists(subfolder_path):
        for file_name in os.listdir(subfolder_path):
            if file_name.endswith(".txt"):  # Assuming detection result files are .txt
                sol_file_name = file_name.replace(".txt", ".txt")  # Assuming filenames match, .txt corresponds to .sol
                sol_file_path = os.path.join(subfolder_path, file_name)

                if sol_file_name not in sol_files:
                    sol_files[sol_file_name] = []  # Create an empty list for a new .sol file

                content = None
                for encoding in encodings:  # Try multiple encodings
                    try:
                        with open(sol_file_path, 'r', encoding=encoding, errors='ignore') as f:
                            content = f.read()
                        break  # Stop trying encodings once successful
                    except UnicodeDecodeError:
                        continue  # Try the next encoding if the current one fails

                if content is not None:
                    sol_files[sol_file_name].append(content)  # Add file content to the corresponding .sol file
                else:
                    print(f"Unable to read file: {sol_file_path}, please check encoding format")

# Merge results and save to the target folder
for sol_file_name, contents in sol_files.items():
    # Merge file contents
    #merged_content = f"Merged detection result - {sol_file_name}\n"
    merged_content = "\n\n".join(contents)  # Merge all contents into one string

    # Only generate one merged result file for each .sol file
    merged_file_path = os.path.join(merge_dir, sol_file_name + ".txt")

    # If the merged file already exists, delete it first then create a new one
    if os.path.exists(merged_file_path):
        os.remove(merged_file_path)

    # Write to the merged file
    with open(merged_file_path, 'w', encoding='utf-8') as f:
        f.write(merged_content)

print(f"All results have been merged and saved to {merge_dir}")
