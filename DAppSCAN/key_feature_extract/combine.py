import os
import re


def get_file_prefix(file_name, match_pattern=None):
    """
    Extract file prefix, supports multiple matching modes

    Parameters:
        file_name: File name
        match_pattern: Matching pattern, optional values:
                      - 'first_delimiter': Part before the first delimiter
                      - 'numeric_suffix': Part after removing numeric suffix
                      - 'custom_regex': Use custom regular expression
    """
    # Remove file extension first
    base_name = os.path.splitext(file_name)[0]

    if match_pattern == 'numeric_suffix':
        # Match and remove numeric suffix (e.g., file123 -> file, doc45 -> doc)
        return re.sub(r'\d+$', '', base_name)
    elif match_pattern == 'custom_regex':
        # Custom regular expression, extract the first captured group
        # Example here: extract content before the first underscore or dot, can be modified as needed
        match = re.match(r'^([^_.]+)', base_name)
        if match:
            return match.group(1)
        return base_name
    else:  # 'first_delimiter' or others
        # Default: Part before the first delimiter, includes more possible delimiters
        delimiters = re.escape('_.-+#$%&*()[]{}|\\/:;<>?, ')
        match = re.match(f'^([^{delimiters}]+)', base_name)
        if match:
            return match.group(1)
        return base_name


def find_common_prefix(strings):
    """Find the longest common prefix of multiple strings"""
    if not strings:
        return ""
    shortest = min(strings, key=len)
    for i, char in enumerate(shortest):
        for other in strings:
            if other[i] != char:
                return shortest[:i]
    return shortest


# Configuration parameters
MATCH_PATTERN = 'first_delimiter'  # Optional: 'first_delimiter', 'numeric_suffix', 'custom_regex'
MIN_COMMON_LENGTH = 3  # Minimum common prefix length for additional checks
CHECK_COMMON_PREFIX = False  # Whether to check for common prefix

# Set path
source_dir = os.path.dirname(__file__)
# Note: os.path.join may not work as expected with absolute paths, directly use absolute path here
merge_dir = os.path.join(source_dir, '../../result/key_feature_extract/combine')
os.makedirs(merge_dir, exist_ok=True)

subfolders = ["SWC-100","SWC-101","SWC-102","SWC-103","SWC-104","SWC-105","SWC-107","SWC-108","SWC-111","SWC-113",
              "SWC-114","SWC-116","SWC-118","SWC-119","SWC-120","SWC-123","SWC-126","SWC-128","SWC-129"]

# Collect all file information
all_files = []
encodings = ['utf-8', 'gbk', 'latin-1', 'iso-8859-1', 'utf-16', 'cp1252']

print("Collecting all files...")
for subfolder in subfolders:
    # Directly construct subfolder path to avoid potential issues with os.path.join
    subfolder_path = os.path.join(source_dir, f'../../result/key_feature_extract/{subfolder}')
    if not os.path.exists(subfolder_path):
        print(f"Warning: Subfolder does not exist - {subfolder_path}")
        continue

    try:
        for file_name in os.listdir(subfolder_path):
            if file_name.lower().endswith(".txt"):  # Case insensitive check for txt files
                file_path = os.path.join(subfolder_path, file_name)
                if os.path.isfile(file_path):  # Ensure it's a file, not a directory
                    # Extract multiple possible prefixes for debugging
                    prefix1 = get_file_prefix(file_name, 'first_delimiter')
                    prefix2 = get_file_prefix(file_name, 'numeric_suffix')
                    prefix3 = get_file_prefix(file_name, 'custom_regex')

                    all_files.append({
                        'path': file_path,
                        'name': file_name,
                        'prefix1': prefix1,
                        'prefix2': prefix2,
                        'prefix3': prefix3,
                        'content': None
                    })
    except Exception as e:
        print(f"Error processing subfolder {subfolder_path}: {str(e)}")

print(f"Found {len(all_files)} txt files")

# Read file contents
print("Reading file contents...")
for file_info in all_files:
    file_path = file_info['path']
    content = None
    for encoding in encodings:
        try:
            with open(file_path, 'r', encoding=encoding) as f:
                content = f.read()
            break
        except UnicodeDecodeError:
            continue
        except Exception as e:
            print(f"Error reading file {file_path}: {str(e)}")
            break

    if content is None:
        print(f"Warning: Could not read file {file_path} (tried all encodings)")
    else:
        file_info['content'] = content

# Group files by selected pattern
print(f"Grouping files by {MATCH_PATTERN} pattern...")
groups = {}
for file_info in all_files:
    if file_info['content'] is None:
        continue

    # Get prefix based on the selected pattern
    key = file_info['name']

    if key not in groups:
        groups[key] = []
    groups[key].append(file_info)

# If enabled, check and merge groups with sufficiently long common prefixes
if CHECK_COMMON_PREFIX and len(groups) > 1:
    print(f"Checking for common prefix (minimum length: {MIN_COMMON_LENGTH})...")
    group_keys = list(groups.keys())
    merged = set()

    for i in range(len(group_keys)):
        if i in merged:
            continue
        for j in range(i + 1, len(group_keys)):
            if j in merged:
                continue

            common = find_common_prefix([group_keys[i], group_keys[j]])
            if len(common) >= MIN_COMMON_LENGTH:
                # Merge these two groups
                groups[common] = groups.get(common, []) + groups[group_keys[i]] + groups[group_keys[j]]
                del groups[group_keys[i]]
                del groups[group_keys[j]]
                merged.add(i)
                merged.add(j)
                print(f"Merged groups: {group_keys[i]} and {group_keys[j]} -> Common prefix: {common}")
                break

# Merge and save results
print("Merging files...")
for key, files in groups.items():
    if not files:
        continue

    # pure concatenation (no headers), consistent with the other three datasets
    merged_content = "\n\n".join(f['content'] for f in files)
    merged_file_name = key
    merged_file_path = os.path.join(merge_dir, merged_file_name)

    with open(merged_file_path, 'w', encoding='utf-8') as f:
        f.write(merged_content)

    print(f"Generated merged file: {merged_file_name} (contains {len(files)} source files)")

print(f"\nAll operations completed. Merged results saved in: {merge_dir}")
