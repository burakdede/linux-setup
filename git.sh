#!/usr/bin/env bash
# GitHub SSH Key Setup Script - Fixed Version

# Exit on error
set -e

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions (replacing utils.sh dependency)
echo_header() {
    echo -e "\n${BLUE}==== $1 ====${NC}"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ $1 is installed${NC}"
    fi
}

# Validate email format
validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}Error: Invalid email format: $email${NC}"
        exit 1
    fi
}

# Check if git is installed
echo_header "Checking Git Installation"
check_command "git"

# Get git email from existing config
echo_header "Getting Git Configuration"
email=$(git config user.email 2>/dev/null || echo "")
if [ -z "$email" ]; then
    echo -e "${RED}Error: No email configured in Git. Please set git config user.email${NC}"
    exit 1
fi

# Validate email format
validate_email "$email"
echo -e "${GREEN}Using email: $email${NC}"

# Ensure SSH directory exists with proper permissions
echo_header "Setting Up SSH Directory"
if [ ! -d ~/.ssh ]; then
    echo "Creating ~/.ssh directory"
    mkdir -p ~/.ssh
fi
chmod 700 ~/.ssh

# Configure SSH for GitHub
echo_header "Configuring SSH for GitHub"

# Check if SSH key already exists
if [ -f ~/.ssh/id_ed25519 ]; then
    echo -e "${YELLOW}SSH key already exists. Verifying...${NC}"
    
    # Verify key permissions
    if [ $(stat -c %a ~/.ssh/id_ed25519) -ne 600 ]; then
        echo "Fixing SSH private key permissions"
        chmod 600 ~/.ssh/id_ed25519
    fi
    
    # Verify public key permissions
    if [ -f ~/.ssh/id_ed25519.pub ]; then
        if [ $(stat -c %a ~/.ssh/id_ed25519.pub) -ne 644 ]; then
            echo "Fixing SSH public key permissions"
            chmod 644 ~/.ssh/id_ed25519.pub
        fi
    else
        echo -e "${RED}Error: Private key exists but public key is missing${NC}"
        exit 1
    fi
else
    echo "Generating new SSH key for GitHub"
    
    # Generate SSH key with comment
    if ! ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""; then
        echo -e "${RED}Error: Failed to generate SSH key${NC}"
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
        echo -e "${GREEN}SSH agent is running with our key already loaded${NC}"
        key_loaded=true
    fi
fi

# Start agent or add key if needed
if [ "$key_loaded" = false ]; then
    # Start SSH agent if not running
    if [ -z "$SSH_AGENT_PID" ] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        echo "Starting SSH agent"
        eval "$(ssh-agent -s)"
    fi
    
    # Add SSH key to agent
    if [ -f ~/.ssh/id_ed25519 ]; then
        echo "Adding SSH key to agent"
        if ! ssh-add ~/.ssh/id_ed25519; then
            echo -e "${RED}Error: Failed to add SSH key to agent${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: No SSH key found to add to agent${NC}"
        exit 1
    fi
fi

# Copy key to clipboard
echo_header "Copying SSH Key to Clipboard"
if [ -f ~/.ssh/id_ed25519.pub ]; then
    # Try different clipboard tools
    if command -v xclip &> /dev/null; then
        if xclip -sel clip < ~/.ssh/id_ed25519.pub; then
            echo -e "${GREEN}SSH public key copied to clipboard using xclip${NC}"
        else
            echo -e "${YELLOW}Warning: Failed to copy key to clipboard with xclip${NC}"
        fi
    elif command -v xsel &> /dev/null; then
        if xsel --clipboard < ~/.ssh/id_ed25519.pub; then
            echo -e "${GREEN}SSH public key copied to clipboard using xsel${NC}"
        else
            echo -e "${YELLOW}Warning: Failed to copy key to clipboard with xsel${NC}"
        fi
    else
        echo -e "${YELLOW}Warning: No clipboard tool found (xclip/xsel). Please install one or copy manually.${NC}"
    fi
    
    echo "Your SSH public key is at: ~/.ssh/id_ed25519.pub"
    echo "Key content:"
    echo "----------------------------------------"
    cat ~/.ssh/id_ed25519.pub
    echo "----------------------------------------"
else
    echo -e "${RED}Error: No public key found${NC}"
    exit 1
fi

# Add GitHub to known hosts if not already there
echo_header "Adding GitHub to Known Hosts"
if ! grep -q "github.com" ~/.ssh/known_hosts 2>/dev/null; then
    echo "Adding GitHub to known hosts"
    # Create known_hosts file if it doesn't exist
    touch ~/.ssh/known_hosts
    chmod 644 ~/.ssh/known_hosts
    
    # Add GitHub's host keys (multiple key types for better compatibility)
    ssh-keyscan -t rsa,ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null || {
        echo -e "${YELLOW}Warning: Failed to add GitHub to known hosts. You may see a host verification prompt.${NC}"
    }
