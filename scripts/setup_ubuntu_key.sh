#!/bin/bash

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create or append to authorized_keys
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Add the public key (replace this with your actual public key)
echo "=== Adding GitHub Actions public key ==="
echo "Please paste the contents of your github_actions.pub file (press Ctrl+D when done):"
cat >> ~/.ssh/authorized_keys

# Verify the key was added
echo "=== Verifying key addition ==="
tail -n 1 ~/.ssh/authorized_keys

# Test local SSH connection
echo "=== Testing local SSH connection ==="
ssh -o StrictHostKeyChecking=no localhost "echo 'SSH connection successful'"

echo "=== Setup complete ==="
echo "Now add the private key to GitHub Secrets as SSH_PRIVATE_KEY" 