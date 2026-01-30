# ELSA: Ensemble LLM-assisted Static Analysis

ELSA (Ensemble LLM-assisted Static Analysis) is a neuro-symbolic approach for comprehensive smart contracts vulnerability detection that integrates multiple static analysis techniques enhanced by Large Language Models (LLMs). By leveraging the unique strengths of different static analyzers and the code comprehension capabilities of LLMs, ELSA significantly improves the effectiveness and performance of vulnerability detection in Solidity smart contracts.

## Table of Contents

- [Features](#features)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Supported Datasets](#supported-datasets)
- [Workflow](#workflow)
- [Directory Structure](#directory-structure)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Citation](#citation)

## Features

- **Multi-technique Integration**: Supports multiple static analysis techniques including Mythril, Slither, SmartCheck, Oyente, Securify, Manticore, Honeybadger, and Osiris
- **LLM Enhancement**: Leverages GPT-3.5-turbo and Deepseek models for intelligent analysis
- **Multiple Analysis Strategies**: 
  - One-Shot LLM-Assisted Analysis Strategy 
  - Chain-of-Thought Reasoning-Enhanced LLM Analysis Strategy
- **Ensemble Methods**:
  - Weighted Integration: Combines results from all techniques
  - Optimal Selection: Uses the best-performing technique for specific scenarios
- **Comprehensive Coverage**: Detects 20+ types of vulnerabilities (SWC categories)
- **Four Test Datasets**: Pre-configured with ZKP_contract, smartbugs_curated, SolidiFI-benchmark, and DAppSCAN

## System Requirements

- **Operating System**: Linux, macOS, or Windows (with WSL recommended for Windows)
- **Python**: Version 3.10 or higher
- **Memory**: At least 8GB RAM (16GB recommended for large datasets)
- **Disk Space**: Minimum 5GB free space

## Installation

### Step 1: Install Python Dependencies

First, ensure you have Python 3.10+ installed:

```bash
python --version
```

Install required Python packages:

```bash
pip install openai==0.28.0
pip install py-solc-x
pip install slither-analyzer
```

### Step 2: Install Solidity Compiler

Install the Solidity compiler (solc):

```bash
pip install py-solc-x
python -c "from solcx import install_solc; install_solc('0.4.25')"
python -c "from solcx import install_solc; install_solc('0.5.0')"
python -c "from solcx import install_solc; install_solc('0.8.0')"
......
```

**Note**: Install multiple Solidity versions to ensure compatibility with different smart contracts.

### Step 3: Install Static Analysis Techniques

#### Mythril
```bash
pip install mythril
```

#### Slither
```bash
pip install slither-analyzer
```

#### SmartCheck
Follow the installation instructions at: https://github.com/smartdec/smartcheck

#### Optional Techniques (required for specific datasets)

**Oyente**:
```bash
git clone https://github.com/enzymefinance/oyente.git
cd oyente
pip install -r requirements.txt
```

**Manticore**:
```bash
pip install manticore
```

**Securify**:
Follow instructions at: https://github.com/eth-sri/securify2

**Osiris** and **Honeybadger**:
Follow respective GitHub repository instructions.

### Step 4: Clone ELSA Repository

```bash
git clone https://github.com/Anonymize-gitcode/ELSA.git
cd ELSA-main
```

## Configuration

### 1. Configure API Keys

You need to set up API keys for the LLM services you plan to use.

**For OpenAI (GPT-3.5-turbo)**:

Create or edit your environment variables:

```bash
export OPENAI_API_KEY="your-api-key-here"
```

Or add it to your Python scripts directly (not recommended for production).

**For Deepseek**:

Configure according to Deepseek's API documentation.

### 2. Configure Techniques Paths

Edit the relevant Python files in each dataset's `ZKP_technique_analysis` folder to set correct paths for installed techniques. For example:

```python
# In mythril.py
MYTHRIL_PATH = "/path/to/mythril"

# In slither.py
SLITHER_PATH = "/path/to/slither"

......
```

### 3. Configure Solidity Compiler Path

Ensure `solc` is accessible in your system PATH, or configure it in `sol_process/solc-analysis.py`:

```python
from solcx import set_solc_version
set_solc_version('0.8.0')
```

### 4. Dataset Configuration

The `config.py` file contains predefined configurations for four datasets:

```python
DATASET_CONFIG = {
    "ZKP_contract": {...},
    "smartbugs_curated": {...},
    "SolidiFI-benchmark": {...},
    "DAppSCAN": {...}
}
```

Each dataset configuration specifies:
- `swc_list`: List of vulnerability types to detect
- `techniques`: Static analysis techniques to use

## Usage

### Basic Usage

Run ELSA with the following command structure:

```bash
python execution.py \
    --analysis_strategy <strategy> \
    --ensemble_strategy <ensemble> \
    --LLM <model> \
    --dataset <dataset_name>
```

### Required Arguments

- `--analysis_strategy`: Choose the LLM-assisted static analysis strategy
  - `one_shot`: One-Shot LLM-Assisted Analysis Strategy
  - `CoT`: Chain-of-Thought Reasoning-Enhanced LLM Analysis Strategy
  
- `--ensemble_strategy`: Choose the analyzer ensemble strategy
  - `Weighted_Integration`: Combine results from all techniques
  - `Optimal_Selection`: Use the best technique (requires `--technique`)
  
- `--LLM`: Choose the language model
  - `gpt-3.5-turbo`: OpenAI GPT-3.5
  - `Deepseek`: Deepseek model
  
- `--dataset`: Choose the dataset
  - `ZKP_contract`
  - `smartbugs_curated`
  - `SolidiFI-benchmark`
  - `DAppSCAN`

### Optional Arguments

- `--ZKP_model`: Enable LLAMA-based filtering (add this flag to use)
- `--technique`: Specify a single technique when using `Optimal_Selection`
  - Options: `mythril`, `slither`, `smartcheck`, `honeybadger`, `manticore`, `osiris`, `oyente`, `securify`

## Supported Datasets

### 1. ZKP_contract
- **Focus**: Specifically designed for Zero-Knowledge Proof-based (ZKP-based) smart contracts, featuring complex algebraic constraints and cryptographic primitives.
- **Techniques**: Mythril, Slither, SmartCheck
- **Vulnerabilities**: 7 SWC categories (SWC-101, 105, 107, 110, 121, 124, 128)

### 2. smartbugs_curated
- **Focus**: A manually curated collection of vulnerable Ethereum smart contracts (from https://github.com/smartbugs/smartbugs-curated).
- **Techniques**: All 7 techniques (Honeybadger, Manticore, Mythril, Osiris, Oyente, Slither, SmartCheck)
- **Vulnerabilities**: 10 SWC categories (SWC-100 to 109)

### 3. SolidiFI-benchmark
- **Focus**: Synthetic contracts generated by injecting standardized vulnerability templates into real-world code (from https://github.com/DependableSystemsLab/SolidiFI-benchmark).
- **Techniques**: Manticore, Mythril, Securify, Oyente, Slither, SmartCheck
- **Vulnerabilities**: 7 SWC categories (SWC-101, 104, 105, 107, 115, 116, 136)

### 4. DAppSCAN
- **Focus**: Real-world DApp projects characterized by high complexity and sparse critical faults (from https://github.com/InPlusLab/DAppSCAN).
- **Techniques**: Mythril, Slither, SmartCheck
- **Vulnerabilities**: 20 SWC categories (comprehensive coverage)

## Workflow

ELSA follows a seven-step pipeline:

1. **Solidity Processing** (`sol_process/`)
   - `solc-analysis.py`: Analyze contract compilation requirements
   - `solc-process.py`: Compile contracts with appropriate Solidity versions

2. **Feature Extraction** (`key_feature_extract/`)
   - Detect specific vulnerability patterns for each SWC category
   - Run `[SWC-XXX]_detect.py` for each target vulnerability
   - Combine results using `combine.py`

3. **Static Analysis** (`ZKP_technique_analysis/`)
   - Execute configured static analysis techniques
   - Generate raw vulnerability reports

4. **Optional LLAMA Filtering** (`ZKP_LLAMA/`)
   - Split contracts for LLAMA processing
   - Filter results using LLAMA models

5. **Result Filtering** (`important_extract_filter/`)
   - Extract significant findings from each technique
   - Remove false positives and redundancies

6. **LLM-Assisted Analysis** (`LLM-assisted/`)
   - Apply selected analysis strategy (CoT or one-shot)
   - Use chosen LLM to enhance detection accuracy
   - Generate final vulnerability reports

7. **Ensemble Integration**
   - **Weighted Integration**: Combine all technique results with learned weights
   - **Optimal Selection**: Use the best-performing technique for specific contexts

## Directory Structure

```
ELSA-main/
├── config.py                    # Dataset and technique configurations
├── execution.py                 # Main execution script
├── datasets/                    # Contract datasets (.sol files)
├── ZKP_contract/                # ZKP_contract dataset pipeline
│   ├── sol_process/            # Solidity compilation
│   ├── key_feature_extract/    # Vulnerability pattern detection
│   ├── ZKP_technique_analysis/      # Static analysis execution
│   ├── ZKP_LLAMA/             # LLAMA filtering (optional)
│   ├── important_extract_filter/ # Result filtering
│   └── LLM-assisted/          # LLM enhancement
│       ├── CoT/               # Chain-of-Thought Reasoning-Enhanced LLM Analysis Strategy
│       └── one_shot/          # One-Shot LLM-Assisted Analysis Strategy
│           ├── GPT-3_5_turbo/ # GPT-3.5 implementation
│           └── Deepseek/      # Deepseek implementation
├── smartbugs_curated/          # SmartBugs dataset pipeline
├── SolidiFI-benchmark/         # SolidiFI dataset pipeline
└── DAppSCAN/                   # DAppSCAN dataset pipeline
```

## Examples

### Example 1: Full Analysis with Weighted Integration

```bash
python execution.py \
    --analysis_strategy CoT \
    --ensemble_strategy Weighted_Integration \
    --LLM gpt-3.5-turbo \
    --dataset smartbugs_curated
```

This command:
- Uses Chain-of-Thought reasoning
- Combines results from all available techniques
- Uses GPT-3.5-turbo for LLM enhancement
- Analyzes the smartbugs_curated dataset

### Example 2: Optimal Selection with Specific Technique

```bash
python execution.py \
    --analysis_strategy one_shot \
    --ensemble_strategy Optimal_Selection \
    --LLM Deepseek \
    --dataset DAppSCAN \
    --technique slither
```

This command:
- Uses one-shot learning
- Selects only Slither results
- Uses Deepseek model
- Analyzes the DAppSCAN dataset

### Example 3: Analysis with LLAMA Filtering

```bash
python execution.py \
    --analysis_strategy CoT \
    --ensemble_strategy Weighted_Integration \
    --LLM gpt-3.5-turbo \
    --dataset ZKP_contract \
    --ZKP_model
```

This command includes the optional LLAMA-based filtering step.

### Example 4: Quick Test on Small Dataset

```bash
python execution.py \
    --analysis_strategy one_shot \
    --ensemble_strategy Weighted_Integration \
    --LLM gpt-3.5-turbo \
    --dataset ZKP_contract
```

## Troubleshooting

### Common Issues

#### 1. Module Not Found Error

**Error**: `ModuleNotFoundError: No module named 'openai'`

**Solution**:
```bash
pip install openai==0.28.0
```

#### 2. Solc Version Error

**Error**: `SolcError: Solc compiler version not found`

**Solution**:
```bash
python -c "from solcx import install_solc; install_solc('0.8.0')"
```

#### 3. API Key Error

**Error**: `openai.error.AuthenticationError: Invalid API Key`

**Solution**:
```bash
export OPENAI_API_KEY="your-valid-api-key"
```

#### 4. Technique Path Error

**Error**: `Technique not found: mythril`

**Solution**: Verify technique installation and update paths in respective Python files in `ZKP_technique_analysis/` folders.

#### 5. Permission Denied

**Error**: `PermissionError: [Errno 13] Permission denied`

**Solution**:
```bash
chmod +x execution.py
```

### Getting Help

If you encounter issues:

1. Check that all dependencies are installed correctly
2. Verify API keys are set properly
3. Ensure sufficient disk space and memory
4. Check Python version compatibility (3.10+)
5. Review error logs in the terminal output

## Output Files

ELSA generates output files at various stages:

- **Compilation results**: `sol_process/` output
- **Raw technique reports**: `ZKP_technique_analysis/` output
- **Filtered results**: `important_extract_filter/` output
- **Final reports**: `LLM-assisted/[strategy]/[model]/` output

Each technique generates its own report format, and the final ensemble results are typically in JSON or CSV format.

## Performance Considerations

- **Runtime**: Depends on dataset size and number of techniques (typically 30min-4hours per dataset)
- **API Costs**: LLM API calls incur costs; monitor your usage
- **Resource Usage**: Memory-intensive techniques like Manticore may require 16GB+ RAM

