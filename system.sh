#!/usr/bin/env bash
# System Package Installer Script

# Exit on error
set -e

# Source common functions
source "utils.sh"

# Directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Update system
echo_header "System Updates"
if ! sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y; then
    echo "Warning: Some system updates may have failed"
fi

# Install Basic Utilities
echo_header "Install Basic Utilities"
if ! sudo apt-get install -y --no-install-recommends xclip ubuntu-restricted-extras; then
    echo "Error: Failed to install basic utilities"
    exit 1
fi

# Install APT packages
echo_header "Installing APT Packages"
if [ -f apt-packages.txt ]; then
    while IFS= read -r package; do
        if [ -n "$package" ] && [[ ! $package =~ ^# ]]; then
            echo "Installing APT package: $package"
            if ! sudo apt-get install -y --no-install-recommends "$package"; then
                echo "Warning: Failed to install APT package $package"
            fi
        fi
    done < apt-packages.txt
fi

# Install Snap packages
echo_header "Installing Snap Packages"
if [ -f snap-packages.txt ]; then
    while IFS= read -r package; do
        if [ -n "$package" ] && [[ ! $package =~ ^# ]]; then
            echo "Installing Snap package: $package"
            if ! sudo snap install "$package" --classic 2>/dev/null; then
                echo "Warning: Failed to install Snap package $package"
            fi
        fi
    done < snap-packages.txt
fi

# Install VS Code
echo_header "Installing VS Code"
if ! command -v code &> /dev/null; then
    echo "Installing VS Code..."
    # Add Microsoft repository
    if ! wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -; then
        echo "Warning: Failed to add Microsoft GPG key"
        exit 1
    fi
    
    if ! echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null; then
        echo "Warning: Failed to add VS Code repository"
        exit 1
    fi
    
    # Update and install VS Code
    if ! sudo apt update || ! sudo apt install -y code; then
        echo "Error: Failed to install VS Code"
        exit 1
    fi
else
    echo "VS Code is already installed"
fi

# Install VS Code extensions
echo_header "Installing VS Code Extensions"
if ! command -v code &> /dev/null; then
    echo "Warning: VS Code is not installed. Skipping extension installation."
    exit 0
fi

if [ -f vscode-extensions.txt ]; then
    echo "Installing VS Code extensions..."
    
    # Create extensions directory
    mkdir -p "$HOME/.vscode/extensions" 2>/dev/null
    
    # Read and install each extension
    while IFS= read -r extension; do
        # Skip empty lines
        if [ -z "$extension" ]; then
            continue
        fi
        
        # Skip if already installed (case-insensitive)
        if code --list-extensions | tr '[:upper:]' '[:lower:]' | grep -iq "$(echo "$extension" | tr '[:upper:]' '[:lower:]')"; then
            echo "Extension '$extension' is already installed."
            continue
        fi
        
        # Install extension
        code --install-extension "$extension" --force
    done < vscode-extensions.txt
else
    echo "Warning: vscode-extensions.txt not found"
fi

# Install Cursor
echo_header "Installing Cursor"
if ! command -v cursor &> /dev/null; then
    echo "Installing Cursor AppImage..."
    # Download Cursor with retries
    for i in {1..3}; do
        if wget -q "https://github.com/cursor-editor/cursor/releases/download/latest/cursor.AppImage" -O /tmp/cursor.AppImage; then
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
if ! command -v windsurf &> /dev/null; then
    echo "Setting up Windsurf repository"
    if ! sudo apt-get install -y wget gpg || \
       wget -qO- "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | gpg --dearmor > windsurf-stable.gpg || \
       sudo install -D -o root -g root -m 644 windsurf-stable.gpg /etc/apt/keyrings/windsurf-stable.gpg || \
       echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/windsurf-stable.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null || \
       rm -f windsurf-stable.gpg; then
        echo "Error: Failed to set up Windsurf repository"
        exit 1
    fi

    echo "Installing required packages"
    if ! sudo apt install -y apt-transport-https || \
       sudo apt update; then
        echo "Error: Failed to install required packages"
        exit 1
    fi

    echo "Installing Windsurf..."
    if ! sudo apt install -y windsurf; then
        echo "Warning: Failed to install Windsurf"
    fi
else
    echo "Windsurf is already installed"
fi

# Install Ulauncher
echo_header "Installing Ulauncher"
if ! command -v ulauncher &> /dev/null; then
    echo "Setting up Ulauncher installation"
    
    # Create necessary directories
    if ! mkdir -p /tmp/ulauncher-install || \
       ! sudo add-apt-repository ppa:agornostal/ulauncher -y 2>/dev/null || \
       ! sudo apt update || \
       ! sudo apt install -y ulauncher; then
        echo "Error: Failed to install Ulauncher"
        exit 1
    fi
    
    echo "Ulauncher installed successfully!"
else
    echo "Ulauncher is already installed"
fi

# Install Google Chrome
echo_header "Installing Google Chrome"
if ! command -v google-chrome &> /dev/null; then
    # Add Google Chrome repository and key
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg

    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

    # Update package list
    sudo apt update

    # Install Google Chrome
    sudo apt install -y google-chrome-stable

    # Verify installation
    if ! command -v google-chrome &> /dev/null; then
        echo "Error: Chrome installation failed"
        exit 1
    fi
    echo "Google Chrome installed successfully!"
else
    echo "Google Chrome is already installed"
fi

# Install JetBrains Toolbox
echo_header "Installing JetBrains Toolbox"
if ! command -v jetbrains-toolbox &> /dev/null; then
    echo "Setting up JetBrains Toolbox installation"
    
    # Create directory and install
    if ! mkdir -p /tmp/jetbrains-toolbox-install || \
       ! wget -q "https://download.jetbrains.com/toolbox/jetbrains-toolbox-2.6.3.43718.tar.gz" -O /tmp/jetbrains-toolbox-install/jetbrains-toolbox.tar.gz || \
       ! tar -xzf /tmp/jetbrains-toolbox-install/jetbrains-toolbox.tar.gz -C /tmp/jetbrains-toolbox-install; then
        echo "Error: Failed to download or extract JetBrains Toolbox"
        exit 1
    fi

    # Get the extracted directory name
    extracted_dir="/tmp/jetbrains-toolbox-install/jetbrains-toolbox-2.6.3.43718"
    if [ ! -d "$extracted_dir" ]; then
        echo "Error: Failed to find extracted directory at $extracted_dir"
        exit 1
    fi

    # Check if the executable exists in the bin directory
    toolbox_file="$extracted_dir/bin/jetbrains-toolbox"
    if [ ! -f "$toolbox_file" ]; then
        echo "Error: Failed to find JetBrains Toolbox executable at $toolbox_file"
        exit 1
    fi

    # Create destination directory if needed
    sudo mkdir -p /usr/local/bin
    
    # Move the executable and set permissions
    if ! sudo cp "$toolbox_file" /usr/local/bin/jetbrains-toolbox || \
       ! sudo chmod +x /usr/local/bin/jetbrains-toolbox; then
        echo "Error: Failed to move JetBrains Toolbox to system path"
        exit 1
    fi
    
    # Clean up
    echo "Cleaning up..."
    rm -rf /tmp/jetbrains-toolbox-install 2>/dev/null
    
    echo "JetBrains Toolbox installed successfully!"
    echo "You can run it with: jetbrains-toolbox"
else
    echo "JetBrains Toolbox is already installed"
fi

# Install Spotify
echo_header "Installing Spotify"
if ! command -v spotify &> /dev/null; then
    # Add Spotify repository and key
    if ! curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg || \
       echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list || \
       sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7A3A762FAFD4A51F || \
       sudo apt-get update || sudo apt-get install -y --no-install-recommends spotify-client; then
        echo "Warning: Failed to install Spotify"
        exit 1
    fi
    echo "Spotify installed successfully!"
else
    echo "Spotify is already installed"
fi

# Verify installations
echo_header "Verification"
for cmd in code spotify consul; do
    if ! verify_tool_version "$cmd"; then
        echo "Warning: $cmd is not installed"
    fi
done

echo "System package installation completed successfully!"
