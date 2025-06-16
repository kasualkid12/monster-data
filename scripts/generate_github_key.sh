#!/bin/bash

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate new SSH key
ssh-keygen -t ed25519 -f ~/.ssh/github_actions -N "" -C "github-actions-deploy"

# Display the public key
echo "=== Public Key (Add to authorized_keys) ==="
cat ~/.ssh/github_actions.pub
echo "=== End Public Key ==="

# Display the private key in the correct format for GitHub Secrets
echo "=== Private Key (Add to GitHub Secrets) ==="
echo "-----BEGIN OPENSSH PRIVATE KEY-----"
cat ~/.ssh/github_actions | grep -v "PRIVATE KEY" | grep -v "END"
echo "-----END OPENSSH PRIVATE KEY-----"
echo "=== End Private Key ==="

# Set correct permissions
chmod 600 ~/.ssh/github_actions
chmod 644 ~/.ssh/github_actions.pub

echo "=== Instructions ==="
echo "1. Add the public key to your server's ~/.ssh/authorized_keys file"
echo "2. Copy the private key (including BEGIN and END lines) to GitHub Secrets as SSH_PRIVATE_KEY"
echo "=== End Instructions ===" 