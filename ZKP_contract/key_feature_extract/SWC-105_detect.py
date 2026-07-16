import os
import re

# Define sensitive operations
sensitive_operations = [
    'setAdmin', 'transferOwnership', 'withdraw', 'destroyContract', 'mintTokens',
    'sensitiveAction', 'updateSensitiveValue', 'releaseFunds', 'payout', 'upgradeContract',
    'setPaused', 'setUnpaused', 'setStakingLimit', 'mint', 'burn', 'approve', 'transferFrom',
    'addMinter', 'removeMinter', 'increaseAllowance', 'decreaseAllowance'
]

# Define sensitive variables
sensitive_variables = ['admin', 'owner', 'contractAddress', 'balance', 'funds', 'userFunds', 'pendingRewards', 'totalSupply', 'contractUpgrader', 'pauseState', 'stakingBalance', 'minters']

# Enhanced regex for permission checks
permission_check_pattern = r'(require|assert|modifier|onlyOwner|onlyAdmin|hasRole|onlySelf|isAuthorized|onlyAuthorizedAddress|checkPermissions|restrictAccess|onlyGovernance|onlyMinter|onlyBurner|onlyUpgrader)\([^\)]*(msg\.sender|admin|owner|contractAddress|msg\.value|tx\.origin|address\([^\)]*\))[^\)]*\)'

# Check function permission control
def detect_vulnerabilities(file_path):
    detected_vulnerabilities = []

    with open(file_path, 'r', encoding='utf-8') as file:
        code = file.read()

    # Check if sensitive functions lack permission checks
    for function in sensitive_operations:
        function_pattern = rf'function\s+{function}\s*\([^)]*\)\s*\{{(.*?)\}}'
        matches = re.findall(function_pattern, code, re.DOTALL)

        for match in matches:
            # Flag as vulnerability if no permission check
            if not re.search(permission_check_pattern, match):
                start_line = code.count('\n', 0, code.find(match)) + 1
                detected_vulnerabilities.append({
                    'name': f'NoPermissionCheckIn{function}',
                    'swc_id': 'SWC-105',
                    'line': start_line,
                    'relevant_code': match.strip(),
                    'description': f'Missing permission check in function {function}'
                })

    # Check if modifiers lack permission control
    for modifier_match in re.findall(r'modifier\s+[^\(]+\([^)]*\)\s*\{(.*?)\}', code, re.DOTALL):
        if not re.search(permission_check_pattern, modifier_match):
            start_line = code.count('\n', 0, code.find(modifier_match)) + 1
            detected_vulnerabilities.append({
                'name': 'NoPermissionCheckInModifier',
                'swc_id': 'SWC-105',
                'line': start_line,
                'relevant_code': modifier_match.strip(),
                'description': 'Missing permission check in modifier'
            })

    # Check conditions inside require statements
    require_pattern = r'require\s*\(([^)]+)\);'
    for match in re.findall(require_pattern, code):
        # Parse the condition in require
        if not re.search(permission_check_pattern, match):
            start_line = code.count('\n', 0, code.find(match)) + 1
            detected_vulnerabilities.append({
                'name': 'RequireWithoutPermissionCheck',
                'swc_id': 'SWC-105',
                'line': start_line,
                'relevant_code': match.strip(),
                'description': 'Require statement without permission check'
            })

    # Check if sensitive variables are modified without permission check
    for sensitive_var in sensitive_variables:
        var_pattern = rf'{sensitive_var}\s*=\s*[^;]*;'
        matches = re.findall(var_pattern, code)
        for match in matches:
            start_line = code.count('\n', 0, code.find(match)) + 1
            detected_vulnerabilities.append({
                'name': f'NoPermissionCheckFor{sensitive_var.capitalize()}Modification',
                'swc_id': 'SWC-105',
                'line': start_line,
                'relevant_code': match.strip(),
                'description': f'Modification of variable {sensitive_var} lacks permission check'
            })

    # Check external contract calls for permission control
    external_call_pattern = r'\s*(call|delegatecall|staticcall|send)\s*\([^\)]*\)\s*;'
    for call_match in re.findall(external_call_pattern, code, re.DOTALL):
        if not re.search(permission_check_pattern, call_match):
            start_line = code.count('\n', 0, code.find(call_match)) + 1
            detected_vulnerabilities.append({
                'name': 'NoPermissionCheckForExternalCall',
                'swc_id': 'SWC-105',
                'line': start_line,
                'relevant_code': call_match.strip(),
                'description': 'External contract call without permission check'
            })

    # Check for tx.origin misuse
    tx_origin_pattern = r'tx\.origin'
    for match in re.findall(tx_origin_pattern, code):
        start_line = code.count('\n', 0, code.find(match)) + 1
        detected_vulnerabilities.append({
            'name': 'TxOriginMisuse',
            'swc_id': 'SWC-105',
            'line': start_line,
            'relevant_code': match.strip(),
            'description': 'Misuse of tx.origin, consider using msg.sender instead'
        })

    # Check permission on state variable modifications
    state_variable_pattern = r'\s*(address|uint256|bool)\s+[a-zA-Z0-9_]+\s*='
    for state_var_match in re.findall(state_variable_pattern, code):
        if not re.search(permission_check_pattern, state_var_match):
            start_line = code.count('\n', 0, code.find(state_var_match)) + 1
            detected_vulnerabilities.append({
                'name': 'StateVariableModificationWithoutPermissionCheck',
                'swc_id': 'SWC-105',
                'line': start_line,
                'relevant_code': state_var_match.strip(),
                'description': 'State variable modification lacks permission check'
            })

    return detected_vulnerabilities

# Process all Solidity files in the directory
def process_solidity_files(directory_path):
    results = {}
    detected_files_count = 0

    for filename in os.listdir(directory_path):
        if filename.endswith('.sol'):
            file_path = os.path.join(directory_path, filename)
            detected_vulnerabilities = detect_vulnerabilities(file_path)
            if detected_vulnerabilities:
                results[filename] = detected_vulnerabilities
                detected_files_count += 1
            else:
                results[filename] = None

    return results, detected_files_count

# Save detection results
def save_results(results, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for filename, vulnerabilities in results.items():
        output_file_path = os.path.join(output_dir, f'{filename}.txt')
        with open(output_file_path, 'w', encoding='utf-8') as output_file:
            if vulnerabilities:
                for vulnerability in vulnerabilities:
                    output_file.write(f"Potential vulnerability type ({vulnerability['swc_id']}): {vulnerability['name']} - {vulnerability['description']}\n")
                    output_file.write(f"Line: {vulnerability['line']}\n")
                    output_file.write(f"Relevant code: {vulnerability['relevant_code']}\n")
                    output_file.write('-' * 50 + '\n')
            else:
                output_file.write('No SWC-105 related vulnerabilities detected\n')

# Execute detection and save results
directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/ZKP_contract'))  # Set the path to your Solidity files
output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-105')) # Set the output path
results, detected_files_count = process_solidity_files(directory_path)
save_results(results, output_dir)

# Print number of files with vulnerabilities detected
print(f"A total of {detected_files_count} files were found to contain SWC-105 related vulnerabilities.")
