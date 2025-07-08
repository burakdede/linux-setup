#!/usr/bin/env bash
# GitHub SSH Key Setup Script - Fixed Version

# Exit on error
set -e

# Directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/../utils/utils.sh"

# Check if git is installed
echo_header "Checking Git Installation"
if ! command_exists git; then
    log_error "Git is not installed. Please install it first."
    exit 1
fi
log_success "Git is installed."

# Get git email from existing config
echo_header "Getting Git Configuration"
email=$(git config user.email 2>/dev/null || echo "")
if [ -z "$email" ]; then
    log_error "No email configured in Git. Please set git config user.email"
    exit 1
fi

# Validate email format
if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    log_error "Invalid email format: $email"
    exit 1
fi
log_info "Using email: $email"

# Ensure SSH directory exists with proper permissions
echo_header "Setting Up SSH Directory"
if [ ! -d ~/.ssh ]; then
    log_info "Creating ~/.ssh directory"
    mkdir -p ~/.ssh
fi
chmod 700 ~/.ssh

# Configure SSH for GitHub
echo_header "Configuring SSH for GitHub"

# Check if SSH key already exists
if [ -f ~/.ssh/id_ed25519 ]; then
    log_warn "SSH key already exists. Verifying..."
    
    # Verify key permissions
        if [ $(stat -c %a ~/.ssh/id_ed25519) -ne 600 ]; then
        log_info "Fixing SSH private key permissions"
        chmod 600 ~/.ssh/id_ed25519
    fi
    
    # Verify public key permissions
    if [ -f ~/.ssh/id_ed25519.pub ]; then
        if [ $(stat -c %a ~/.ssh/id_ed25519.pub) -ne 644 ]; then
            log_info "Fixing SSH public key permissions"
            chmod 644 ~/.ssh/id_ed25519.pub
        fi
    else
        log_error "Private key exists but public key is missing"
        exit 1
    fi
else
    log_info "Generating new SSH key for GitHub"
    
    # Generate SSH key with comment
    if ! ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""; then
        log_error "Failed to generate SSH key"
        exit 1
    fi
    
    # Set proper permissions
    chmod 600 ~/.ssh/id_ed25519
    chmod 644 ~/.ssh/id_ed25519.pub
fi

# Configure SSH agent (consolidated single approach)
echo_header "Configuring SSH Agent"

# Check if we have an active SSH agent with our key
key_loaded=false
if [ -n "$SSH_AGENT_PID" ] && kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
    # Agent is running, check if our key is loaded
    if ssh-add -l 2>/dev/null | grep -q "id_ed25519"; then
        log_success "SSH agent is running with our key already loaded"
        key_loaded=true
    fi
fi

# Start agent or add key if needed
if [ "$key_loaded" = false ]; then
    # Start SSH agent if not running
    if [ -z "$SSH_AGENT_PID" ] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        log_info "Starting SSH agent"
        eval "$(ssh-agent -s)"
    fi
    
    # Add SSH key to agent
    if [ -f ~/.ssh/id_ed25519 ]; then
        log_info "Adding SSH key to agent"
        if ! ssh-add ~/.ssh/id_ed25519; then
            log_error "Failed to add SSH key to agent"
            exit 1
        fi
    else
        log_error "No SSH key found to add to agent"
        exit 1
    fi
fi

# Copy key to clipboard
echo_header "Copying SSH Key to Clipboard"
if [ -f ~/.ssh/id_ed25519.pub ]; then
    # Try different clipboard tools
    if command -v xclip &> /dev/null; then
        if xclip -sel clip < ~/.ssh/id_ed25519.pub; then
            log_success "SSH public key copied to clipboard using xclip"
        else
            log_warn "Failed to copy key to clipboard with xclip"
        fi
    elif command -v xsel &> /dev/null; then
        if xsel --clipboard < ~/.ssh/id_ed25519.pub; then
            log_success "SSH public key copied to clipboard using xsel"
        else
            log_warn "Failed to copy key to clipboard with xsel"
        fi
    else
        log_warn "No clipboard tool found (xclip/xsel). Please install one or copy manually."
    fi
    
    log_info "Your SSH public key is at: ~/.ssh/id_ed25519.pub"
    log_info "Key content:"
    log_info "----------------------------------------"
    cat ~/.ssh/id_ed25519.pub
    log_info "----------------------------------------"
else
    log_error "No public key found"
    exit 1
fi

# Add GitHub to known hosts if not already there
echo_header "Adding GitHub to Known Hosts"
if ! grep -q "github.com" ~/.ssh/known_hosts 2>/dev/null; then
    log_info "Adding GitHub to known hosts"
    # Create known_hosts file if it doesn't exist
    touch ~/.ssh/known_hosts
    chmod 644 ~/.ssh/known_hosts
    
    # Add GitHub's host keys (multiple key types for better compatibility)
    ssh-keyscan -t rsa,ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null || {
        log_warn "Failed to add GitHub to known hosts. You may see a host verification prompt."
    }
