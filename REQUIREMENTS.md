# REQUIREMENTS


This document lists the hardware and software prerequisites for running **ELSA (Ensemble LLM-assisted Static Analysis)**. For step-by-step installation, configuration, and per-dataset details, see `README.md`. For the exact pinned Python dependencies, see `requirements.txt`.


## 0. Recommended: Docker


The recommended way to run ELSA is through the pre-built Docker image. The image packages `solc` 0.8.0, Slither, Mythril, SmartCheck, and the Python dependencies required by the main pipeline. With Docker, no manual installation of the OS, compiler, or analysis-technique prerequisites.
Pull the image and run the default smoke test with:


```bash
docker pull anonymizecode/elsa:latest
docker run --rm -e OPENAI_API_KEY=sk-... anonymizecode/elsa:latest
```


See the Docker Quick Start section in `README.md` for details. 


## 1. Hardware


| Resource | Minimum                                                           | Recommended                                       |
| -------- | ----------------------------------------------------------------- | ------------------------------------------------- |
| CPU      | 2 cores, x86-64                                                   | 4 or more cores                                   |
| Memory   | 8 GB RAM                                                          | 16 GB or more RAM for Manticore or large datasets |
| Disk     | 10 GB free space                                                  | 20 GB or more free space                          |
| Network  | Internet access for LLM API calls and Solidity compiler downloads | Stable broadband                                  |


## 2. Operating System


ELSA supports Linux, macOS, and Windows. Ubuntu 20.04 or later is best supported. macOS 12 or later is also supported. On Windows 10 or 11, WSL2 is strongly recommended because several techniques, including Oyente, Securify, and Manticore, target Unix-like environments.


## 3. Software


* **Python:** Python 3.10 or later with `pip`.
* **Solidity compiler:** `solc` must be available from your `PATH`. The `ZKP_contract` and `smartbugs_curated` datasets use a fixed `solc` 0.8.0. The `DAppSCAN` and `SolidiFI-benchmark` datasets automatically install or switch compiler versions per contract through `solc-select`. See section 3 of `README.md` for details.
* **Python packages:** Install with `pip install -r requirements.txt`.
* **Static analysis techniques:** Mythril, Slither, SmartCheck, Oyente, Manticore, Securify, Osiris, and Honeybadger. Only the subset required by the target dataset needs to be installed. See the per-dataset technique lists and installation instructions in `README.md`.
* **LLM API access:** An LLM API key is required for the LLM-assisted stage. Use `OPENAI_API_KEY` for GPT-3.5-turbo or configure the corresponding credentials for DeepSeek or another OpenAI-compatible backend. API usage may incur cost.
