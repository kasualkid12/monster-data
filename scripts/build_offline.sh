#!/bin/bash

# Offline Docker Build Script
# This script helps build the Docker image when there are network connectivity issues

echo "=== Offline Docker Build Script ==="
echo ""

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    echo "ERROR: Dockerfile not found. Please run this script from the project directory."
    exit 1
fi

# Create a temporary requirements file with exact versions
echo "1. Creating exact version requirements..."
pip download --no-deps --dest ./packages flask pymongo python-dotenv
echo "✓ Downloaded packages to ./packages directory"
echo ""

# Create a new Dockerfile for offline build
echo "2. Creating offline Dockerfile..."
cat > Dockerfile.offline << 'EOF'
# Use Python 3.13 slim image
FROM python:3.13-slim

# Set working directory
WORKDIR /app

# Copy downloaded packages
COPY packages/ /tmp/packages/

# Install packages from local files
RUN pip install --no-index --find-links /tmp/packages flask pymongo python-dotenv

# Copy the rest of the application
COPY . .

# Expose the port the app runs on
EXPOSE 5000

# Command to run the application
CMD ["python", "app.py"]
EOF

echo "✓ Created Dockerfile.offline"
echo ""

# Build using the offline Dockerfile
echo "3. Building Docker image offline..."
docker build -f Dockerfile.offline -t monster-data:offline .

if [ $? -eq 0 ]; then
    echo "✓ Docker image built successfully!"
    echo ""
    echo "4. Updating docker-compose to use the offline image..."
    
    # Create a temporary docker-compose file
    cat > docker-compose.offline.yml << EOF
version: '3.8'

services:
  mongo:
    image: mongo:latest
    container_name: dnd_mongo
    restart: unless-stopped
    environment:
      - MONGO_INITDB_ROOT_USERNAME=\${MONGO_INITDB_ROOT_USERNAME}
      - MONGO_INITDB_ROOT_PASSWORD=\${MONGO_INITDB_ROOT_PASSWORD}
      - MONGO_INITDB_DATABASE=\${MONGO_DB_NAME}
    ports:
      - '127.0.0.1:27017:27017'
    volumes:
      - mongo_data:/data/db
      - ./mongo-init.js:/docker-entrypoint-initdb.d/mongo-init.js:ro
    networks:
      - backend
    security_opt:
      - no-new-privileges:true
    ulimits:
      nproc: 65535
      nofile:
        soft: 20000
        hard: 40000

  web:
    image: monster-data:offline
    container_name: dnd_web
    restart: unless-stopped
    ports:
      - '127.0.0.1:5000:5000'
    environment:
      - MONGO_USER=\${MONGO_INITDB_ROOT_USERNAME}
      - MONGO_PASS=\${MONGO_INITDB_ROOT_PASSWORD}
      - MONGO_DB=\${MONGO_DB_NAME}
      - MONGO_HOST=mongo
      - MONGO_PORT=27017
      - FLASK_ENV=production
      - SECRET_KEY=\${SECRET_KEY}
    volumes:
      - ./logs:/app/logs
    networks:
      - backend
      - frontend
    security_opt:
      - no-new-privileges:true
    ulimits:
      nproc: 65535
      nofile:
        soft: 20000
        hard: 40000
    depends_on:
      - mongo

networks:
  backend:
    internal: true
  frontend:

volumes:
  mongo_data:
    driver: local
EOF

    echo "✓ Created docker-compose.offline.yml"
    echo ""
    echo "5. Starting containers with offline build..."
    docker-compose -f docker-compose.offline.yml up -d
    
    if [ $? -eq 0 ]; then
        echo "✓ Containers started successfully!"
        echo ""
        echo "Your application should now be running at http://localhost:5000"
    else
        echo "✗ Failed to start containers"
    fi
else
    echo "✗ Failed to build Docker image"
fi

# Cleanup
echo ""
echo "6. Cleaning up temporary files..."
rm -rf ./packages
rm -f Dockerfile.offline
echo "✓ Cleanup complete" 