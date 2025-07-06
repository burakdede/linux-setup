#!/usr/bin/env bash
# System Package Installer Script
# Fixed for modern Ubuntu with proper GPG key handling

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Source common functions
source "utils.sh"

# Directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system
echo_header "System Updates"
log_info "Updating system packages..."
if ! sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y; then
    log_warn "Some system updates may have failed"
fi

# Install Basic Utilities
echo_header "Install Basic Utilities"
log_info "Installing basic utilities..."
if ! sudo apt-get install -y --no-install-recommends xclip ubuntu-restricted-extras curl wget gpg software-properties-common; then
    log_error "Failed to install basic utilities"
    exit 1
fi

# Install APT packages
echo_header "Installing APT Packages"
if [ -f apt-packages.txt ]; then
    log_info "Installing packages from apt-packages.txt..."
    while IFS= read -r package; do
        if [ -n "$package" ] && [[ ! $package =~ ^# ]]; then
            log_info "Installing APT package: $package"
            if ! sudo apt-get install -y --no-install-recommends "$package"; then
                log_warn "Failed to install APT package $package"
            fi
        fi
    done < apt-packages.txt
else
    log_warn "apt-packages.txt not found, skipping APT package installation"
fi

# Install Snap packages
echo_header "Installing Snap Packages"
if [ -f snap-packages.txt ]; then
    log_info "Installing packages from snap-packages.txt..."
    while IFS= read -r package; do
        if [ -n "$package" ] && [[ ! $package =~ ^# ]]; then
            log_info "Installing Snap package: $package"
            if ! sudo snap install "$package" --classic 2>/dev/null; then
                log_warn "Failed to install Snap package $package"
            fi
        fi
    done < snap-packages.txt
else
    log_warn "snap-packages.txt not found, skipping Snap package installation"
fi

# Install VS Code
echo_header "Installing VS Code"
if ! command_exists code; then
    log_info "Installing VS Code..."
    
    # Create keyrings directory if it doesn't exist
    sudo mkdir -p /etc/apt/keyrings
    
    # Download and add Microsoft GPG key (modern method)
    if ! wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg; then
        log_error "Failed to add Microsoft GPG key"
        exit 1
    fi
    
    # Add VS Code repository with signed-by
    if ! echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null; then
        log_error "Failed to add VS Code repository"
        exit 1
    fi
    
    # Update and install VS Code
    if ! sudo apt update || ! sudo apt install -y code; then
        log_error "Failed to install VS Code"
        exit 1
    fi
    
    log_info "VS Code installed successfully!"
else
    log_info "VS Code is already installed"
fi

# Install VS Code extensions
echo_header "Installing VS Code Extensions"
if ! command_exists code; then
    log_warn "VS Code is not installed. Skipping extension installation."
else
    if [ -f vscode-extensions.txt ]; then
        log_info "Installing VS Code extensions..."
        
        # Create extensions directory
        mkdir -p "$HOME/.vscode/extensions" 2>/dev/null || true
        
        # Read and install each extension
        while IFS= read -r extension; do
            # Skip empty lines and comments
            if [ -z "$extension" ] || [[ $extension =~ ^# ]]; then
                continue
            fi
            
            # Skip if already installed (case-insensitive)
            if code --list-extensions | tr '[:upper:]' '[:lower:]' | grep -iq "$(echo "$extension" | tr '[:upper:]' '[:lower:]')"; then
                log_info "Extension '$extension' is already installed."
                continue
            fi
            
            # Install extension
            log_info "Installing extension: $extension"
            if ! code --install-extension "$extension" --force; then
                log_warn "Failed to install extension: $extension"
            fi
        done < vscode-extensions.txt
    else
        log_warn "vscode-extensions.txt not found, skipping extension installation"
    fi
fi

# Install Cursor
echo_header "Installing Cursor"
if ! command -v cursor &> /dev/null; then
    echo "Installing Cursor AppImage..."
    
    # Get download URL from API with retries
    DOWNLOAD_URL=""
    for i in {1..3}; do
        if API_RESPONSE=$(curl -s "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable"); then
            DOWNLOAD_URL=$(echo "$API_RESPONSE" | grep -o '"downloadUrl":"[^"]*' | cut -d'"' -f4)
            if [ -n "$DOWNLOAD_URL" ]; then
                echo "✓ Successfly retrieved download URL"
                break
            fi
        fi
        echo "API attempt $i failed, retrying..."
        sleep 2
    done
    
    if [ -z "$DOWNLOAD_URL" ]; then
        echo "✗ Warning: Failed to get download URL from API"
        exit 1
    fi
    
    # Download Cursor with retries
    for i in {1..3}; do
        if wget -q "$DOWNLOAD_URL" -O /tmp/cursor.AppImage; then
            echo "✓ Successfully downloaded Cursor"
            break
        else
            echo "Attempt $i failed, retrying..."
            sleep 2
        fi
    done

    if [ -f /tmp/cursor.AppImage ]; then
        # Make executable and move to bin
        if chmod +x /tmp/cursor.AppImage && sudo mv /tmp/cursor.AppImage /usr/local/bin/cursor; then
            echo "✓ Successfully installed Cursor"
            # Create desktop entry
            if ! [ -f /usr/share/applications/cursor.desktop ]; then
                echo "[Desktop Entry]" | sudo tee /usr/share/applications/cursor.desktop > /dev/null
                echo "Name=Cursor" | sudo tee -a /usr/share/applications/cursor.desktop > /dev/null
                echo "Comment=Cursor IDE" | sudo tee -a /usr/share/applications/cursor.desktop > /dev/null
                echo "Exec=/usr/local/bin/cursor" | sudo tee -a /usr/share/applications/cursor.desktop > /dev/null
                echo "Icon=cursor" | sudo tee -a /usr/share/applications/cursor.desktop > /dev/null
                echo "Terminal=false" | sudo tee -a /usr/share/applications/cursor.desktop > /dev/null
                echo "Type=Application" | sudo tee -a /usr/share/applications/cursor.desktop > /dev/null
                echo "Categories=Development;IDE;" | sudo tee -a /usr/share/applications/cursor.desktop > /dev/null
            fi
        else
            echo "✗ Warning: Failed to install Cursor"
        fi
    else
        echo "✗ Warning: Failed to download Cursor AppImage"
    fi
else
    echo "Cursor is already installed"
fi

# Install Windsurf
echo_header "Installing Windsurf"
if ! command_exists windsurf; then
    log_info "Setting up Windsurf repository..."
    
    # Create keyrings directory
    sudo mkdir -p /etc/apt/keyrings
    
    # Download and add Windsurf GPG key
    if ! wget -qO- "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/windsurf-stable.gpg; then
        log_error "Failed to add Windsurf GPG key"
        exit 1
    fi
    
    # Add Windsurf repository
    if ! echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/windsurf-stable.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null; then
        log_error "Failed to add Windsurf repository"
        exit 1
    fi

    # Update and install Windsurf
    if ! sudo apt update || ! sudo apt install -y windsurf; then
        log_error "Failed to install Windsurf"
        exit 1
    fi
    
    log_info "Windsurf installed successfully!"
else
    log_info "Windsurf is already installed"
fi

# Install Google Chrome
echo_header "Installing Google Chrome"
if ! command_exists google-chrome; then
    log_info "Installing Google Chrome..."
    
    # Create keyrings directory
    sudo mkdir -p /etc/apt/keyrings
    
    # Download and add Google Chrome GPG key
    if ! wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg; then
        log_error "Failed to add Google Chrome GPG key"
        exit 1
    fi

    # Add Google Chrome repository
    if ! echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null; then
        log_error "Failed to add Google Chrome repository"
        exit 1
    fi

    # Update and install Google Chrome
    if ! sudo apt update || ! sudo apt install -y google-chrome-stable; then
        log_error "Failed to install Google Chrome"
        exit 1
    fi
    
    log_info "Google Chrome installed successfully!"
else
    log_info "Google Chrome is already installed"
fi

# Install JetBrains Toolbox
echo_header "Installing JetBrains Toolbox"
if ! command_exists jetbrains-toolbox; then
    log_info "Setting up JetBrains Toolbox installation..."
    
    # Check if jq is available for JSON parsing
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required for JSON parsing. Please install it first: sudo apt-get install jq"
        exit 1
    fi
    
    # Get the latest version from JetBrains API
    TOOLBOX_JSON=$(curl -s 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release')
    
    if [ -z "$TOOLBOX_JSON" ]; then
        log_error "Failed to fetch JetBrains Toolbox release information"
        exit 1
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            PLATFORM="linux"
            ;;
        aarch64|arm64)
            PLATFORM="linuxARM64"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    # Parse JSON to get download URL for the detected platform
    TOOLBOX_URL=$(echo "$TOOLBOX_JSON" | jq -r ".TBA[0].downloads.${PLATFORM}.link")
    
    if [ -z "$TOOLBOX_URL" ] || [ "$TOOLBOX_URL" = "null" ]; then
        log_error "Could not fetch latest JetBrains Toolbox release URL for platform: $PLATFORM"
        exit 1
    fi
    
    log_info "Downloading JetBrains Toolbox from: $TOOLBOX_URL"
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    
    # Download and extract
    if ! wget -q "$TOOLBOX_URL" -O "$TEMP_DIR/jetbrains-toolbox.tar.gz"; then
        log_error "Failed to download JetBrains Toolbox"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    if ! tar -xzf "$TEMP_DIR/jetbrains-toolbox.tar.gz" -C "$TEMP_DIR"; then
        log_error "Failed to extract JetBrains Toolbox"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # Find the extracted directory (it contains the version number)
    EXTRACTED_DIR=$(find "$TEMP_DIR" -name "jetbrains-toolbox-*" -type d | head -1)
    
    if [ -z "$EXTRACTED_DIR" ] || [ ! -d "$EXTRACTED_DIR" ]; then
        log_error "Failed to find extracted JetBrains Toolbox directory"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # Find the executable
    TOOLBOX_EXECUTABLE=$(find "$EXTRACTED_DIR" -name "jetbrains-toolbox" -type f | head -1)
    
    if [ -z "$TOOLBOX_EXECUTABLE" ] || [ ! -f "$TOOLBOX_EXECUTABLE" ]; then
        log_error "Failed to find JetBrains Toolbox executable"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # Install the executable
    if ! sudo cp "$TOOLBOX_EXECUTABLE" /usr/local/bin/jetbrains-toolbox; then
        log_error "Failed to copy JetBrains Toolbox to /usr/local/bin/"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    if ! sudo chmod +x /usr/local/bin/jetbrains-toolbox; then
        log_error "Failed to make JetBrains Toolbox executable"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Clean up
    rm -rf "$TEMP_DIR"
    
    log_info "JetBrains Toolbox installed successfully!"
    log_info "You can run it with: jetbrains-toolbox"
else
    log_info "JetBrains Toolbox is already installed"
fi

# Install Spotify
echo_header "Installing Spotify"
if ! command_exists spotify; then
    log_info "Installing Spotify..."
    
    # Download and add Spotify GPG key (using official method)
    if ! curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg; then
        log_error "Failed to add Spotify GPG key"
        exit 1
    fi
    
    # Add Spotify repository
    if ! echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null; then
        log_error "Failed to add Spotify repository"
        exit 1
    fi
    
    # Update and install Spotify
    if ! sudo apt-get update || ! sudo apt-get install -y spotify-client; then
        log_error "Failed to install Spotify"
        exit 1
    fi
    
    log_info "Spotify installed successfully!"
else
    log_info "Spotify is already installed"
fi

# Verify installations
echo_header "Verification"
log_info "Verifying installations..."

INSTALLED_APPS=()
FAILED_APPS=()

for app in code spotify google-chrome cursor windsurf ulauncher jetbrains-toolbox; do
    if command_exists "$app"; then
        INSTALLED_APPS+=("$app")
        log_info "✓ $app is installed"
    else
        FAILED_APPS+=("$app")
        log_warn "✗ $app is not installed"
    fi
done

# Summary
echo_header "Installation Summary"
log_info "Successfully installed: ${#INSTALLED_APPS[@]} applications"
if [ ${#FAILED_APPS[@]} -gt 0 ]; then
    log_warn "Failed to install: ${FAILED_APPS[*]}"
fi

log_info "System package installation completed!"
log_info "You may need to restart your system or log out and back in for some applications to work properly."
