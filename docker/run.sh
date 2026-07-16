#!/usr/bin/env bash
# Entrypoint for the ELSA artifact container.
#
# Runs the REAL pipeline (execution.py). Everything is configured through
# optional environment variables (sensible defaults shown):
#
#   DATASET=ZKP_contract|smartbugs_curated|SolidiFI-benchmark|DAppSCAN  (default: ZKP_contract)
#   ANALYSIS_STRATEGY=one_shot|CoT                 (default: one_shot)
#   ENSEMBLE_STRATEGY=Weighted_Integration|Optimal_Selection  (default: Weighted_Integration)
#   TECHNIQUE=mythril|slither|smartcheck                     (required when ENSEMBLE_STRATEGY=Optimal_Selection)
#   LLM_MODEL=gpt-3.5-turbo|Deepseek               (default: gpt-3.5-turbo)
#   OPENAI_API_KEY=...                             (needed for the LLM stages to return findings)
#   OPENAI_API_BASE=... / OPENAI_MODEL=...         (optional: free/open OpenAI-compatible endpoint)
#
# Contracts are a mountable input parameter. To analyze your OWN contracts, mount
# a directory of .sol files at /elsa/input_contracts:
#     docker run --rm -v /path/to/your/contracts:/elsa/input_contracts elsa
# With nothing mounted, the 3 bundled smoke-test contracts (smoke_test/*.sol) are used.
set -uo pipefail

STRATEGY="${ANALYSIS_STRATEGY:-one_shot}"
ENSEMBLE="${ENSEMBLE_STRATEGY:-Weighted_Integration}"
TECHNIQUE="${TECHNIQUE:-}"
LLM="${LLM_MODEL:-gpt-3.5-turbo}"
# Dataset selects which per-dataset code tree runs (its own SWC list, techniques,
# and LLM-assisted/<strategy>/<LLM> scripts). Default ZKP_contract is the one fully
# bundled/verified in this image; the others need extra analyzers not installed here.
DATASET="${DATASET:-ZKP_contract}"

# Result folders are named after the LLM: gpt-3.5-turbo -> *_gpt_3_5_turbo,
# Deepseek -> *_deepseek. Used only for the end-of-run summary display.
if [ "${LLM}" = "Deepseek" ]; then LLM_SUFFIX="deepseek"; else LLM_SUFFIX="gpt_3_5_turbo"; fi

# Bound Mythril so a pathological contract cannot hang the smoke run. Set to empty
# (-e MYTHRIL_EXECUTION_TIMEOUT=) to restore Mythril's unbounded default.
export MYTHRIL_EXECUTION_TIMEOUT="${MYTHRIL_EXECUTION_TIMEOUT-360}"

echo "=================================================================="
echo " ELSA artifact container"
echo "   dataset           = ${DATASET}"
echo "   analysis_strategy = ${STRATEGY}"
echo "   ensemble_strategy = ${ENSEMBLE}"
if [ "${ENSEMBLE}" = "Optimal_Selection" ]; then
  echo "   technique         = ${TECHNIQUE:-(not set — required)}"
fi
echo "   LLM               = ${LLM}"
echo "   solc              = $(solc --version 2>/dev/null | tail -n1)"
echo "   slither           = $(slither --version 2>&1 | head -n1)"
if command -v myth >/dev/null 2>&1; then
  echo "   mythril           = $(myth version 2>/dev/null | head -n1) (timeout=${MYTHRIL_EXECUTION_TIMEOUT:-unbounded}s/contract)"
else
  echo "   mythril           = (not installed; technique skipped)"
fi
if command -v smartcheck >/dev/null 2>&1; then
  echo "   smartcheck        = available"
else
  echo "   smartcheck        = (not installed; technique skipped)"
fi
# solc-process (structure compression, Step 1) always uses OPENAI_API_KEY; the
# per-technique analysis uses OPENAI_* for gpt-3.5-turbo or DEEPSEEK_* for Deepseek.
if [ "${LLM}" = "Deepseek" ]; then ANALYSIS_KEY="${DEEPSEEK_API_KEY:-}"; else ANALYSIS_KEY="${OPENAI_API_KEY:-}"; fi
if [ -z "${ANALYSIS_KEY}" ]; then
  echo "   LLM credentials   = (none) -> the pipeline runs end-to-end, but the LLM"
  echo "                        stages return no findings. Pass -e OPENAI_API_KEY=... (gpt-3.5-turbo)"
  echo "                        or -e DEEPSEEK_API_KEY=... (Deepseek); solc-process compression"
  echo "                        additionally needs OPENAI_API_KEY."
