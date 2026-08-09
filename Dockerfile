# ---------- STAGE 1: Builder ----------
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .

RUN python3 -m pip install --upgrade pip

RUN python3 -m pip install \
    --no-cache-dir \
    -r requirements.txt

# ---------- STAGE 2: Runtime ----------
FROM nvidia/cuda:12.1.1-base-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Run as non-root
RUN useradd -m -u 1000 appuser

WORKDIR /app

# Copy Python libraries
COPY --from=builder /usr/local/lib/python3.10/ /usr/local/lib/python3.10/

# Copy pip-installed executables
COPY --from=builder /usr/local/bin/ /usr/local/bin/

USER appuser

EXPOSE 8000

CMD ["python3", "-m", "vllm.entrypoints.openai.api_server", \
     "--model", "TheBloke/Meta-Llama-3-8B-Instruct-AWQ", \
     "--quantization", "awq", \
     "--max-model-len", "4096", \
     "--gpu-memory-utilization", "0.9", \
     "--host", "0.0.0.0", \
     "--port", "8000"]
