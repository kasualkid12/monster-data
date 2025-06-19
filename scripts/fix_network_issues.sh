#!/bin/bash

# Fix Network Issues for Docker
# This script helps resolve network connectivity issues that prevent Docker from accessing the internet

echo "=== Fixing Docker Network Issues ==="
echo ""

# Check current Docker network configuration
echo "1. Checking Docker network configuration..."
docker network ls
echo ""

# Check DNS resolution
echo "2. Testing DNS resolution from host..."
nslookup pypi.org
echo ""

# Check DNS resolution from Docker
echo "3. Testing DNS resolution from Docker..."
docker run --rm alpine nslookup pypi.org
echo ""

# Check if Docker daemon has internet access
echo "4. Testing Docker daemon internet access..."
docker run --rm alpine ping -c 3 8.8.8.8
echo ""

# Check Docker daemon configuration
echo "5. Checking Docker daemon configuration..."
sudo systemctl status docker
echo ""

# Check if Docker daemon has custom DNS
echo "6. Checking Docker daemon DNS configuration..."
if [ -f "/etc/docker/daemon.json" ]; then
    echo "Docker daemon configuration found:"
    cat /etc/docker/daemon.json
else
    echo "No custom Docker daemon configuration found"
fi
echo ""

# Try to fix DNS issues
echo "7. Attempting to fix DNS issues..."

# Create Docker daemon configuration with Google DNS
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
    "dns": ["8.8.8.8", "8.8.4.4"],
    "mtu": 1400
}
EOF

echo "✓ Created Docker daemon configuration with Google DNS"
echo ""

# Restart Docker daemon
echo "8. Restarting Docker daemon..."
sudo systemctl restart docker
sleep 5

# Test again
echo "9. Testing DNS resolution after restart..."
docker run --rm alpine nslookup pypi.org
echo ""

# Test pip install in a container
echo "10. Testing pip install in a container..."
docker run --rm python:3.13-slim pip install --no-cache-dir flask
echo ""

echo "=== Network Fix Complete ==="
echo ""
echo "If the issue persists, try:"
echo "1. Check your firewall settings"
echo "2. Check your VPN configuration"
echo "3. Try building with: docker build --network host ."
echo "4. Check if your ISP is blocking Docker Hub" 