else
    log_success "GitHub already in known hosts"
fi

# Instructions for GitHub setup
echo_header "GitHub Setup Instructions"
log_info "1. Add your SSH key to GitHub:"
log_info "   - Go to GitHub.com -> Settings -> SSH and GPG keys"
log_info "   - Click 'New SSH key'"
log_info "   - Give it a title (e.g., 'Personal Laptop')"
log_info "   - Paste your public key (shown above or from clipboard)"
log_info "   - Click 'Add SSH key'"
log_info ""

# Open GitHub settings in browser (with error handling)
echo_header "Opening GitHub Settings"
if command -v xdg-open &> /dev/null; then
    if xdg-open "https://github.com/settings/keys" 2>/dev/null; then
        log_success "Opened GitHub settings in browser"
    else
        log_warn "Failed to open browser. Please manually go to: https://github.com/settings/keys"
    fi
elif command -v open &> /dev/null; then
    # macOS
    if open "https://github.com/settings/keys" 2>/dev/null; then
        log_success "Opened GitHub settings in browser"
    else
        log_warn "Failed to open browser. Please manually go to: https://github.com/settings/keys"
    fi
else
    log_info "Please manually open: https://github.com/settings/keys"
fi

# Wait for user confirmation
log_info ""
read -p "After adding the SSH key to GitHub, press Enter to test the connection..."

# Test SSH connection with improved error handling
echo_header "Testing SSH Connection to GitHub"
if [ -f ~/.ssh/id_ed25519 ]; then
    log_info "Testing SSH connection..."
    
    # Test with better timeout and error handling
    set +e  # Don't exit on error for this test
    ssh_output=$(timeout 30 ssh -T git@github.com -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=yes 2>&1)
    ssh_exit_code=$?
    set -e  # Re-enable exit on error
    
    # Check results
    if [ $ssh_exit_code -eq 124 ]; then
        log_error "Connection timed out after 30 seconds"
        log_info "This might indicate:"
        log_info "1. Network connectivity issues"
        log_info "2. Firewall blocking SSH connections"
        log_info "3. GitHub is experiencing issues"
        exit 1
    elif echo "$ssh_output" | grep -q "successfully authenticated"; then
        log_success "✓ SSH connection test successful"
        username=$(echo "$ssh_output" | grep "Hi " | cut -d' ' -f2 | cut -d'!' -f1)
        log_success "Connected to GitHub as: $username"
    elif echo "$ssh_output" | grep -q "Permission denied"; then
        log_error "❌ SSH connection failed - Permission denied"
        log_info "This usually means:"
        log_info "1. The SSH key hasn't been added to GitHub yet"
        log_info "2. The SSH key was added incorrectly"
        log_info "3. The SSH key doesn't match the one in your GitHub account"
        log_info ""
        log_info "Please double-check that you've added the correct SSH key to GitHub."
        exit 1
    else
        log_warn "Unexpected SSH response"
        log_info "SSH output: $ssh_output"
        log_info "Exit code: $ssh_exit_code"
        log_info ""
        log_info "Common issues:"
        log_info "1. SSH key not added to GitHub"
        log_info "2. Network connectivity problems"
        log_info "3. SSH agent not running"
        log_info ""
        log_info "You can test manually with: ssh -T git@github.com"
        exit 1
    fi
else
    log_error "No SSH key found to test"
    exit 1
fi

# Final verification
echo_header "Final Verification"
log_success "✓ SSH key location: ~/.ssh/id_ed25519"
log_success "✓ SSH key permissions: $(stat -c %a ~/.ssh/id_ed25519)"
log_success "✓ SSH agent running: $(if [ -n "$SSH_AGENT_PID" ]; then echo "Yes (PID: $SSH_AGENT_PID)"; else echo "No"; fi)"
log_success "✓ Key loaded in agent: $(if ssh-add -l 2>/dev/null | grep -q "id_ed25519"; then echo "Yes"; else echo "No"; fi)"
log_success "✓ GitHub connection: Working"

# Show key fingerprint
if [ -f ~/.ssh/id_ed25519 ]; then
    log_success "✓ Key fingerprint: $(ssh-keygen -l -f ~/.ssh/id_ed25519 | awk '{print $2}')"
fi

log_info ""
log_success "🎉 GitHub SSH key setup completed successfully!"
log_info ""
log_info "You can now clone repositories using SSH URLs like:"
log_info "git clone git@github.com:username/repository.git"
