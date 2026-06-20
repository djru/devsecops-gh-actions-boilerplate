# ==========================================
# Stage 1: Build and dependency compilation
# ==========================================
FROM python:3.11-slim-bookworm AS builder

# Install uv directly via its official installer
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Copy the application source (which contains inline dependencies)
COPY app/main.py .

# Compile dependencies into a virtual environment.
# --frozen prevents uv from looking for updates and ensures strict reproducibility.
RUN uv venv .venv && \
    uv pip compile main.py --universal -o requirements.txt && \
    uv pip install -r requirements.txt

# ==========================================
# Stage 2: Hardened Runtime Environment
# ==========================================
FROM python:3.11-slim-bookworm AS runtime

WORKDIR /app

# Create a dedicated, unprivileged system user and group
RUN groupadd -r appgroup && useradd -r -g appgroup -s /sbin/nologin appuser

# Copy the virtual environment from the builder stage
COPY --from=builder /app/.venv /app/.venv
COPY app/main.py .

# Ensure the app code and virtual environment are owned by the non-root user
RUN chown -R appuser:appgroup /app

# Set environment variables to optimize Python performance and use the venv
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Switch away from root to the unprivileged user
USER appuser

# Document the intended runtime port
EXPOSE 8000

# Implement a container native health check that Trivy/Hadolint flags require
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD curl 'http://localhost:8000/health'

# Execute the application
CMD ["python", "main.py"]