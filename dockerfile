# Use Alpine — no perl, smaller attack surface
FROM python:3.12-alpine

# Apply OS-level security patches
RUN apk update && apk upgrade --no-cache

# Create non-root user
RUN adduser -D -u 1000 appuser

# Set working directory
WORKDIR /app

# Copy dependencies first for caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Set ownership and switch to non-root user
RUN chown -R appuser:appuser /app
USER appuser

# Expose Flask port
EXPOSE 5000

# Run the app
CMD ["python", "app.py"]