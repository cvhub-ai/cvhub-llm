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

LLM_PORT="${LLM_PORT:-8000}"

# The service listens on 0.0.0.0.
# The health check runs inside the container and therefore uses 127.0.0.1.
HEALTHCHECK_HOST="${HEALTHCHECK_HOST:-127.0.0.1}"
HEALTHCHECK_TIMEOUT="${HEALTHCHECK_TIMEOUT:-5}"

HEALTHCHECK_URL="http://${HEALTHCHECK_HOST}:${LLM_PORT}/health"

export HEALTHCHECK_URL
export HEALTHCHECK_TIMEOUT

python - <<'PY'
import os
import sys
import urllib.error
import urllib.request

url = os.environ["HEALTHCHECK_URL"]
timeout = float(os.environ["HEALTHCHECK_TIMEOUT"])

try:
    with urllib.request.urlopen(url, timeout=timeout) as response:
        status = response.status

    if 200 <= status < 300:
        print(f"Healthy: {url}")
        sys.exit(0)

    print(f"Unhealthy: {url} returned HTTP {status}", file=sys.stderr)
    sys.exit(1)

except urllib.error.HTTPError as exc:
    print(
        f"Unhealthy: {url} returned HTTP {exc.code}",
        file=sys.stderr,
    )
    sys.exit(1)

except (urllib.error.URLError, TimeoutError, OSError) as exc:
    print(
        f"Unhealthy: cannot reach {url}: {exc}",
        file=sys.stderr,
    )
    sys.exit(1)
PY