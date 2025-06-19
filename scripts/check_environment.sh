#!/bin/bash

# Check Environment Variables
# This script helps identify and fix environment variable issues

echo "=== Environment Variable Check ==="
echo ""

# Check if .env file exists
if [ -f ".env" ]; then
    echo "✓ .env file exists"
    echo "Current environment variables:"
    cat .env | grep -v "^#" | grep -v "^$" || echo "No environment variables found"
else
    echo "✗ .env file not found"
    echo "Creating .env file with default values..."
    cat > .env << EOF
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=your_secure_password_here
MONGO_DB_NAME=dnd_data
SECRET_KEY=your_secret_key_here
EOF
    echo "✓ Created .env file"
fi

echo ""

# Check if containers are running
echo "Checking container status..."
if docker ps | grep -q dnd_mongo; then
    echo "✓ MongoDB container is running"
else
    echo "✗ MongoDB container is not running"
fi

if docker ps | grep -q dnd_web; then
    echo "✓ Web container is running"
else
    echo "✗ Web container is not running"
fi

echo ""

# Check MongoDB connection from web container
echo "Testing MongoDB connection from web container..."
docker exec dnd_web python -c "
import os
from urllib.parse import quote_plus
from pymongo import MongoClient

mongo_user = os.getenv('MONGO_USER', 'admin')
mongo_pass = os.getenv('MONGO_PASS', 'changeme')
mongo_db = os.getenv('MONGO_DB', 'dnd_monster_data')
mongo_host = os.getenv('MONGO_HOST', 'mongo')
mongo_port = os.getenv('MONGO_PORT', '27017')

encoded_user = quote_plus(mongo_user)
encoded_pass = quote_plus(mongo_pass)

mongo_uri = f'mongodb://{encoded_user}:{encoded_pass}@{mongo_host}:{mongo_port}/'

try:
    client = MongoClient(mongo_uri, serverSelectionTimeoutMS=5000)
    client.admin.command('ping')
    print('✓ MongoDB connection successful')
    print(f'Database: {mongo_db}')
    print(f'Host: {mongo_host}:{mongo_port}')
    print(f'User: {mongo_user}')
except Exception as e:
    print(f'✗ MongoDB connection failed: {str(e)}')
"

echo ""

# Check environment variables in web container
echo "Environment variables in web container:"
docker exec dnd_web env | grep -E "(MONGO|SECRET)" || echo "No MongoDB/Secret environment variables found"

echo ""

# Check MongoDB logs
echo "Recent MongoDB logs:"
docker logs dnd_mongo --tail 10

echo ""

# Check web container logs
echo "Recent web container logs:"
docker logs dnd_web --tail 10

echo ""
echo "=== Environment Check Complete ==="
echo ""
echo "If MongoDB connection is failing:"
echo "1. Check that MONGO_INITDB_ROOT_USERNAME and MONGO_INITDB_ROOT_PASSWORD are set"
echo "2. Make sure the password doesn't contain special characters that need encoding"
echo "3. Verify that MONGO_DB_NAME matches what the app expects"
echo "4. Restart containers after changing environment variables:"
echo "   docker-compose -f docker-compose.prod.yml down"
echo "   docker-compose -f docker-compose.prod.yml up -d" 