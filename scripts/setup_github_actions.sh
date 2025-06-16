#!/bin/bash

# Create SSH directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key for GitHub Actions
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions -N ""

# Set proper permissions
chmod 600 ~/.ssh/github_actions
chmod 644 ~/.ssh/github_actions.pub

# Add to authorized keys
cat ~/.ssh/github_actions.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Display the private key (to be added to GitHub secrets)
echo "=== Add this private key to GitHub Secrets as SSH_PRIVATE_KEY ==="
cat ~/.ssh/github_actions
echo "=== End of private key ==="

# Create application directory with proper permissions
sudo mkdir -p /opt/dnd-monster-data
sudo chown -R $USER:$USER /opt/dnd-monster-data

# Create backups directory
mkdir -p /opt/dnd-monster-data/backups

echo "Setup complete! Please add the following to your GitHub repository secrets:"
echo "1. SSH_PRIVATE_KEY: (the private key shown above)"
echo "2. SSH_USER: $USER"
echo "3. SERVER_HOST: $(hostname -I | awk '{print $1}')" 