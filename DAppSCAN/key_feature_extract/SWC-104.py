import os
import re
from packaging import version
from packaging.specifiers import SpecifierSet, InvalidSpecifier


def extract_pragma_directives(solidity_code):
    """Extract and clean all pragma solidity declarations, excluding comments and string interference"""
    # Process in steps to avoid parsing errors caused by complex regular expressions
    code = solidity_code

    # 1. Remove multi-line comments
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)

    # 2. Remove single-line comments (but retain comments before the pragma declaration)
    lines = []
    for line in code.split('\n'):
        comment_pos = line.find('//')
        if comment_pos != -1 and 'pragma solidity' in line[:comment_pos]:
            lines.append(line[:comment_pos])  # Retain pragma part
        elif 'pragma solidity' in line:
            lines.append(line)
    code = '\n'.join(lines)

    # 3. Remove strings
    code = re.sub(r'"(?:\\.|[^"\\])*"', '', code)
    code = re.sub(r"'(?:\\.|[^'\\])*'", '', code)

    # 4. Extract pragma declarations
    pragma_pattern = r'pragma\s+solidity\s+([^;]+);'
    matches = re.findall(pragma_pattern, code)

    # Clean spaces and unnecessary characters
    return [re.sub(r'\s+', '', match) for match in matches if match.strip()]


def get_security_baseline():
    """Security baseline version: 0.8.0 and above includes built-in overflow checks"""
    return version.parse("0.8.0")


def get_safe_versions_whitelist():
    """Known safe versions whitelist (including old versions with patch fixes)"""
    return {
        # 0.8.x series are safe by default
        "0.8.0", "0.8.1", "0.8.2", "0.8.3", "0.8.4", "0.8.5", "0.8.6",
        "0.8.7", "0.8.8", "0.8.9", "0.8.10", "0.8.11", "0.8.12", "0.8.13",
        "0.8.14", "0.8.15", "0.8.16", "0.8.17", "0.8.18", "0.8.19", "0.8.20",

        # Safe patch versions in old releases
        "0.7.6-patch3",  # 0.7.6 patch that fixed specific overflow issues
        "0.6.12-patch2"  # 0.6.12 patch that fixed reentrancy vulnerabilities
    }


def get_unsafe_versions():
    """Versions with known unresolved vulnerabilities (not including patch versions)"""
    return {
        # 0.7.x series (no built-in overflow checks, and no patches)
        "0.7.0", "0.7.1", "0.7.2", "0.7.3", "0.7.4", "0.7.5", "0.7.6",

        # 0.6.x series
        "0.6.0", "0.6.1", "0.6.2", "0.6.3", "0.6.4", "0.6.5", "0.6.6",
        "0.6.7", "0.6.8", "0.6.9", "0.6.10", "0.6.11", "0.6.12",

        # Older versions
        "0.5.0", "0.4.26", "0.3.6"
    }


def parse_complex_version_spec(spec):
    """Parse complex version ranges with logical operators (e.g. ^0.8.0 || >=0.7.6 <0.8.0)"""
    # Split logical OR conditions
    or_parts = re.split(r'\|\|', spec)
    valid_specs = []

    for part in or_parts:
        part = part.strip()
        if not part:
            continue

        # Handle logical AND conditions (implicitly within ranges)
        try:
            # Use packaging library's SpecifierSet to parse standard ranges
            spec_set = SpecifierSet(part)
            valid_specs.append(spec_set)
        except InvalidSpecifier:
            # Handle special symbols (like ^ and ~) with compatible conversion
            converted = convert_special_symbols(part)
            try:
                spec_set = SpecifierSet(converted)
                valid_specs.append(spec_set)
            except InvalidSpecifier:
                continue  # Invalid range is ignored

    return valid_specs


def convert_special_symbols(spec):
    """Convert ^ and ~ symbols to standard range representations"""
    if spec.startswith('^'):
        base = spec[1:]
        if '.' in base:
            parts = base.split('.')
            if len(parts) >= 2:
                # ^0.8.0 → >=0.8.0, <0.9.0
                return f">={base}, <{parts[0]}.{int(parts[1]) + 1}.0"
    elif spec.startswith('~'):
        base = spec[1:]
        if '.' in base:
            parts = base.split('.')
            if len(parts) >= 3:
                # ~0.8.5 → >=0.8.5, <0.8.6
                return f">={base}, <{parts[0]}.{parts[1]}.{int(parts[2]) + 1}"
    return spec


def is_test_contract(file_path):
    """Determine if the contract is a test contract (relaxed check)"""
    filename = os.path.basename(file_path).lower()
    return any(keyword in filename for keyword in ['test', 'mock', 'tester', 'example'])


