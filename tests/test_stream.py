from __future__ import annotations

import json

import httpx


def test_streaming_chat_completion(
    client: httpx.Client,
    model_name: str,
) -> None:
    request_body = {
        "model": model_name,
        "messages": [
            {
                "role": "user",
                "content": "Briefly introduce vLLM in one sentence.",
            }
        ],
        "temperature": 0.0,
        "max_tokens": 128,
        "stream": True,
    }

    received_chunks = 0
    received_done_event = False
    generated_text_parts: list[str] = []
    reasoning_text_parts: list[str] = []

    with client.stream(
        "POST",
        "/v1/chat/completions",
        json=request_body,
    ) as response:
        assert response.status_code == 200, (
            f"Streaming request failed: "
            f"status={response.status_code}, "
            f"body={response.read().decode(errors='replace')}"
        )

        content_type = response.headers.get("content-type", "")

        assert "text/event-stream" in content_type

        for line in response.iter_lines():
            line = line.strip()

            if not line or not line.startswith("data:"):
                continue

            data = line.removeprefix("data:").strip()

            if data == "[DONE]":
                received_done_event = True
                break

            chunk = json.loads(data)
            received_chunks += 1

            choices = chunk.get("choices", [])

            if not choices:
                continue

            delta = choices[0].get("delta", {})

            content = delta.get("content")

            if content:
                generated_text_parts.append(content)

            # Some reasoning models expose this vLLM extension.
            reasoning_content = delta.get("reasoning_content")

            if reasoning_content:
                reasoning_text_parts.append(reasoning_content)

    generated_text = "".join(generated_text_parts).strip()
    reasoning_text = "".join(reasoning_text_parts).strip()

    assert received_chunks > 0, "No streaming chunks were received."
    assert received_done_event, "The stream did not return a [DONE] event."
    assert generated_text or reasoning_text, (
        "The stream returned neither content nor reasoning content."
    )