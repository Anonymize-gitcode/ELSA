# A tool for ELSA

ELSA (Ensemble LLM-assisted Static Analysis) is an approach that integrates the unique strengths of multiple static analysis techniques, each enhanced by the code comprehension and analysis capabilities of Large Language Models (LLMs), to improve the effectiveness and performance of vulnerability detection.
A tool has been implemented based on the ELSA.

The config.py file contains the tool's configuration, and execution.py is the main script for running the tool. The tool has been tested on three different sub-datasets, and both the sub-datasets and the detailed code are organized into their respective folders. These correspond to the datasets used in the experiment (§4) and the detailed examples of the code in the experiment (§3) from the paper.

# User Setup Requirements

To run the tool, please follow these steps:

1\. Install \*\*Python 3.10+\*\* and the necessary packages (e.g., `solc`).

2\. Configure the required \*\*API keys\*\*, set the correct location for `solc`, and specify the installation location for the \*\*static analysis techniques\*\*.

3\. Run the tool using the following command:

&nbsp;  ```bash

&nbsp;  python execution.py

