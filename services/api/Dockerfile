# ─── Stage 1: Builder ────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

# Install dependencies in isolated layer
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


###─── Stage 2: Production Image ───────────────────────────────────────────────
FROM python:3.11-slim AS production

# Security: create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy only installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY --chown=appuser:appuser . .

# Drop to non-root
USER appuser

# Expose port
EXPOSE 8000

# Health check — Kubernetes will also do this, but good practice in image itself
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"


# Run with uvicorn — single worker for container (Kubernetes handles scaling)
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]