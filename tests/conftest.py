from __future__ import annotations

import os
from collections.abc import Iterator
from pathlib import Path

import httpx
import pytest


PROJECT_ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = PROJECT_ROOT / ".env"


def load_env_file(path: Path) -> None:
    """Load simple KEY=VALUE entries without overriding existing variables."""
    if not path.is_file():
        return

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()

        if not line or line.startswith("#") or "=" not in line:
            continue

        key, value = line.split("=", maxsplit=1)
        key = key.strip()
        value = value.strip().strip("'\"")

        if key:
            os.environ.setdefault(key, value)


load_env_file(ENV_FILE)


@pytest.fixture(scope="session")
def base_url() -> str:
    host = os.getenv("TEST_LLM_HOST", "127.0.0.1")
    port = os.getenv("LLM_PORT", "8000")

    return f"http://{host}:{port}"


@pytest.fixture(scope="session")
def model_name() -> str:
    value = os.getenv("MODEL_NAME")

    if not value:
        pytest.fail("MODEL_NAME is not configured.")

    return value


@pytest.fixture(scope="session")
def api_key() -> str | None:
    return os.getenv("LLM_API_KEY") or None


@pytest.fixture(scope="session")
def auth_headers(api_key: str | None) -> dict[str, str]:
    if not api_key:
        return {}

    return {
        "Authorization": f"Bearer {api_key}",
    }


@pytest.fixture(scope="session")
def client(
    base_url: str,
    auth_headers: dict[str, str],
) -> Iterator[httpx.Client]:
    with httpx.Client(
        base_url=base_url,
        headers=auth_headers,
        timeout=httpx.Timeout(120.0, connect=10.0),
    ) as http_client:
        yield http_client