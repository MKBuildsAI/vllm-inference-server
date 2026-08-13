# ---------- STAGE 1: Builder ----------
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
	python3-distutils \
        git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create a self-contained virtual environment
RUN python3 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip

COPY requirements.txt .

# Install dependencies, pulling PyTorch specifically from the CUDA 12.1 wheel index
RUN pip install --no-cache-dir -r requirements.txt \
    --extra-index-url https://download.pytorch.org/whl/cu121


# ---------- STAGE 2: Runtime ----------
FROM nvidia/cuda:12.1.1-base-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PATH="/app/venv/bin:$PATH" \
    HF_HOME="/app/.cache/huggingface"

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
	python3-distutils \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with home directory
RUN useradd -ms /bin/bash appuser

WORKDIR /app

# Copy the pre-built virtual environment from builder
COPY --from=builder /app/venv /app/venv

# Create cache directory and grant ownership to non-root user
RUN mkdir -p /app/.cache && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["python3", "-m", "vllm.entrypoints.openai.api_server", \
     "--model", "TheBloke/TinyLlama-1.1B-Chat-v1.0-AWQ", \
     "--quantization", "awq", \
     "--max-model-len", "2048", \
     "--gpu-memory-utilization", "0.85", \
     "--host", "0.0.0.0", \
     "--port", "8000"]
