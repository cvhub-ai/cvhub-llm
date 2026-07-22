# Pin this version in production instead of using "latest".
ARG VLLM_VERSION=latest

FROM vllm/vllm-openai:${VLLM_VERSION}

WORKDIR /app

COPY scripts/start.sh /app/scripts/start.sh
COPY scripts/healthcheck.sh /app/scripts/healthcheck.sh

RUN chmod +x \
    /app/scripts/start.sh \
    /app/scripts/healthcheck.sh

EXPOSE 8000

HEALTHCHECK \
    --interval=30s \
    --timeout=10s \
    --start-period=300s \
    --retries=3 \
    CMD ["/app/scripts/healthcheck.sh"]

ENTRYPOINT ["/app/scripts/start.sh"]