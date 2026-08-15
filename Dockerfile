FROM vllm/vllm-openai:v0.5.1

ENV HF_HOME=/app/.cache/huggingface

RUN useradd -ms /bin/bash appuser

WORKDIR /app

RUN mkdir -p /app/.cache && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["--model","TheBloke/TinyLlama-1.1B-Chat-v1.0-AWQ","--quantization","awq","--max-model-len","2048","--gpu-memory-utilization","0.85","--host","0.0.0.0","--port","8000"]
