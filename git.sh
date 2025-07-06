#!/usr/bin/env bash
# GitHub SSH Key Setup Script

# Exit on error
set -e

# Source common functions
source "utils.sh"

# Check if git is installed
echo_header "Checking Git Installation"
check_command "git"

# Get git email from existing config
echo_header "Getting Git Configuration"
email=$(git config user.email)
if [ -z "$email" ]; then
    echo "Error: No email configured in Git. Please set git config user.email"
    exit 1
fi

# Configure SSH for GitHub
echo_header "Configuring SSH for GitHub"

# Check if SSH key already exists
if [ -f ~/.ssh/id_ed25519 ]; then
    echo "SSH key already exists. Skipping key generation."
    # Verify existing key permissions
    if [ $(stat -c %a ~/.ssh/id_ed25519) -ne 600 ]; then
        echo "Warning: Fixing SSH key permissions"
        chmod 600 ~/.ssh/id_ed25519
    fi
else
    echo "Generating new SSH key for GitHub"
    
    # Generate SSH key with comment
    if ! ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""; then
        echo "Error: Failed to generate SSH key"
        exit 1
    fi
fi

# Configure SSH agent
echo_header "Configuring SSH Agent"

# Start SSH agent if not running
if ! ps aux | grep -q "[s]sh-agent"; then
    eval "$(ssh-agent -s)"
fi

# Add SSH key to agent
if [ -f ~/.ssh/id_ed25519 ]; then
    if ! ssh-add ~/.ssh/id_ed25519; then
        echo "Warning: Failed to add SSH key to agent"
    fi
fi

# Copy key to clipboard
echo_header "Copying SSH Key to Clipboard"
if [ -f ~/.ssh/id_ed25519.pub ]; then
    if ! command -v xclip &> /dev/null; then
        echo "Warning: xclip not found. Please install xclip to copy key to clipboard."
        echo "Your SSH public key is at: ~/.ssh/id_ed25519.pub"
    else
        if ! xclip -sel clip < ~/.ssh/id_ed25519.pub; then
            echo "Warning: Failed to copy key to clipboard. Please copy manually."
        else
            echo "SSH public key copied to clipboard. Please add it to your GitHub account."
        fi
    fi
else
    echo "Error: No public key found. Please generate a key first."
    exit 1
fi

# Instructions for GitHub setup
echo_header "GitHub Setup Instructions"
echo "1. Add your SSH key to GitHub:"
echo "   - Go to GitHub.com -> Settings -> SSH and GPG keys"
echo "   - Click 'New SSH key'"
echo "   - Give it a title (e.g., 'Personal Laptop')"
echo "   - Paste your public key from clipboard"
echo "   - Click 'Add SSH key'"
echo ""
echo "2. Test your connection:"
echo "   - Run: ssh -T git@github.com"
echo "   - You should see a welcome message from GitHub"
echo ""
echo "GitHub SSH key setup completed successfully!"
echo_header "Starting SSH Agent"
# Check if agent is running with our key
agent_pid=$(ps aux | grep "[s]sh-agent" | awk '{print $2}')
if [ -z "$agent_pid" ]; then
    echo "Starting SSH agent"
    eval "$(ssh-agent -s)"
    trap "kill $SSH_AGENT_PID" EXIT
else
    echo "SSH agent is already running"
fi

# Add key to SSH agent
echo_header "Adding SSH Key to Agent"
if [ -f ~/.ssh/id_ed25519 ]; then
    if ! ssh-add -l | grep -q "id_ed25519"; then
        echo "Adding SSH key to agent"
        if ! ssh-add ~/.ssh/id_ed25519; then
            echo "Error: Failed to add SSH key to agent"
            exit 1
        fi
    else
        echo "SSH key already added to agent"
    fi
else
    echo "Error: No SSH key found to add to agent"
    exit 1
fi

# Open GitHub settings in browser
echo_header "Opening GitHub Settings"
echo "Please add your SSH key to GitHub in the next 60 seconds"
xdg-open "https://github.com/settings/keys" &

# Test SSH connection
echo_header "Testing SSH Connection to GitHub"
if [ -f ~/.ssh/id_ed25519 ]; then
    if ! ssh -T git@github.com -i ~/.ssh/id_ed25519; then
        echo "Warning: SSH connection test failed. Please verify your SSH key in GitHub settings."
        exit 1
    else
        echo "✓ SSH connection test successful"
    fi
else
    echo "Error: No SSH key found to test"
    exit 1
fi

# Verify configuration
echo_header "Verification"
echo "GitHub SSH key setup completed successfully!"
if [ -f ~/.ssh/id_ed25519 ]; then
    echo "SSH key location: ~/.ssh/id_ed25519"
    echo "Fingerprint: $(ssh-keygen -l -f ~/.ssh/id_ed25519)"
else
    echo "Error: SSH key verification failed"
    exit 1
fi
