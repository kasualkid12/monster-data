# Create .ssh directory if it doesn't exist
$sshDir = "$env:USERPROFILE\.ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir | Out-Null
}

# Generate new SSH key
$keyPath = "$sshDir\github_actions"
ssh-keygen -t ed25519 -f $keyPath -N '""' -C "github-actions-deploy"

# Display the public key
Write-Host "=== Public Key (Add to authorized_keys) ==="
Get-Content "$keyPath.pub"
Write-Host "=== End Public Key ==="

# Display the private key in the correct format for GitHub Secrets
Write-Host "=== Private Key (Add to GitHub Secrets) ==="
Write-Host "-----BEGIN OPENSSH PRIVATE KEY-----"
Get-Content $keyPath | Where-Object { $_ -notmatch "PRIVATE KEY" -and $_ -notmatch "END" }
Write-Host "-----END OPENSSH PRIVATE KEY-----"
Write-Host "=== End Private Key ==="

Write-Host "=== Instructions ==="
Write-Host "1. Add the public key to your server's ~/.ssh/authorized_keys file"
Write-Host "2. Copy the private key (including BEGIN and END lines) to GitHub Secrets as SSH_PRIVATE_KEY"
Write-Host "=== End Instructions ===" 