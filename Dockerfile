# Use Python 3.11 slim image (more stable)
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install dependencies with better network handling and DNS configuration
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf && \
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf && \
    pip install --no-cache-dir --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --timeout 60 -r requirements.txt

# Copy the rest of the application
COPY . .

# Expose the port the app runs on
EXPOSE 5000

# Command to run the application
CMD ["python", "app.py"]
