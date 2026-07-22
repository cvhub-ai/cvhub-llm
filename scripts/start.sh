#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ENV_FILE:-${PROJECT_ROOT}/.env}"

if [[ -f "${ENV_FILE}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
    set +a
fi

: "${MODEL_DIR:?MODEL_DIR is required}"
: "${MODEL_NAME:?MODEL_NAME is required}"

LLM_HOST="${LLM_HOST:-0.0.0.0}"
LLM_PORT="${LLM_PORT:-8000}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-8192}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.85}"
TENSOR_PARALLEL_SIZE="${TENSOR_PARALLEL_SIZE:-1}"

if [[ ! -d "${MODEL_DIR}" ]]; then
    echo "Error: model directory does not exist: ${MODEL_DIR}" >&2
    exit 1
fi

if [[ ! "${LLM_PORT}" =~ ^[0-9]+$ ]]; then
    echo "Error: LLM_PORT must be an integer: ${LLM_PORT}" >&2
    exit 1
fi

if [[ ! "${TENSOR_PARALLEL_SIZE}" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: TENSOR_PARALLEL_SIZE must be a positive integer." >&2
    exit 1
fi

VLLM_ARGS=(
    "serve"
    "${MODEL_DIR}"
    "--served-model-name"
    "${MODEL_NAME}"
    "--host"
    "${LLM_HOST}"
    "--port"
    "${LLM_PORT}"
    "--max-model-len"
    "${MAX_MODEL_LEN}"
    "--gpu-memory-utilization"
    "${GPU_MEMORY_UTILIZATION}"
    "--tensor-parallel-size"
    "${TENSOR_PARALLEL_SIZE}"
)

if [[ -n "${LLM_API_KEY:-}" ]]; then
    VLLM_ARGS+=(
        "--api-key"
        "${LLM_API_KEY}"
    )
else
    echo "Warning: LLM_API_KEY is empty; API authentication is disabled." >&2
fi

echo "Starting vLLM service..."
echo "Model directory: ${MODEL_DIR}"
echo "Served model name: ${MODEL_NAME}"
echo "Listen address: ${LLM_HOST}:${LLM_PORT}"
echo "Tensor parallel size: ${TENSOR_PARALLEL_SIZE}"

export VLLM_USE_V2_MODEL_RUNNER=0   

# Docker official image or a standard vLLM environment
if command -v vllm >/dev/null 2>&1; then
    exec vllm "${VLLM_ARGS[@]}"
fi

if command -v uv >/dev/null 2>&1; then
    exec uv run vllm "${VLLM_ARGS[@]}"
fi

echo "Error: neither 'vllm' nor 'uv' was found." >&2
exit 127