else
  echo "   LLM credentials   = provided"
  [ -n "${OPENAI_API_BASE:-}" ] && echo "   OPENAI_API_BASE   = ${OPENAI_API_BASE}"
  [ -n "${OPENAI_MODEL:-}" ] && echo "   OPENAI_MODEL      = ${OPENAI_MODEL}"
  [ "${LLM}" = "Deepseek" ] && [ -n "${DEEPSEEK_BASE_URL:-}" ] && echo "   DEEPSEEK_BASE_URL = ${DEEPSEEK_BASE_URL}"
  [ "${LLM}" = "Deepseek" ] && [ -n "${DEEPSEEK_MODEL:-}" ] && echo "   DEEPSEEK_MODEL    = ${DEEPSEEK_MODEL}"
fi
echo "=================================================================="

if [ "${DATASET}" != "ZKP_contract" ]; then
  echo "[run.sh] NOTE: dataset '${DATASET}' selected. Only ZKP_contract is fully"
  echo "         bundled in this image. Other datasets may reference analyzers not"
  echo "         installed here (e.g. Oyente, Manticore, Securify) and will skip them."
fi

# --- Prepare the dataset directory ----------------------------------------
# Contracts are a mountable input: a directory of .sol files at /elsa/input_contracts
# overrides the bundled set. Otherwise the 3 bundled smoke-test contracts are used.
rm -rf "datasets/${DATASET}"
mkdir -p "datasets/${DATASET}"
if compgen -G "/elsa/input_contracts/*.sol" > /dev/null 2>&1; then
  echo "[run.sh] Using mounted contracts from /elsa/input_contracts"
  cp /elsa/input_contracts/*.sol "datasets/${DATASET}/"
else
  echo "[run.sh] Using the bundled smoke-test contracts (smoke_test/*.sol)"
  cp smoke_test/*.sol "datasets/${DATASET}/"
fi
echo "[run.sh] Contracts to analyze:"
ls -1 "datasets/${DATASET}"/*.sol | sed 's#.*/#    #'

# Start from a clean result tree (clear contents; tolerate result/ being a mount).
rm -rf result 2>/dev/null || true
mkdir -p result

echo "[run.sh] python execution.py --analysis_strategy ${STRATEGY} --ensemble_strategy ${ENSEMBLE} --LLM ${LLM} --dataset ${DATASET}${TECHNIQUE:+ --technique ${TECHNIQUE}}"
EXEC_ARGS=(
  --analysis_strategy "${STRATEGY}"
  --ensemble_strategy "${ENSEMBLE}"
  --LLM "${LLM}"
  --dataset "${DATASET}"
)
if [ "${ENSEMBLE}" = "Optimal_Selection" ]; then
  if [ -z "${TECHNIQUE}" ]; then
    echo "[run.sh] ERROR: Optimal_Selection requires TECHNIQUE=mythril|slither|smartcheck" >&2
    exit 2
  fi
  EXEC_ARGS+=(--technique "${TECHNIQUE}")
fi
python execution.py "${EXEC_ARGS[@]}"
STATUS=$?

echo ""
echo "=================================================================="
echo " Pipeline finished (execution.py exit code: ${STATUS})."
echo "=================================================================="
if [ -d result ]; then
  echo "Result files:"
  find result -type f | sort | sed 's/^/  /'
  echo ""
  echo "----- Per-contract LLM findings (if any) -----"
  find result -type f -name "*gpt_analysis*" 2>/dev/null | sort | while read -r f; do
    echo "### ${f}"
    sed 's/^/    /' "${f}"
  done
  if [ "${ENSEMBLE}" = "Weighted_Integration" ]; then
    WI_DIR="result/WI_${STRATEGY}_${LLM_SUFFIX}"
    echo ""
    echo "----- Weighted Integration verdicts (${WI_DIR}) -----"
    if [ -d "${WI_DIR}" ]; then
      find "${WI_DIR}" -type f -name "*_result.txt" 2>/dev/null | sort | while read -r f; do
        echo "### ${f}"
        sed 's/^/    /' "${f}"
      done
    else
      echo "    (no WI output directory)"
    fi
  elif [ "${ENSEMBLE}" = "Optimal_Selection" ] && [ -n "${TECHNIQUE}" ]; then
    OS_DIR="result/${TECHNIQUE}_${STRATEGY}_${LLM_SUFFIX}"
    echo ""
    echo "----- Optimal Selection: single-technique LLM output (${OS_DIR}) -----"
    if [ -d "${OS_DIR}" ]; then
      find "${OS_DIR}" -type f -name "*_gpt_analysis.txt" 2>/dev/null | sort | while read -r f; do
        echo "### ${f}"
        sed 's/^/    /' "${f}"
      done
    else
      echo "    (no technique output directory)"
    fi
  fi
else
  echo "(no result directory was produced)"
fi
exit ${STATUS}
