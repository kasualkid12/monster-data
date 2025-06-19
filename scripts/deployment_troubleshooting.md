# Deployment Troubleshooting Guide

## Network Connectivity Issues

If you're experiencing DNS resolution failures during Docker build, try these solutions in order:

### 1. Quick Fix - Run Network Fix Script

```bash
chmod +x scripts/fix_network_issues.sh
./scripts/fix_network_issues.sh
```

### 2. Manual DNS Configuration

```bash
# Create Docker daemon configuration
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
    "dns": ["8.8.8.8", "8.8.4.4", "1.1.1.1"],
    "mtu": 1400
}
EOF

# Restart Docker
sudo systemctl restart docker
```

### 3. Build with Host Network

```bash
cd /home/your-username/monster-data
docker-compose -f docker-compose.prod.yml build --network host
docker-compose -f docker-compose.prod.yml up -d
```

### 4. Offline Build (Last Resort)

```bash
chmod +x scripts/build_offline.sh
./scripts/build_offline.sh
```

### 5. Check VPN/Firewall Settings

- Ensure Docker containers can access the internet through your Firewalla VPN
- Check if your VPN is blocking Docker traffic
- Try temporarily disabling VPN to test

### 6. Alternative Base Image

If Python 3.11 still fails, try:

```bash
# Edit Dockerfile to use a different base image
# FROM python:3.9-slim
# FROM ubuntu:20.04
```

## Common Error Messages

### "Temporary failure in name resolution"

- **Cause**: DNS resolution failure
- **Solution**: Use network fix script or build with host network

### "No matching distribution found"

- **Cause**: Can't reach PyPI servers
- **Solution**: Use offline build or check network connectivity

### "Connection timeout"

- **Cause**: Network connectivity issues
- **Solution**: Check firewall/VPN settings

## Testing Network Connectivity

```bash
# Test DNS from host
nslookup pypi.org

# Test DNS from Docker
docker run --rm alpine nslookup pypi.org

# Test internet access
docker run --rm alpine ping -c 3 8.8.8.8

# Test pip install in container
docker run --rm python:3.11-slim pip install flask
```

## Environment Variables

Make sure your `.env` file exists and contains:

```bash
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=your_secure_password_here
MONGO_DB_NAME=dnd_data
SECRET_KEY=your_secret_key_here
```

## Manual Deployment Steps

If automated deployment fails:

1. **SSH into your server**
2. **Navigate to project directory**

   ```bash
   cd /home/your-username/monster-data
   ```

3. **Try different build methods**:

   ```bash
   # Method 1: Standard build
   docker-compose -f docker-compose.prod.yml up -d --build

   # Method 2: Host network build
   docker-compose -f docker-compose.prod.yml build --network host
   docker-compose -f docker-compose.prod.yml up -d

   # Method 3: Offline build
   ./scripts/build_offline.sh
   ```

4. **Check container status**:
   ```bash
   docker ps
   docker-compose -f docker-compose.prod.yml logs
   ```

## Getting Help

If none of these solutions work:

1. Check your server's internet connectivity
2. Verify your VPN/firewall settings
3. Consider using a different server or cloud provider
4. Contact your network administrator
