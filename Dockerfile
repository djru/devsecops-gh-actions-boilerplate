# ==========================================
# Stage 1: Build and dependency compilation
# ==========================================
FROM python:3.11-slim-bookworm AS builder

# Install uv directly via its official installer
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Enable bytecode compilation for faster application container startup times
ENV UV_COMPILE_BYTECODE=1

# Copy only the configuration layout first to maximize Docker layer caching
COPY pyproject.toml uv.lock ./

RUN uv sync --frozen --no-install-project --no-dev

# Copy the actual application source code
COPY app/ ./app


# ==========================================
# Stage 2: Hardened Runtime Environment
# ==========================================
FROM python:3.11-slim-bookworm AS runtime

WORKDIR /app

# Install curl cleanly for the container HEALTHCHECK, then purge apt cache to keep image slim
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Create a dedicated, unprivileged system user and group
RUN groupadd -r appgroup && useradd -r -g appgroup -s /sbin/nologin appuser

# Copy the virtual environment from the builder stage
COPY --from=builder /app/.venv /app/.venv
COPY app/ ./app

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

# Implement a container native health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Execute the application
CMD ["python", "main.py"]