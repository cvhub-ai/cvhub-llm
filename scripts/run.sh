#!/usr/bin/env bash

export VLLM_USE_V2_MODEL_RUNNER=0

uv run vllm serve ./models/Qwen3-4B-Instruct-2507 \
  --served-model-name qwen3-4b \
  --host 0.0.0.0 \
  --port 8000 \
  --gpu-memory-utilization 0.85 \
  --max-model-len 4096