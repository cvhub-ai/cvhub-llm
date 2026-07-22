import httpx


def test_health_endpoint(base_url: str) -> None:
    response = httpx.get(
        f"{base_url}/health",
        timeout=10.0,
    )

    assert response.status_code == 200, (
        f"Health check failed: "
        f"status={response.status_code}, body={response.text}"
    )