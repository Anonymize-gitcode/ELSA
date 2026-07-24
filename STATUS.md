# STATUS

## Badges Requested

The authors of **ELSA (Ensemble LLM-assisted Static Analysis)** apply for the following artifact-evaluation badges:

* **Artifacts Available**
* **Artifacts Evaluated - Functional**
* **Artifacts Evaluated - Reusable**

## Why the Artifact Deserves the *Available* Badge

The artifact is publicly and permanently archived on Zenodo (DOI: https://doi.org/10.5281/zenodo.21523579) with open access. It includes:

* The complete ELSA source code and orchestration pipeline.
* A self-contained Docker image, published on Docker Hub as `anonymizecode/elsa:latest` and also archived with the Zenodo record. The image bundles `solc`, Slither, Mythril, and SmartCheck for one-command execution.
* Documentation (`README.md`), dependency specifications (`requirements.txt`, `REQUIREMENTS.md`), and an open-source `LICENSE`.

## Why the Artifact Deserves the *Functional* Badge

The artifact is documented, consistent, complete, and exercisable:

* **Documented:** `README.md` provides a Docker quick start, installation instructions, configuration guidance, usage examples, troubleshooting notes, and a paper-claims reproduction map. `REQUIREMENTS.md` details the prerequisites.
* **Consistent:** The artifact implements the methods described in the paper, including LLM-assisted static analysis strategies (One-Shot and Chain-of-Thought), and analyzer ensemble strategies (Weighted Integration and Optimal Selection).
* **Exercisable:** The bundled Docker image runs the real pipeline end-to-end with a single command on a self-contained three-contract smoke-test subset, without requiring manual installation of individual analysis tools. LLM credentials are read from one place (`.env` or environment variables via `python-dotenv`) rather than being hard-coded. The pipeline can also run with open-model backends such as a local Ollama server or a hosted Llama-compatible endpoint by setting `OPENAI_API_BASE` and `OPENAI_MODEL`.

## Why the Artifact Deserves the *Reusable* Badge

The artifact is structured for reuse and extension beyond the paper:

* The self-contained Docker container removes the need for manual, non-portable installation of multiple analyzers, allowing evaluators to build on the artifact immediately.
* The configuration-driven design (`config.py`) makes it straightforward to add new datasets, vulnerability categories, or static-analysis techniques.
* The pipeline is modularized into clearly separated stages (`sol_process/`, `key_feature_extract/`, `technique_analysis/`, `important_extract_filter/`, `LLM-assisted/`).
* Key experimental dimensions are parameterized, including dataset, LLM-assisted static analysis strategy (`one_shot`/`CoT`), analyzer ensemble strategy (`Weighted_Integration`/`Optimal_Selection`), LLM backend (GPT-3.5-turbo, DeepSeek, or any OpenAI-compatible/open model), and input contracts. These options can be selected through environment variables or CLI flags.
* The artifact is released under a permissive open-source license (see `LICENSE`), permitting modification and redistribution.

## How to Evaluate

The fastest path is to pull the pre-built image and run one command:

`docker pull anonymizecode/elsa:latest`

Then follow the Docker quick-start command in `README.md`. The image runs the smoke test by default and can be configured through environment variables such as `OPENAI_API_KEY`, `OPENAI_API_BASE`, and `OPENAI_MODEL`.

As an offline alternative, evaluators can load the archived image from the Zenodo record:

For a native installation, please verify the prerequisites in `REQUIREMENTS.md` and follow the installation, configuration, and usage steps in `README.md`.
