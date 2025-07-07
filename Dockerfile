# Use Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install dependencies with offline-first approach and fallback strategies
RUN pip install --no-cache-dir \
    --index-url https://pypi.org/simple/ \
    --trusted-host pypi.org \
    --trusted-host pypi.python.org \
    --trusted-host files.pythonhosted.org \
    --timeout 60 \
    --retries 5 \
    -r requirements.txt

# Copy the rest of the application
COPY . .

# Make startup script executable
RUN chmod +x start.sh

# Expose the port the app runs on
EXPOSE 5000

# Command to run the application
CMD ["./start.sh"]