else
    echo -e "${GREEN}GitHub already in known hosts${NC}"
fi

# Instructions for GitHub setup
echo_header "GitHub Setup Instructions"
echo "1. Add your SSH key to GitHub:"
echo "   - Go to GitHub.com -> Settings -> SSH and GPG keys"
echo "   - Click 'New SSH key'"
echo "   - Give it a title (e.g., 'Personal Laptop')"
echo "   - Paste your public key (shown above or from clipboard)"
echo "   - Click 'Add SSH key'"
echo ""

# Open GitHub settings in browser (with error handling)
echo_header "Opening GitHub Settings"
if command -v xdg-open &> /dev/null; then
    if xdg-open "https://github.com/settings/keys" 2>/dev/null; then
        echo -e "${GREEN}Opened GitHub settings in browser${NC}"
    else
        echo -e "${YELLOW}Warning: Failed to open browser. Please manually go to: https://github.com/settings/keys${NC}"
    fi
elif command -v open &> /dev/null; then
    # macOS
    if open "https://github.com/settings/keys" 2>/dev/null; then
        echo -e "${GREEN}Opened GitHub settings in browser${NC}"
    else
        echo -e "${YELLOW}Warning: Failed to open browser. Please manually go to: https://github.com/settings/keys${NC}"
    fi
else
    echo "Please manually open: https://github.com/settings/keys"
fi

# Wait for user confirmation
echo ""
read -p "After adding the SSH key to GitHub, press Enter to test the connection..."

# Test SSH connection with improved error handling
echo_header "Testing SSH Connection to GitHub"
if [ -f ~/.ssh/id_ed25519 ]; then
    echo "Testing SSH connection..."
    
    # Test with better timeout and error handling
    set +e  # Don't exit on error for this test
    ssh_output=$(timeout 30 ssh -T git@github.com -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=yes 2>&1)
    ssh_exit_code=$?
    set -e  # Re-enable exit on error
    
    # Check results
    if [ $ssh_exit_code -eq 124 ]; then
        echo -e "${RED}Connection timed out after 30 seconds${NC}"
        echo "This might indicate:"
        echo "1. Network connectivity issues"
        echo "2. Firewall blocking SSH connections"
        echo "3. GitHub is experiencing issues"
        exit 1
    elif echo "$ssh_output" | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✓ SSH connection test successful${NC}"
        username=$(echo "$ssh_output" | grep "Hi " | cut -d' ' -f2 | cut -d'!' -f1)
        echo -e "${GREEN}Connected to GitHub as: $username${NC}"
    elif echo "$ssh_output" | grep -q "Permission denied"; then
        echo -e "${RED}❌ SSH connection failed - Permission denied${NC}"
        echo "This usually means:"
        echo "1. The SSH key hasn't been added to GitHub yet"
        echo "2. The SSH key was added incorrectly"
        echo "3. The SSH key doesn't match the one in your GitHub account"
        echo ""
        echo "Please double-check that you've added the correct SSH key to GitHub."
        exit 1
    else
        echo -e "${YELLOW}Warning: Unexpected SSH response${NC}"
        echo "SSH output: $ssh_output"
        echo "Exit code: $ssh_exit_code"
        echo ""
        echo "Common issues:"
        echo "1. SSH key not added to GitHub"
        echo "2. Network connectivity problems"
        echo "3. SSH agent not running"
        echo ""
        echo "You can test manually with: ssh -T git@github.com"
        exit 1
    fi
else
    echo -e "${RED}Error: No SSH key found to test${NC}"
    exit 1
fi

# Final verification
echo_header "Final Verification"
echo -e "${GREEN}✓ SSH key location: ~/.ssh/id_ed25519${NC}"
echo -e "${GREEN}✓ SSH key permissions: $(stat -c %a ~/.ssh/id_ed25519)${NC}"
echo -e "${GREEN}✓ SSH agent running: $(if [ -n "$SSH_AGENT_PID" ]; then echo "Yes (PID: $SSH_AGENT_PID)"; else echo "No"; fi)${NC}"
echo -e "${GREEN}✓ Key loaded in agent: $(if ssh-add -l 2>/dev/null | grep -q "id_ed25519"; then echo "Yes"; else echo "No"; fi)${NC}"
echo -e "${GREEN}✓ GitHub connection: Working${NC}"

# Show key fingerprint
if [ -f ~/.ssh/id_ed25519 ]; then
    echo -e "${GREEN}✓ Key fingerprint: $(ssh-keygen -l -f ~/.ssh/id_ed25519 | awk '{print $2}')${NC}"
fi

echo ""
echo -e "${GREEN}🎉 GitHub SSH key setup completed successfully!${NC}"
echo ""
echo "You can now clone repositories using SSH URLs like:"
echo -e "${BLUE}git clone git@github.com:username/repository.git${NC}"
