# Multi-stage Docker build for Inference Container

# Build stage
FROM python:3.11-slim AS builder

RUN apt-get update && apt-get install -y gcc g++ make libgomp1 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim

RUN apt-get update && apt-get install -y libgomp1 && rm -rf /var/lib/apt/lists/*

RUN groupadd -r mluser && useradd -r -g mluser mluser

WORKDIR /app

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

COPY predict.py .
COPY utils/ utils/

RUN chown -R mluser:mluser /app

USER mluser

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD python --version || exit 1

CMD ["python", "predict.py"]

