#!/bin/bash

# Test Web App Accessibility
# This script tests if the web app is accessible after configuration changes

echo "=== Testing Web App Accessibility ==="
echo ""

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Server IP: $SERVER_IP"
echo ""

# Check if containers are running
echo "1. Checking container status..."
if docker ps | grep -q dnd_web; then
    echo "✓ Web container is running"
else
    echo "✗ Web container is not running"
    exit 1
fi

# Check if MongoDB container is running
if docker ps | grep -q dnd_mongo; then
    echo "✓ MongoDB container is running"
else
    echo "✗ MongoDB container is not running"
fi

echo ""

# Test localhost access
echo "2. Testing localhost access..."
if curl -s http://localhost:5000 > /dev/null; then
    echo "✓ Web app accessible on localhost:5000"
else
    echo "✗ Web app not accessible on localhost:5000"
fi

echo ""

# Test external IP access
echo "3. Testing external IP access..."
if curl -s http://$SERVER_IP:5000 > /dev/null; then
    echo "✓ Web app accessible on $SERVER_IP:5000"
else
    echo "✗ Web app not accessible on $SERVER_IP:5000"
fi

echo ""

# Check firewall status
echo "4. Checking firewall status..."
if sudo ufw status | grep -q "Status: active"; then
    echo "Firewall is active"
    if sudo ufw status | grep -q "5000"; then
        echo "✓ Port 5000 is allowed in firewall"
    else
        echo "✗ Port 5000 is not allowed in firewall"
        echo "To allow port 5000: sudo ufw allow 5000"
    fi
else
    echo "Firewall is inactive"
fi

echo ""

# Show container logs if there are issues
echo "5. Recent web container logs:"
docker logs dnd_web --tail 10

echo ""
echo "=== Test Complete ==="
echo ""
echo "If the web app is accessible on localhost but not external IP:"
echo "1. Check firewall settings: sudo ufw allow 5000"
echo "2. Check if your VPN is blocking external access"
echo "3. Try accessing from a different network"
echo ""
echo "Your web app should be accessible at:"
echo "  - Local: http://localhost:5000"
echo "  - External: http://$SERVER_IP:5000" 