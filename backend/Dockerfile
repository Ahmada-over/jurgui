FROM python:3.13-slim

WORKDIR /app

# Install system dependencies for asyncpg / psycopg
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy and install python dependencies (cached layer)
COPY backend/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir gunicorn

# Copy backend application
COPY backend/app /app/app

# Create non-root user for security
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Cloud Run injects PORT (default 8080), we honour it
ENV PORT=8080
EXPOSE ${PORT}

# Production: gunicorn with uvicorn workers
# Cloud Run sends SIGTERM for graceful shutdown (--timeout 0 = no worker timeout)
CMD exec gunicorn app.main:app \
    --bind 0.0.0.0:${PORT} \
    --worker-class uvicorn.workers.UvicornWorker \
    --workers 1 \
    --threads 8 \
    --timeout 0 \
    --access-logfile - \
    --error-logfile -
