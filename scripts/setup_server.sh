#!/bin/bash

# Server Setup Script for Monster Data
# This script prepares the Ubuntu server for deployment

set -e

echo "=== Setting up Ubuntu Server for Monster Data ==="

# Get the username from command line or default to kasu
USERNAME=${1:-kasu}
PROJECT_DIR="/home/$USERNAME/monster-data"
BACKUP_DIR="$PROJECT_DIR/backup"

echo "Setting up for user: $USERNAME"
echo "Project directory: $PROJECT_DIR"
echo "Backup directory: $BACKUP_DIR"

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USERNAME
    rm get-docker.sh
else
    echo "Docker already installed"
fi

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose already installed"
fi

# Create project directory
echo "Creating project directory..."
sudo mkdir -p $PROJECT_DIR
sudo chown $USERNAME:$USERNAME $PROJECT_DIR

# Create backup directory within project directory
echo "Creating backup directory..."
sudo mkdir -p $BACKUP_DIR
sudo chown $USERNAME:$USERNAME $BACKUP_DIR

# Create logs directory
echo "Creating logs directory..."
sudo mkdir -p $PROJECT_DIR/logs
sudo chown $USERNAME:$USERNAME $PROJECT_DIR/logs

# Set up environment file
echo "Creating environment file..."
cat > $PROJECT_DIR/.env << EOF
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=your_secure_password_here
MONGO_DB_NAME=dnd_data
SECRET_KEY=your_secret_key_here
EOF

sudo chown $USERNAME:$USERNAME $PROJECT_DIR/.env
chmod 600 $PROJECT_DIR/.env

# Create systemd service for auto-start
echo "Creating systemd service..."
sudo tee /etc/systemd/system/monster-data.service > /dev/null << EOF
[Unit]
Description=Monster Data Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
User=$USERNAME
Group=$USERNAME

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable monster-data.service

# Set up log rotation
echo "Setting up log rotation..."
sudo tee /etc/logrotate.d/monster-data > /dev/null << EOF
$PROJECT_DIR/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USERNAME $USERNAME
    postrotate
        systemctl reload monster-data.service
    endscript
}
EOF

# Create deployment script
echo "Creating deployment script..."
cat > $PROJECT_DIR/deploy.sh << 'EOF'
#!/bin/bash

set -e

echo "=== Starting Deployment ==="

# Create backup
echo "Creating backup of MongoDB data..."
docker exec dnd_mongo mongodump --out /backup/$(date +%Y%m%d_%H%M%S) || echo "Backup failed, continuing..."

# Pull latest changes
echo "Pulling latest changes..."
git pull origin main

# Update containers
echo "Updating containers..."
docker-compose -f docker-compose.prod.yml up -d --build

# Clean up old backups (keeping last 5)
echo "Cleaning up old backups (keeping last 5)..."
ls -t ./backup | tail -n +6 | xargs -I {} rm -rf ./backup/{} 2>/dev/null || true

# Prune unused Docker images
echo "Pruning unused Docker images..."
docker image prune -f

echo "=== Deployment Complete ==="
EOF

chmod +x $PROJECT_DIR/deploy.sh

# Set proper permissions
echo "Setting proper permissions..."
sudo chown -R $USERNAME:$USERNAME $PROJECT_DIR

# Add user to docker group (requires logout/login to take effect)
echo "Adding user to docker group..."
sudo usermod -aG docker $USERNAME

echo ""
echo "=== Server Setup Complete ==="
echo ""
echo "IMPORTANT: You need to log out and log back in for Docker permissions to take effect."
echo "Or run: newgrp docker"
echo ""
echo "Next steps:"
echo "1. Log out and log back in (or run 'newgrp docker')"
echo "2. Clone your repository to $PROJECT_DIR"
echo "3. Update the .env file with your actual passwords"
echo "4. Test the deployment with: cd $PROJECT_DIR && ./deploy.sh"
echo ""
echo "GitHub Actions will use:"
echo "- SSH_HOST: $(hostname -I | awk '{print $1}')"
echo "- SSH_USER: $USERNAME"
echo "- Project directory: $PROJECT_DIR"
echo "- Backup directory: $BACKUP_DIR" 