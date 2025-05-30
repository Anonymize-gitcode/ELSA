import argparse
import subprocess
import os
import sys

from config import DATASET_CONFIG

def run_script(script_path):
    if not os.path.isfile(script_path):
        print(f"Script not found: {script_path}", file=sys.stderr)
        sys.exit(1)
    try:
        print(f"Running: {script_path}")
        subprocess.run(["python", script_path], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running {script_path}: {e}", file=sys.stderr)
        sys.exit(e.returncode)

def process_dataset(args, config):
    base = os.getcwd()
    dataset = args.dataset

    # Step 1: sol_process
    run_script(os.path.join(base, dataset, "sol_process", "solc-analysis.py"))
    run_script(os.path.join(base, dataset, "sol_process", "solc-process.py"))

    # Step 2: SWC detect
    for swc in config["swc_list"]:
        run_script(os.path.join(base, dataset, "key_feature_extract", f"{swc}_detect.py"))

    # Step 3: combine
    run_script(os.path.join(base, dataset, "key_feature_extract", "combine.py"))

    # Step 4: tool analysis
    for tool in config["tools"]:
        run_script(os.path.join(base, dataset, "ZKP_tool_analysis", f"{tool}.py"))

    # Step 5: optional LLAMA
    if args.ZKP_model:
        run_script(os.path.join(base, dataset, "ZKP_LLAMA", "split_contract_for_LLAMA.py"))
        run_script(os.path.join(base, dataset, "ZKP_LLAMA", "ZKP_LLAMA_filter.py"))

    # Step 6: filter
    for tool in config["tools"]:
        run_script(os.path.join(base, dataset, "important_extract_filter", f"{tool}.py"))

    # Step 7: LLM-assisted
    if args.LLM == "gpt-3.5-turbo": args.LLM = "gpt-3_5_turbo"
    llm_path = os.path.join(base, dataset, "LLM-assisted", args.analtysis_stratery, args.LLM)
    if args.ensemble_stratery == "Weighted_Integration":
        for tool in config["tools"] + ["Weighted_Integration"]:
            run_script(os.path.join(llm_path, f"{tool}.py"))
    elif args.ensemble_stratery == "Optimal_Selection":
        if not args.technique:
            print("Error: --technique must be specified when using Optimal_Selection strategy", file=sys.stderr)
            sys.exit(1)
        run_script(os.path.join(llm_path, f"{args.technique}.py"))

def main():
    parser = argparse.ArgumentParser(description="Run vulnerability analysis pipeline")
    parser.add_argument("--analysis_strategy", required=True, choices=["CoT", "one_shot"])
    parser.add_argument("--ensemble_strategy", required=True, choices=["Weighted_Integration", "Optimal_Selection"])
    parser.add_argument("--LLM", required=True, choices=["gpt-3.5-turbo", "Deepseek"])
    parser.add_argument("--dataset", required=True, choices=list(DATASET_CONFIG.keys()))
    parser.add_argument("--ZKP_model", action="store_true")
    parser.add_argument("--technique", choices=["mythril", "slither", "smartcheck", "honeybadger", "manticore", "osiris", "oyente", "securify"])

    args = parser.parse_args()
    config = DATASET_CONFIG.get(args.dataset)
    process_dataset(args, config)

if __name__ == "__main__":
    main()
