#!/usr/bin/env bash
# GitHub SSH Key Setup Script

# Exit on error
set -e

# Source common functions
source "utils.sh"

# Check if git is installed
echo_header "Checking Git Installation"
check_command "git"

# Check if gitconfig exists
echo_header "Checking Git Configuration"
if ! git config --list &> /dev/null; then
    echo "Error: Git is not configured. Please configure Git first."
    exit 1
fi

# Check if SSH key already exists
echo_header "Checking SSH Key"
if [ -f ~/.ssh/id_ed25519 ]; then
    echo "SSH key already exists. Skipping key generation."
else
    echo "Generating new SSH key for GitHub"
    email=$(git config user.email)
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519
fi

# Copy key to clipboard
echo_header "Copying SSH Key to Clipboard"
if [ -f ~/.ssh/id_ed25519.pub ]; then
    if ! xclip -sel clip < ~/.ssh/id_ed25519.pub; then
        echo "Warning: Failed to copy key to clipboard. Please copy manually."
    fi
else
    echo "Warning: No public key found. Please generate a key first."
fi

# Start SSH agent
echo_header "Starting SSH Agent"
if ! ps aux | grep -q "[s]sh-agent"; then
    echo "Starting SSH agent"
    eval "$(ssh-agent -s)"
else
    echo "SSH agent is already running"
fi

# Add key to SSH agent
echo_header "Adding SSH Key to Agent"
if [ -f ~/.ssh/id_ed25519 ]; then
    if ! ssh-add -l | grep -q "id_ed25519"; then
        echo "Adding SSH key to agent"
        ssh-add ~/.ssh/id_ed25519
    else
        echo "SSH key already added to agent"
    fi
else
    echo "Warning: No SSH key found to add to agent"
fi

# Open GitHub settings in browser
echo_header "Opening GitHub Settings"
echo "Please add your SSH key to GitHub in the next 60 seconds"
xdg-open "https://github.com/settings/keys"
sleep 60

# Test SSH connection
echo_header "Testing SSH Connection to GitHub"
if [ -f ~/.ssh/id_ed25519 ]; then
    if ! ssh -T git@github.com -i ~/.ssh/id_ed25519; then
        echo "Warning: SSH connection test failed. Please verify your SSH key in GitHub settings."
    fi
else
    echo "Warning: No SSH key found to test"
fi

# Verify configuration
echo_header "Verification"
echo "GitHub SSH key setup completed successfully!"
if [ -f ~/.ssh/id_ed25519 ]; then
    echo "SSH key location: ~/.ssh/id_ed25519"
    echo "Fingerprint: $(ssh-keygen -l -f ~/.ssh/id_ed25519)"
fi
