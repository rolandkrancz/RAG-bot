# Use Python 3.13 slim image
FROM python:3.13-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ ./src/
COPY knowledge-base/ ./knowledge-base/
COPY chainlit.md .
COPY .chainlit/ ./.chainlit/

# Create directory for vector database
RUN mkdir -p /app/vector_db

# Expose Chainlit default port
EXPOSE 8000

# Create startup script that runs document loader then starts the app
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Initializing vector database..."\n\
python src/document_loader.py\n\
echo "Starting Chainlit application..."\n\
chainlit run src/app.py --host 0.0.0.0 --port 8000' > /app/start.sh && \
    chmod +x /app/start.sh

# Set the startup script as entrypoint
CMD ["/app/start.sh"]
