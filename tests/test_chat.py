import httpx


def test_chat_completion(
    client: httpx.Client,
    model_name: str,
) -> None:
    request_body = {
        "model": model_name,
        "messages": [
            {
                "role": "system",
                "content": "You are a concise and helpful assistant.",
            },
            {
                "role": "user",
                "content": "Reply with exactly one short sentence in Chinese.",
            },
        ],
        "temperature": 0.0,
        "max_tokens": 128,
        "stream": False,
    }

    response = client.post(
        "/v1/chat/completions",
        json=request_body,
    )

    assert response.status_code == 200, (
        f"Chat completion failed: "
        f"status={response.status_code}, body={response.text}"
    )

    payload = response.json()

    assert payload.get("object") == "chat.completion"
    assert payload.get("model")
    assert isinstance(payload.get("choices"), list)
    assert payload["choices"], "The response contains no choices."

    first_choice = payload["choices"][0]

    assert first_choice.get("finish_reason") is not None

    message = first_choice.get("message")

    assert isinstance(message, dict)
    assert message.get("role") == "assistant"

    content = message.get("content")

    assert isinstance(content, str)
    assert content.strip(), "The model returned empty content."

    usage = payload.get("usage")

    if usage is not None:
        assert usage.get("prompt_tokens", 0) > 0
        assert usage.get("completion_tokens", 0) > 0
        assert usage.get("total_tokens", 0) > 0