def analyze_version_risk(specs, file_path):
    """Analyze the risk level of version ranges, reducing false positives"""
    if not specs:
        return "High", "No explicit compiler version specified (may use outdated version)"

    safe_whitelist = get_safe_versions_whitelist()
    unsafe_versions = get_unsafe_versions()
    baseline = get_security_baseline()
    is_test = is_test_contract(file_path)

    # Check if any safe version ranges are included
    has_safe_range = False
    # Check if any unsafe version ranges are included
    has_unsafe_range = False
    # Record specific risk reasons
    risk_details = []

    for spec_set in specs:
        # Check if any safe versions from the whitelist are included
        for safe_ver in safe_whitelist:
            if version.parse(safe_ver) in spec_set:
                has_safe_range = True
                break

        # Check if any unsafe versions are included
        for unsafe_ver in unsafe_versions:
            if version.parse(unsafe_ver) in spec_set:
                has_unsafe_range = True
                risk_details.append(f"includes known unsafe version {unsafe_ver}")
                break

        # Check if the version is below the security baseline (0.8.0) and not in the whitelist
        if any(ver < baseline for ver in [
            version.parse(spec.operator + spec.version)
            for spec in spec_set if spec.operator in ['<=', '<']
        ]):
            if not any(version.parse(safe_ver) in spec_set for safe_ver in safe_whitelist):
                has_unsafe_range = True
                risk_details.append("includes versions below security baseline (0.8.0) without safety patches")

    # Risk determination logic (priority: unsafe range > mixed range > safe range)
    if has_unsafe_range:
        # Test contracts lower the risk level
        risk_level = "Medium" if is_test else "High"
        return risk_level, "; ".join(risk_details) if risk_details else "Includes unsafe compiler versions"
    elif has_safe_range:
        return "Low", "Version range includes safe compiler versions"
    else:
        # Neither safe nor unsafe versions are included (typically unrecognized new versions)
        return "Medium", "Unrecognized version range (risk unknown)"


def get_pragma_line_numbers(solidity_code, specs):
    """Get the line numbers for each pragma declaration in the code (for reporting)"""
    line_numbers = []
    code_lines = solidity_code.split('\n')

    for spec in specs:
        for line_num, line in enumerate(code_lines, 1):
            # Loosely match, allowing for space differences
            clean_line = re.sub(r'\s+', '', line).lower()
            clean_spec = re.sub(r'\s+', '', spec).lower()
            if f"pragmasolidity{clean_spec};" in clean_line:
                line_numbers.append(line_num)
                break  # Exit the current loop after finding

    return line_numbers


def detect_swc104(file_path):
    """Optimized SWC-104 detection logic"""
    vulnerabilities = []

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_code = f.read()

        # Extract pragma declarations
        pragma_specs = extract_pragma_directives(original_code)
        # Parse version ranges
        parsed_specs = parse_complex_version_spec('||'.join(pragma_specs)) if pragma_specs else []
        # Analyze risks
        risk_level, description = analyze_version_risk(parsed_specs, file_path)

        if risk_level in ["High", "Medium"]:
            # Get line numbers
            line_numbers = get_pragma_line_numbers(original_code, pragma_specs) or [1]

            # Build report content
            code_snippet = f"pragma solidity {'; '.join(pragma_specs)};" if pragma_specs else "No pragma directive"

            vulnerabilities.append({
                'type': 'SWC-104',
                'risk': risk_level,
                'description': description,
                'code': code_snippet,
                'lines': line_numbers
            })

        return vulnerabilities

    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")
        return []


def batch_process(input_dir, output_dir):
    """Batch process Solidity files in a directory"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    safe_files = 0
    for filename in os.listdir(input_dir):
        if filename.endswith('.sol'):
            file_path = os.path.join(input_dir, filename)
            issues = detect_swc104(file_path)

            output_path = os.path.join(output_dir, f"{os.path.splitext(filename)[0]}.txt")
            with open(output_path, 'w', encoding='utf-8') as f:
                if issues:
                    f.write(f"Found {len(issues)} SWC-104 issues in {filename}:\n")
                    f.write("=" * 80 + "\n")
                    for i, issue in enumerate(issues, 1):
                        f.write(f"Issue #{i}\n")
                        f.write(f"Lines: {', '.join(map(str, issue['lines']))}\n")
                        f.write(f"Risk: {issue['risk']}\n")
                        f.write(f"Code: {issue['code']}\n")
                        f.write(f"Description: {issue['description']}\n")
                        f.write("-" * 80 + "\n")
                else:
                    f.write(f"No SWC-104 issues detected in {filename}.\n")
                    safe_files += 1

    print(f"Total files with safe compiler versions: {safe_files}")


if __name__ == "__main__":
    input_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../datasets/DAppSCAN'))
    output_directory_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/key_feature_extract/SWC-104'))

    if not os.path.exists(input_directory):
        print(f"Error: Input directory not found - {input_directory}")
    else:
        batch_process(input_directory, output_directory)
        print(f"Results saved to: {output_directory}")
