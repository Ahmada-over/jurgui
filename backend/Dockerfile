FROM python:3.13-slim

WORKDIR /app

# Copy and install python dependencies (cached layer)
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy backend application
COPY app /app/app

# Create non-root user for security
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Cloud Run injects PORT (default 8080)
ENV PORT=8080
EXPOSE 8080

# Production: gunicorn with uvicorn workers
CMD ["sh", "-c", "exec gunicorn app.main:app --bind 0.0.0.0:${PORT:-8080} --worker-class uvicorn.workers.UvicornWorker --workers 1 --threads 8 --timeout 0 --access-logfile - --error-logfile -"]
