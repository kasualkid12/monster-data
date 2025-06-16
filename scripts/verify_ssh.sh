#!/bin/bash

echo "=== SSH Configuration Verification ==="

# Check SSH directory permissions
echo "Checking ~/.ssh directory permissions..."
ls -la ~/.ssh

# Check authorized_keys file
echo -e "\nChecking authorized_keys file..."
if [ -f ~/.ssh/authorized_keys ]; then
    echo "authorized_keys exists"
    echo "Permissions: $(ls -l ~/.ssh/authorized_keys)"
    echo "Number of keys: $(wc -l < ~/.ssh/authorized_keys)"
else
    echo "authorized_keys does not exist!"
fi

# Check SSH service status
echo -e "\nChecking SSH service status..."
systemctl status ssh | grep "Active:"

# Check SSH configuration
echo -e "\nChecking SSH configuration..."
grep -v "^#" /etc/ssh/sshd_config | grep -v "^$"

# Test local SSH connection
echo -e "\nTesting local SSH connection..."
ssh -v localhost 'echo "Local SSH connection successful"' || echo "Local SSH connection failed"

echo -e "\n=== Verification Complete ===" 