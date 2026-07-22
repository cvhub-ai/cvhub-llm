import httpx


def test_models_endpoint(
    client: httpx.Client,
    model_name: str,
) -> None:
    response = client.get("/v1/models")

    assert response.status_code == 200, (
        f"Models request failed: "
        f"status={response.status_code}, body={response.text}"
    )

    payload = response.json()

    assert payload.get("object") == "list"
    assert isinstance(payload.get("data"), list)
    assert payload["data"], "No models were returned by the service."

    returned_model_names = {
        model.get("id")
        for model in payload["data"]
        if isinstance(model, dict)
    }

    assert model_name in returned_model_names, (
        f"Expected model {model_name!r}, "
        f"but received {sorted(returned_model_names)!r}." # type: ignore
    )