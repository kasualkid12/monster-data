#!/bin/bash

# Check Web App Accessibility
# This script helps troubleshoot why the web app isn't accessible

echo "=== Web App Accessibility Check ==="
echo ""

# Check if containers are running
echo "1. Checking container status..."
docker ps --filter "name=dnd_"
echo ""

# Check container logs
echo "2. Checking web container logs..."
docker logs dnd_web --tail 20
echo ""

# Check if the app is listening on the port
echo "3. Checking if app is listening on port 5000..."
docker exec dnd_web netstat -tlnp | grep :5000 || echo "No process listening on port 5000"
echo ""

# Check from inside the container
echo "4. Testing web app from inside container..."
docker exec dnd_web curl -s http://localhost:5000 || echo "Web app not responding inside container"
echo ""

# Check from host
echo "5. Testing web app from host..."
curl -s http://localhost:5000 || echo "Web app not accessible from host"
echo ""

# Check firewall status
echo "6. Checking firewall status..."
sudo ufw status
echo ""

# Check what's listening on port 5000
echo "7. Checking what's listening on port 5000..."
sudo netstat -tlnp | grep :5000
echo ""

# Check Docker network configuration
echo "8. Checking Docker networks..."
docker network ls
docker network inspect monster-data_frontend
echo ""

echo "=== Common Issues and Solutions ==="
echo ""
echo "If containers are running but web app isn't accessible:"
echo "1. Check if the app is bound to 0.0.0.0 instead of 127.0.0.1"
echo "2. Check if firewall is blocking port 5000"
echo "3. Check if the app is actually starting properly"
echo "4. Check if MongoDB connection is working"
echo ""
echo "To fix port binding issue, update docker-compose.prod.yml:"
echo "  ports:"
echo "    - '0.0.0.0:5000:5000'  # Allow external access"
echo ""
echo "To check app configuration, look at app.py to see how Flask is configured." 