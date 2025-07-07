#!/usr/bin/env bash

# Common utility functions for setup scripts

# ANSI color codes
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# Function to create a styled header
echo_header() {
    printf "\n${BLUE}================================================================================${RESET}\n"
    printf "${BLUE}${BOLD}  %s${RESET}\n" "$1"
    printf "${BLUE}================================================================================${RESET}\n\n"
}

# Function to log messages with shell colors and indentation
log_info() {
    printf "  ${CYAN}--> %s${RESET}\n" "$1"
}

log_warn() {
    printf "  ${YELLOW}>> %s${RESET}\n" "$1" >&2
}

log_error() {
    printf "  ${RED}!! %s${RESET}\n" "$1" >&2
}

# Function for success messages
log_success() {
    printf "  ${GREEN}++ %s${RESET}\n" "$1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run a command with output
run_with_output() {
    local cmd="$*"
    log_info "Running: $cmd"
    "$@"
}

# Function to run a command with sudo after ensuring privileges
sudo_run() {
    ensure_sudo
    log_info "Running command: $*"
    sudo "$@"
}

# Function to run a script with sudo check
run_script() {
    local script_name="$1"
    
    # Check if script exists
    if [ ! -f "$script_name" ]; then
        log_error "❌ Script $script_name not found!"
        return 1
    fi
    
    # Check if script needs sudo
    if grep -q "sudo" "$script_name"; then
        ensure_sudo
    fi
    
    # Run script with live output
    bash "$script_name"
}

# Function to create a styled header with shell colors
echo_header() {
    echo "${BLUE}=== $1 ===${RESET}"
}

# Function to log messages with shell colors
log_info() {
    echo "${GREEN}[INFO] $1${RESET}"
}

log_warn() {
    echo "${YELLOW}[WARN] $1${RESET}"
}

log_error() {
    echo "${RED}[ERROR] $1${RESET}"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then 
        echo "Error: Please run this script as a normal user, not root"
        exit 1
    fi
}

# Function to check if in correct directory
check_directory() {
    if [ ! -f "run.sh" ]; then
        echo "Error: Please run this script from the project root directory"
        exit 1
    fi
}

# Function to verify command exists
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Function to verify file exists
check_file() {
    if [ ! -f "$1" ]; then
        echo "Warning: $1 not found"
        return 1
    fi
    return 0
}

# Function to verify directory exists
check_dir() {
    if [ ! -d "$1" ]; then
        echo "Warning: Directory $1 not found"
        return 1
    fi
    return 0
}

# Function to backup GNOME settings
# Usage: 
#   1. From terminal: source utils.sh && backup_gnome_settings
#   2. From another script: source utils.sh && backup_gnome_settings
backup_gnome_settings() {
    echo "Backing up GNOME settings..."
    local backup_dir=~/.config/gsettings-backup
    mkdir -p "$backup_dir"
    gsettings list-recursively > "$backup_dir/settings-backup-$(date +%Y%m%d-%H%M%S).txt"
    echo "Backup completed successfully"
}

# Function to restore GNOME settings
# Usage:
#   1. From terminal: source utils.sh && restore_gnome_settings
#   2. From another script: source utils.sh && restore_gnome_settings
# Warning: This will reset ALL GNOME settings to defaults
restore_gnome_settings() {
    echo "Restoring GNOME settings to defaults..."
    
    # Reset all relevant schemas
    gsettings reset-recursively org.gnome.desktop.wm.preferences
    gsettings reset-recursively org.gnome.desktop.wm.keybindings
    gsettings reset-recursively org.gnome.desktop.interface
    gsettings reset-recursively org.gnome.shell
    gsettings reset-recursively org.gnome.shell.extensions.dash-to-dock
    gsettings reset-recursively org.gnome.shell.extensions
    
    echo "Settings restored to defaults. You may need to log out and back in for all changes to take effect."
}

# Function to show backup and restore instructions
# Usage:
#   1. From terminal: source utils.sh && show_backup_instructions
#   2. From another script: source utils.sh && show_backup_instructions
show_backup_instructions() {
    echo "Backup and Restore Instructions:"
    echo "1. Backup of current settings is stored in ~/.config/gsettings-backup/"
    echo "2. To restore default settings, run:"
    echo "   restore_gnome_settings"
    echo "3. Alternatively, you can use GNOME Tweaks to reset settings manually"
    echo "4. Each backup file is timestamped and contains all current GNOME settings"
}



# Function to verify package installation
verify_package() {
    if ! dpkg -l | grep -q "$1"; then
        echo "Warning: $1 is not installed"
        return 1
    fi
}

# Function to verify dock configuration
verify_dock_apps() {
    local expected_apps=(
        "code.desktop"  # VSCode
        "slack_slack.desktop"  # Slack
        "discord_discord.desktop"  # Discord
        "google-chrome.desktop"  # Chrome
        "firefox_firefox.desktop"  # Firefox
        "spotify_spotify.desktop"  # Spotify
        "obsidian_obsidian.desktop"  # Obsidian
        "windsurf_windsurf.desktop"  # Windsurf
        "cursor_cursor.desktop"  # Cursor
        "localsend_localsend.desktop"  # LocalSend
        "org.gnome.Nautilus.desktop"  # Home Folder
        "org.gnome.Terminal.desktop"  # Terminal
        "gnome-control-center_gnome-control-center.desktop"  # Settings
    )

    echo "Verifying dock configuration..."
    local current_apps=$(gsettings get org.gnome.shell favorite-apps | tr -d "[]'" | tr ',' ' ')
    
    echo "Expected apps in dock:"
    printf "  %s\n" "${expected_apps[@]}"
    
    echo "Current apps in dock:"
    printf "  %s\n" $current_apps
    
    # Verify each expected app is present
    local missing_apps=()
    for app in "${expected_apps[@]}"; do
        if [[ ! $current_apps =~ $app ]]; then
            missing_apps+=("$app")
        fi
    done
    
    if [ ${#missing_apps[@]} -eq 0 ]; then
        echo "✅ All expected applications are present in the dock"
    else
        echo "❌ Missing applications in the dock:"
        printf "  %s\n" "${missing_apps[@]}"
        return 1
    fi
    
    # Verify no extra apps are present
    local extra_apps=()
    for app in $current_apps; do
        if [[ ! " ${expected_apps[*]} " =~ " $app " ]]; then
            extra_apps+=("$app")
        fi
    done
    
    if [ ${#extra_apps[@]} -eq 0 ]; then
        echo "✅ No extra applications in the dock"
    else
        echo "❌ Extra applications in the dock:"
        printf "  %s\n" "${extra_apps[@]}"
        return 1
    fi
    
    return 0
}

# Function to verify snap package installation
verify_snap() {
    if ! snap list | grep -q "$1"; then
        echo "Warning: Snap package $1 is not installed"
        return 1
    fi
    return 0
}

# Function to verify tool version
verify_tool_version() {
    if ! command -v "$1" &> /dev/null; then
        echo "Warning: $1 is not installed"
        return 1
    fi
    version=$($1 --version 2>/dev/null || echo "Unknown")
    echo "$1 version: $version"
    return 0
}

# Function to install a package if missing
install_package() {
    if ! verify_package "$1"; then
        echo "Installing $1..."
        if ! sudo apt-get install -y "$1"; then
            echo "Error: Failed to install $1"
            exit 1
        fi
    fi
}

# Function to install a snap package if missing
install_snap() {
    if ! verify_snap "$1"; then
        echo "Installing snap package $1..."
        if ! sudo snap install "$1" --classic 2>/dev/null; then
            echo "Warning: Failed to install snap package $1"
        fi
    fi
}

# Function to check system prerequisites and install missing ones
check_system_prerequisites() {
    echo_header "Checking System Prerequisites"
    
    # Check essential system tools
    for tool in apt apt-get sudo dpkg; do
        if ! check_command "$tool"; then
            echo "Error: Essential system tool $tool is missing"
            exit 1
        fi
    done
    
    # Check SSH tools and install if missing
    for tool in openssh-client openssh-server; do
        install_package "$tool"
    done
    
    # Check basic utilities and install if missing
    for tool in xclip; do
        install_package "$tool"
    done
    
    # Install other required packages
    install_package "ubuntu-restricted-extras"
    install_package "curl"
    install_package "wget"
    
    # Verify installations
    echo_header "Verifying Prerequisites"
    for tool in ssh-keygen ssh ssh-agent xclip; do
        if ! check_command "$tool"; then
            echo "Warning: $tool is still missing after installation attempt"
        fi
    done
    
    echo "System prerequisites check and installation completed"
}
