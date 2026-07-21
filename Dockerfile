# ELSA artifact container.
#
# Runs the REAL pipeline (execution.py) on a small, self-contained 3-contract
# subset of ZKP_contract so evaluators can exercise the artifact end-to-end with
# a single command and no manual tool installation.
#
# Bundled analyzers: solc 0.8.0 + Slither (always), Mythril and SmartCheck
# (best-effort). Together these cover ZKP_contract's full mythril+slither+smartcheck
# ensemble; any best-effort analyzer that fails to install is skipped gracefully.
#
# LLM stages need credentials. Either bring an OpenAI key:
#     docker run --rm -e OPENAI_API_KEY=sk-... elsa
# or point at a free / open OpenAI-compatible endpoint (no source edits needed):
#     docker run --rm \
#        -e OPENAI_API_BASE=https://api.groq.com/openai/v1 \
#        -e OPENAI_API_KEY=gsk_... \
#        -e OPENAI_MODEL=llama-3.1-8b-instant elsa
FROM python:3.10-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# build-essential: lets heavier analyzers (Mythril) build any dependency that
# lacks a prebuilt wheel. ca-certificates: TLS for solc-select downloads.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /elsa

# --- Core Python dependencies (own layer for caching) ----------------------
# Mirrors requirements.txt except: solc-select provides the solc binary and
# Mythril is installed separately (best-effort) so a flaky build never blocks.
COPY requirements.txt ./
RUN pip install --upgrade pip \
    && pip install --prefer-binary --retries 5 --timeout 180 \
        "openai==0.28.0" "python-dotenv>=1.0.0" "slither-analyzer>=0.9.0" solc-select

# solc 0.8.0 matches the bundled ZKP_contract subset (pragma ^0.8.0).
RUN solc-select install 0.8.0 && solc-select use 0.8.0

# --- Optional analyzers (best-effort; pipeline degrades gracefully) --------
RUN pip install --prefer-binary --retries 5 --timeout 600 "mythril>=0.23.0" \
    || echo "WARNING: mythril not installed -> mythril technique will be skipped"

# SmartCheck (Java-backed npm CLI) completes ZKP_contract's 3-technique ensemble.
# Its JAR targets Java 8 (uses JAXB, removed from JDK 11+), so install a Temurin 8
# JRE. Best-effort: if any step fails, the smartcheck technique degrades gracefully.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl gnupg ca-certificates tar gzip \
    && mkdir -p /opt/java8 \
    && curl -fsSL "https://api.adoptium.net/v3/binary/latest/8/ga/linux/x64/jre/hotspot/normal/eclipse" \
       | tar -xz -C /opt/java8 --strip-components=1 \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g @smartdec/smartcheck \
    && rm -rf /var/lib/apt/lists/* \
    || echo "WARNING: smartcheck not installed -> smartcheck technique will be skipped"
# SmartCheck's JAR needs Java 8 on PATH (JAXB). Other tools are unaffected.
ENV PATH="/opt/java8/bin:${PATH}"
# Silence Node's circular-dependency warnings from SmartCheck's bundled shelljs,
# so they don't pollute the smartcheck tool-analysis output (analysis unaffected).
ENV NODE_NO_WARNINGS=1

# --- Artifact code ---------------------------------------------------------
COPY . .
# Normalize the entrypoint's line endings in case of a CRLF checkout on Windows.
RUN sed -i 's/\r$//' docker/run.sh

ENTRYPOINT ["bash", "docker/run.sh"]
