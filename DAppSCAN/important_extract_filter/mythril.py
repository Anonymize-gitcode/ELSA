import os
import json
import re
import logging
from pathlib import Path

try:
    import demjson3
except ImportError:
    raise ImportError("Please install demjson3 library first: pip install demjson3")

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def clean_long_hex_fields(text: str) -> str:
    """Clean long hexadecimal fields to avoid interfering with the parser"""
    if not text:
        return text

    # Match long hexadecimal strings in input fields
    hex_pattern = re.compile(
        r'("input"\s*:\s*")(0x[0-9a-fA-F]{100,})(")',
        re.DOTALL
    )

    def truncate_hex(match):
        key = match.group(1)
        hex_str = match.group(2)
        suffix = match.group(3)
        # Keep the first 100 characters and the last 10 characters, replace the middle with "..."
        if len(hex_str) > 110:
            return f'{key}{hex_str[:100]}...{hex_str[-10:]}{suffix}'
        return match.group(0)

    return hex_pattern.sub(truncate_hex, text)


def fix_unclosed_structures(text: str) -> str:
    """Fix unclosed JSON structures (mismatched brackets and quotes)"""
    if not text:
        return text

    # Count bracket matches
    open_braces = text.count('{')
    close_braces = text.count('}')
    open_brackets = text.count('[')
    close_brackets = text.count(']')

    # Add missing closing brackets
    if open_braces > close_braces:
        text += '}' * (open_braces - close_braces)
        logger.debug(f"Added {open_braces - close_braces} missing")
    if open_brackets > close_brackets:
        text += ']' * (open_brackets - close_brackets)
        logger.debug(f"Added {open_brackets - close_brackets} missing")

    # Ensure quotes are closed
    if text.count('"') % 2 != 0:
        text += '"'
        logger.debug("Added 1 missing quote")

    return text


def fix_description_field(text: str) -> str:
    """Fix special characters in description field"""
    if not text:
        return text

    desc_pattern = re.compile(
        r'("description"|"Description")\s*:\s*"([^"]*?)(?<!\\)"',
        re.DOTALL
    )

    def process_match(match):
        key = match.group(1)
        content = match.group(2)
        content = re.sub(r'(?<!\\)"', '\\"', content)  # Escape unescaped quotes
        content = content.replace('\n', '\\n')
        content = content.replace('\t', '\\t')
        return f'{key}: "{content}"'

    return desc_pattern.sub(process_match, text)


def extract_json_from_text(text: str) -> list:
    """Final parsing logic: process long fields and unclosed structures"""
    valid_jsons = []
    original_text = text

    if not text.strip():
        return valid_jsons

    # 1. Step-by-step preprocessing (priority order)
    text = fix_description_field(text)  # First, process description field
    text = clean_long_hex_fields(text)  # Process long hexadecimal
    text = fix_unclosed_structures(text)  # Fix unclosed structures

    # 2. Extract ZortCoin specific format JSON (complete structure with tx_sequence)
    json_pattern = re.compile(
        r'\{\s*"error"\s*:\s*null\s*,\s*"issues"\s*:\s*\[\s*\{.*?\}\s*\]\s*,\s*"success"\s*:\s*true\s*\}',
        re.DOTALL
    )
    candidates = json_pattern.findall(text)

    # 3. If not found, try a more general pattern
    if not candidates:
        candidates = re.findall(
            r'\{[^{}]*?"issues"?\s*:\s*\[[^]]*\][^{}]*\}',
            text,
            re.DOTALL
        )

    logger.debug(f"Found {len(candidates)} candidate JSON fragments")

    # 4. Parse each candidate fragment
    for idx, candidate in enumerate(candidates):
        candidate = candidate.strip()
        if len(candidate) < 50:
            continue

        parsed = None

        # Try 1: Standard parsing
        try:
            parsed = json.loads(candidate)
            logger.debug(f"Candidate {idx} standard parsing succeeded")
        except Exception as e:
            logger.debug(f"Candidate {idx} standard parsing failed: {str(e)}")

        # Try 2: Tolerant parsing
        if parsed is None:
            try:
                parsed = demjson3.decode(candidate, strict=False)
                logger.debug(f"Candidate {idx} demjson3 parsing succeeded")
            except Exception as e:
                logger.debug(f"Candidate {idx} demjson3 parsing failed: {str(e)}")

        # Validate result
        if parsed and isinstance(parsed, dict) and "issues" in parsed:
            valid_jsons.append(parsed)

    # 5. Final attempt: Parse by truncating excess content
    if not valid_jsons:
        try:
            # Find potential JSON end position
            end_marker = '"success": true}'
            end_pos = text.rfind(end_marker)
            if end_pos != -1:
                truncated = text[:end_pos + len(end_marker)]
                parsed = demjson3.decode(truncated, strict=False)
                if isinstance(parsed, dict) and "issues" in parsed:
                    valid_jsons.append(parsed)
                    logger.debug("Parsing succeeded after truncating excess content")
        except Exception as e:
            logger.debug(f"Truncation parsing failed: {str(e)}")

    # 6. Remove duplicates
    unique_jsons = []
    seen = set()
    for js in valid_jsons:
        try:
            js_str = json.dumps(js, sort_keys=True, default=str)
            if js_str not in seen:
                seen.add(js_str)
                unique_jsons.append(js)
        except:
            unique_jsons.append(js)

    logger.info(f"Extracted {len(unique_jsons)} valid JSON objects")
    return unique_jsons


def filter_analysis_results(input_dir: str, output_dir: str) -> None:
    """Process all txt files in the input directory"""
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    txt_files = list(input_path.glob("*.txt"))

    if not txt_files:
        logger.warning(f"No txt files found in input directory {input_dir}")
        return

    for txt_file in txt_files:
        try:
            encodings = ['utf-8', 'latin-1', 'utf-16']
            content = None
            for encoding in encodings:
                try:
                    with open(txt_file, 'r', encoding=encoding) as f:
                        content = f.read()
                    break
                except UnicodeDecodeError:
                    continue

            if content is None:
                logger.error(f"File {txt_file.name} cannot be read")
                continue

            extracted_jsons = extract_json_from_text(content)

            if extracted_jsons:
                all_issues = []
                for data in extracted_jsons:
                    issues = data.get("issues", [])
                    if isinstance(issues, list):
                        for issue in issues:
                            if not isinstance(issue, dict):
                                continue

                            filtered = {
                                "contract": issue.get("contract") or "unknown",
                                "filename": issue.get("filename") or txt_file.name,
                                "description": issue.get("description") or "no description",
                                "severity": issue.get("severity", "Low").capitalize(),
                                "code": issue.get("code", ""),
                                "swc-id": issue.get("swc-id")
                            }
                            all_issues.append(filtered)

                output_file = output_path / txt_file.name
                with open(output_file, 'w', encoding='utf-8') as f:
                    json.dump({"issues": all_issues}, f, indent=4, ensure_ascii=False)

                logger.info(f"Processed {txt_file.name}, extracted {len(all_issues)} issues")

            else:
                output_file = output_path / txt_file.name
                with open(output_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                logger.info(f"{txt_file.name} did not extract valid JSON, saved original content")

        except Exception as e:
            logger.error(f"Error processing {txt_file.name}: {str(e)}")


if __name__ == "__main__":
    input_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/mythril_tool_analysis'))
    output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../result/mythril_tool_analysis_filter'))
    filter_analysis_results(input_dir, output_dir)
    logger.info("All files processed")
