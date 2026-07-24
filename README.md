# Reproduction Package for ELSA: A Neuro-Symbolic Approach to Smart Contract Vulnerability Detection

ELSA (Ensemble LLM-assisted Static Analysis) is a neuro-symbolic approach for comprehensive smart contracts vulnerability detection that synergizes multiple static analysis techniques enhanced by Large Language Models (LLMs). By leveraging the unique strengths of different static analyzers and the semantic reasoning of LLMs, ELSA significantly improves the effectiveness and performance of vulnerability detection in Solidity smart contracts.

## Table of Contents

- [Features](#features)
- [Quick Start (Docker)](#quick-start-docker)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Supported Datasets](#supported-datasets)
- [Workflow](#workflow)
- [Directory Structure](#directory-structure)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Reproducing Paper Claims](#reproducing-paper-claims)
- [Citation](#citation)

## Features

- **Multi-technique Synergy**: Supports multiple static analysis techniques including Mythril, Slither, SmartCheck, Oyente, Securify, Manticore, Honeybadger, and Osiris
- **LLM Enhancement**: Leverages GPT-3.5-turbo and Deepseek models for semantic analysis
- **Multiple Analysis Strategies**: 
  - One-Shot LLM-Assisted Analysis Strategy 
  - Chain-of-Thought Reasoning-Enhanced LLM Analysis Strategy
- **Ensemble Methods**:
  - Weighted Integration: Combines results from all techniques
  - Optimal Selection: Uses the best-performing technique for specific scenarios
- **Comprehensive Coverage**: Detects 20+ types of vulnerabilities (SWC categories)
- **Four Test Datasets**: Pre-configured with ZKP_contract, smartbugs_curated, SolidiFI-benchmark, and DAppSCAN

## Quick Start (Docker)

For evaluation we provide a pre-built Docker image (about **1.4 GB** on disk; a few
hundred MB compressed to download) that bundles the full runtime (Python 3.10, `solc`
0.8.0, Slither, Mythril, SmartCheck, Node.js, Java) and the complete pipeline. This is
the recommended way to reproduce results — no local technique installation is required.

```bash
# 1. Pull the image (or build it locally: docker build -t elsa .)
docker pull anonymizecode/elsa:latest

# 2. Run the default smoke test (ZKP_contract, one_shot + Weighted_Integration)
docker run --rm -e OPENAI_API_KEY="your-api-key-here" anonymizecode/elsa:latest
```

Without an API key the pipeline still runs end-to-end (static analysis, filtering,
ensemble), but the LLM stages return no findings. Provide a key to get LLM-assisted
verdicts.

### Default behavior

With no extra options, the container runs the real pipeline (`execution.py`) on the
**3 bundled smoke-test contracts** (`smoke_test/*.sol`) using these defaults:

| Setting | Default |
|---|---|
| `DATASET` | `ZKP_contract` |
| `ANALYSIS_STRATEGY` | `one_shot` |
| `ENSEMBLE_STRATEGY` | `Weighted_Integration` |
| `LLM_MODEL` | `gpt-3.5-turbo` |
| `MYTHRIL_EXECUTION_TIMEOUT` | `360` (seconds per contract) |

It prints the compiler and technique versions and the contracts analyzed, then — at the end — the
per-contract LLM findings and the Weighted-Integration verdicts. All artifacts are
written under `result/` inside the container; mount a host directory at
`/elsa/result` to keep them.

### What the smoke test contains

The `smoke_test/` folder holds three small ZKP-based Solidity contracts
(`withdraw.6186.sol`, `ZKPAudit.ab71.sol`, `ZKPChal_.3b83.sol`). They are the
default input so a full run finishes in a few minutes while still exercising every
pipeline stage. The complete category-balanced ZKP dataset (2,310 files) ships in
`datasets/ZKP_dataset/`; to analyze more than the smoke set, mount a directory of
`.sol` files at `/elsa/input_contracts` (see
[Analyzing your own contracts](#analyzing-your-own-contracts)).

### Configuration knobs

Everything is controlled through environment variables (`-e NAME=value`):

| Variable | Values | Default | Meaning |
|---|---|---|---|
| `DATASET` | `ZKP_contract`, `smartbugs_curated`, `SolidiFI-benchmark`, `DAppSCAN` | `ZKP_contract` | Which per-dataset pipeline to run. Only `ZKP_contract` is fully bundled/verified in the image. |
| `ANALYSIS_STRATEGY` | `one_shot`, `CoT` | `one_shot` | LLM-assisted analysis strategy. |
| `ENSEMBLE_STRATEGY` | `Weighted_Integration`, `Optimal_Selection` | `Weighted_Integration` | Combine all techniques, or use a single one. |
| `TECHNIQUE` | `mythril`, `slither`, `smartcheck` | — | Required when `ENSEMBLE_STRATEGY=Optimal_Selection`. |
| `LLM_MODEL` | `gpt-3.5-turbo`, `Deepseek` | `gpt-3.5-turbo` | Which LLM code path to use. |
| `MYTHRIL_EXECUTION_TIMEOUT` | integer seconds (empty = unbounded) | `360` | Per-contract Mythril time budget. |

```bash
# Chain-of-Thought + Weighted Integration
docker run --rm -e OPENAI_API_KEY=... -e ANALYSIS_STRATEGY=CoT anonymizecode/elsa:latest

# Optimal Selection using a single technique (Slither)
docker run --rm -e OPENAI_API_KEY=... \
  -e ENSEMBLE_STRATEGY=Optimal_Selection -e TECHNIQUE=slither anonymizecode/elsa:latest
```

### Analyzing your own contracts

Contracts are a mountable input. Mount a directory of `.sol` files at
`/elsa/input_contracts` and they replace the bundled smoke-test set:

```bash
docker run --rm -e OPENAI_API_KEY=... \
  -v /path/to/your/contracts:/elsa/input_contracts \
  -v "$(pwd)/result:/elsa/result" \
  anonymizecode/elsa:latest
```

### Running with open models (no OpenAI key)

The `gpt-3.5-turbo` code path speaks the OpenAI API, so you can point it at any
OpenAI-compatible endpoint — a hosted free model or a fully local one — **without
editing code**, via `OPENAI_API_BASE` and `OPENAI_MODEL`:

```bash
# Hosted Llama via Groq (free tier)
docker run --rm \
  -e OPENAI_API_KEY=gsk_... \
  -e OPENAI_API_BASE=https://api.groq.com/openai/v1 \
  -e OPENAI_MODEL=llama-3.1-8b-instant \
  anonymizecode/elsa:latest

# Local Ollama (open model on your own machine)
docker run --rm --network host \
  -e OPENAI_API_KEY=ollama \
  -e OPENAI_API_BASE=http://localhost:11434/v1 \
  -e OPENAI_MODEL=llama3.1 \
  anonymizecode/elsa:latest
```

### Estimated cost

The default smoke test issues a small number of short chat-completion calls (3
contracts across the LLM stages). With `gpt-3.5-turbo` this costs well under
US$0.05; with a free Groq endpoint or a local Ollama model it is free.

## System Requirements

> The Docker image (see [Quick Start](#quick-start-docker)) already satisfies all of
> these. The requirements below apply only to a manual/native installation.

- **Operating System**: Linux, macOS, or Windows (with WSL recommended for Windows)
- **Python**: Version 3.10 or higher
- **Memory**: At least 8GB RAM (16GB recommended for large datasets)
- **Disk Space**: Minimum 10GB free space (20GB+ recommended)

## Installation

> **Recommended:** use the Docker image (see [Quick Start](#quick-start-docker)); it
> bundles every dependency below. Follow the manual steps only for a native install.

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

**Core Techniques:**
* **Mythril:** `pip install mythril`
* **Slither:** `pip install slither-analyzer`
* **SmartCheck:** Follow the instructions in the [official repository](https://github.com/smartdec/smartcheck).

**Optional Techniques (Required for specific datasets):**
Due to specific environment dependencies, please refer to the official repositories for installation (Docker-based setup is highly recommended where applicable):
* **[Oyente](https://github.com/enzymefinance/oyente)**
* **[Manticore](https://github.com/trailofbits/manticore)**
* **[Securify2](https://github.com/eth-sri/securify2)**
* **[Osiris](https://github.com/christoftorres/Osiris)** *(Docker quick-start available)*
* **[HoneyBadger](https://github.com/christoftorres/HoneyBadger)** *(Docker quick-start available)*

### Step 4: Clone ELSA Repository

```bash
git clone https://github.com/Anonymize-gitcode/ELSA.git
cd ELSA-main
```

## Configuration

### 1. Configure API Keys

API keys live in **one place** and are read from the environment — they are never
hard-coded in the scripts. Copy the template and fill in the key(s) for the LLM(s)
you plan to use:

```bash
cp .env.example .env
# then edit .env
```

`.env` is loaded automatically by `execution.py` and inherited by every pipeline
step; it is git-ignored, so keys are never committed. You may also `export` the same
variables instead of using a file.

```bash
# OpenAI, used with --LLM gpt-3.5-turbo
OPENAI_API_KEY=your-api-key-here

# Deepseek, used with --LLM Deepseek
DEEPSEEK_API_KEY=your-deepseek-key

# Optional: route the gpt-3.5-turbo path to ANY OpenAI-compatible endpoint
# (e.g. a free/open model) without editing code — leave unset for standard OpenAI.
OPENAI_API_BASE=
OPENAI_MODEL=
```

### 2. Static Analysis Techniques

The static analysis techniques are invoked from your `PATH` — there are no path
constants to edit. Make sure the techniques you plan to use are installed and runnable:

```bash
slither --version
myth version        # Mythril
smartcheck          # SmartCheck
solc --version
```

The Docker image already provides `solc`, Slither, Mythril, and SmartCheck.

### 3. Solidity Compiler

`solc` is invoked from your `PATH`. The `ZKP_contract` and `smartbugs_curated`
pipelines use a fixed `solc 0.8.0` for every contract, so make sure that version is
installed. `DAppSCAN` and `SolidiFI-benchmark` auto-install/switch `solc` versions
per contract via `solc-select`.

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
  - `Deepseek`: DeepSeek-Chat
  - ... (other models)
  
- `--dataset`: Choose the dataset
  - `ZKP_contract`
  - `smartbugs_curated`
  - `SolidiFI-benchmark`
  - `DAppSCAN`

### Optional Arguments

- `--ZKP_model`: Enable LLAMA-based ZKP-specific semantic alignment (add this flag to use)
- `--technique`: Specify a single technique when using `Optimal_Selection`
  - Options: `mythril`, `slither`, `smartcheck`, `honeybadger`, `manticore`, `osiris`, `oyente`, `securify`

## Supported Datasets

### 1. ZKP_contract
- **Focus**: Specifically designed for Zero-Knowledge Proof-based (ZKP-based) smart contracts, featuring complex algebraic constraints and cryptographic primitives. Sampled from the ZKP_dataset (containing 2,310 Solidity files).
- **Techniques**: Mythril, Slither, SmartCheck
- **Vulnerabilities**: 7 SWC categories (SWC-101, 105, 107, 110, 121, 124, 128)

### 2. smartbugs_curated
- **Focus**: A manually curated collection of vulnerable Ethereum smart contracts (from https://github.com/smartbugs/smartbugs-curated).
- **Techniques**: All 7 techniques (Honeybadger, Manticore, Mythril, Osiris, Oyente, Slither, SmartCheck)
- **Vulnerabilities**: 9 SWC categories (SWC-101, 104, 105, 107, 113, 114, 116, 120, Oth./999)
- 
### 3. SolidiFI-benchmark
- **Focus**: Synthetic contracts generated by injecting standardized vulnerability templates into real-world code (from https://github.com/DependableSystemsLab/SolidiFI-benchmark).
- **Techniques**: Manticore, Mythril, Securify, Oyente, Slither, SmartCheck
- **Vulnerabilities**: 7 SWC categories (SWC-101, 104, 105, 107, 115, 116, 136)

### 4. DAppSCAN
- **Focus**: Real-world DApp projects characterized by high complexity and sparse critical faults (from https://github.com/InPlusLab/DAppSCAN).
- **Techniques**: Mythril, Slither, SmartCheck
- **Vulnerabilities**: 20 SWC categories (comprehensive coverage)

## The ZKP_dataset

The `datasets/ZKP_dataset/` directory holds the complete category-balanced ZKP-based dataset. It contains **2,310 Solidity files** and is constructed through vulnerability injection, with origin contracts comprising **23 single-chain and 12 cross-chain** ZKP-based smart contracts sourced from open-source Ethereum and GitHub projects.

### Organization

The files are grouped into **7 vulnerability-category subfolders**, which double as the ground-truth labels:

| Category (folder)                                      | SWC code |
|--------------------------------------------------------|----------|
| `Reentrancy`                                           | SWC-107  |
| `Integer_Overflow_and_Underflow`                       | SWC-101  |
| `Unprotected_Ether_Withdrawal`                         | SWC-105  |
| `Assert_Violation`                                     | SWC-110  |
| `Missing_Protection_Against_Signature_Replay_Attacks`  | SWC-121  |
| `Write_to_Arbitrary_Storage_Location`                  | SWC-124  |
| `DoS_with_Block_Gas_Limit_Gas`                          | SWC-128  |

## Workflow

ELSA follows a seven-step pipeline:

1. **Solidity Processing** (`sol_process/`)
   - `solc-analysis.py`: Analyze contract compilation requirements
   - `solc-process.py`: Compile contracts with appropriate Solidity versions

2. **Constraint Context Abstraction** (`key_feature_extract/`)
   - Detect specific vulnerability patterns for each SWC category
   - Run `[SWC-XXX]_detect.py` for each target vulnerability
   - Combine results using `combine.py`

3. **Static Analysis** (`technique_analysis/`)
   - Execute configured static analysis techniques
   - Generate raw vulnerability reports

4. **Optional LLAMA semantic alignment** (`ZKP_LLAMA/`)
   - Split contracts for LLAMA processing
   - Filter results using LLAMA models

5. **Result Filtering** (`important_extract_filter/`)
   - Extract significant findings from each technique
   - Remove false positives and redundancies

6. **LLM-Assisted Analysis** (`LLM-assisted/`)
   - Apply selected analysis strategy (CoT or one-shot)
   - Use chosen LLM to enhance detection accuracy
   - Generate final vulnerability reports

7. **Analyzer Ensemble**
   - **Weighted Integration**: Combine all technique results with learned weights
   - **Optimal Selection**: Use the best-performing technique for specific contexts

## Directory Structure

```
ELSA-main/
├── Dockerfile                   # Container image for the full pipeline (recommended)
├── docker/run.sh                # Container entrypoint (env-var driven)
├── .dockerignore                # Build-context excludes (prevents image bloat)
├── .env.example                 # Template for API keys (copy to .env)
├── requirements.txt             # Python dependencies
├── REQUIREMENTS.md              # Artifact Evaluation: hardware/software requirements
├── STATUS.md                    # Artifact Evaluation: requested badges
├── LICENSE                      # MIT license
├── config.py                    # Dataset and technique configurations
├── execution.py                 # Main execution script
├── smoke_test/                  # 3 sample ZKP contracts (default Docker smoke test)
├── datasets/                    # Contract datasets (.sol files)
│   └── ZKP_dataset/            # Full category-balanced ZKP dataset (2,310 files)
├── ZKP_contract/                # ZKP_contract dataset pipeline
│   ├── sol_process/            # Solidity compilation
│   ├── key_feature_extract/    # Vulnerability pattern detection
│   ├── technique_analysis/ # Static analysis execution
│   ├── ZKP_LLAMA/              # LLAMA-based ZKP-specific semantic alignment (optional)
│   ├── important_extract_filter/ # Result filtering
│   └── LLM-assisted/           # LLM enhancement
│       ├── CoT/                # Chain-of-Thought Reasoning-Enhanced LLM Analysis Strategy
│       └── one_shot/           # One-Shot LLM-Assisted Analysis Strategy
│           ├── GPT-3_5_turbo/  # GPT-3.5 implementation
│           └── Deepseek/       # Deepseek implementation
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
- Uses One-Shot LLM-Assisted Analysis
- Selects only Slither results
- Uses Deepseek model
- Analyzes the DAppSCAN dataset

### Example 3: Analysis with LLAMA semantic alignment

```bash
python execution.py \
    --analysis_strategy CoT \
    --ensemble_strategy Weighted_Integration \
    --LLM gpt-3.5-turbo \
    --dataset ZKP_contract \
    --ZKP_model
```

This command includes the optional LLAMA-based semantic alignment step.

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

#### 4. Technique Not Found

**Error**: `Technique not found: mythril` (or `slither`, `smartcheck`)

**Solution**: The techniques are called from your `PATH`; there are no path constants
to edit. Verify the technique is installed and runnable (`myth version`, `slither --version`,
`smartcheck`), or use the Docker image, which bundles them.

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

## Input and Output Files

ELSA requires the analysis result files from all techniques to be in TXT format.

ELSA generates output files at various stages:

- **Compilation results**: `sol_process/` output
- **Raw technique reports**: `technique_analysis/` output
- **Filtered results**: `important_extract_filter/` output
- **Final reports**: `LLM-assisted/[strategy]/[model]/` output

Each technique generates its own report format, and the final ensemble results are typically in JSON, TXT or CSV format.  

## Performance Considerations

- **Runtime**: Depends on dataset size and number of techniques (typically 30min-4hours per dataset)
- **API Costs**: LLM API calls incur costs; monitor your usage
- **Resource Usage**: Memory-intensive techniques like Manticore may require 16GB+ RAM

## Reproducing Paper Claims

The artifact reproduces the paper's central claim — that ensembling multiple static
analysis techniques with LLM-assisted reasoning improves smart-contract
vulnerability detection — through the same `execution.py` pipeline used in the paper.

| Paper claim | How to reproduce |
|---|---|
| The end-to-end ELSA pipeline runs as described | `docker run ... anonymizecode/elsa:latest` executes the workflow and prints per-stage artifacts. |
| Two LLM-assisted static analysis strategies (One-Shot, Chain-of-Thought) | Set `ANALYSIS_STRATEGY=one_shot` or `CoT`. |
| Two analyzer ensemble strategies (Weighted Integration, Optimal Selection) | Set `ENSEMBLE_STRATEGY=Weighted_Integration`, or `Optimal_Selection` with `TECHNIQUE=...`. |
| ELSA targets ZKP-based contracts | `DATASET=ZKP_contract` (default). The full category-balanced dataset (2,310 files) is in `datasets/ZKP_dataset/`. |
| Each technique contributes to the ensemble | Compare single-technique `Optimal_Selection` runs (`TECHNIQUE=mythril/slither/smartcheck`) against `Weighted_Integration`. |

The bundled 3-contract smoke test finishes in a few minutes and exercises the full
pipeline — per-technique reports, LLM-assisted findings, and an ensemble verdict.
Reproducing the full tables from the paper is a matter of mounting more contracts
(`-v ...:/elsa/input_contracts`) and, for datasets other than `ZKP_contract`,
installing their additional techniques.

## Citation

This artifact accompanies a research paper that is **currently under review**. To preserve double-blind anonymity, the authors, venue, and DOI are
intentionally omitted for now and will be filled in once the paper is published.
If you use ELSA in your research, please cite it using the template below:
```bibtex
@inproceedings{elsa,
title     = {Augmenting Multi-Technique Static Analysis with Large Language Models: A Neuro-Symbolic Approach to Smart Contract Vulnerability Detection},
author    = {Anonymous Author(s)},
booktitle = {ISSTA},
year      = {},
doi       = {},
note      = {Under review}
}
```

