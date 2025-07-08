#!/usr/bin/env bash
# Ubuntu System Settings Configuration Script

# Exit on error
set -e

# Directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/utils.sh"

# Backup existing settings
backup_gnome_settings

# Show backup and restore instructions
show_backup_instructions

echo_header "Configuring Ubuntu Settings"



# ========================= Configure Workspace Settings =========================
# This section sets up the multi-workspace environment with 4 workspaces
# and custom keyboard shortcuts for workspace management
echo_header "Setting up Workspaces"

# Configure workspace settings
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 5
gsettings set org.gnome.mutter workspaces-only-on-primary true
gsettings set org.gnome.desktop.wm.preferences workspace-names "['[1] Browse', '[2] Code', '[3] Terminal', '[4] Media', '[5] Other']"

# Configure workspace switching shortcuts
# Set up keyboard shortcuts for switching between workspaces and moving windows
echo "Configuring workspace switching shortcuts..."
for i in {1..5}; do
    # Ctrl + Number: Switch to workspace
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Control>$i']"
    # Ctrl + Shift + Number: Move active window to workspace
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Control><Shift>$i']"
done



# ========================= Configure GNOME Extensions =========================
echo_header "Setting up GNOME Extensions"
log_info "Installing GNOME Extension Manager and pipx..."
if ! sudo apt-get install -y gnome-shell-extension-manager pipx; then
    log_warn "Failed to install GNOME extension dependencies. Skipping extension setup."
    return
fi

log_info "Installing gnome-extensions-cli with pipx..."
pipx install gnome-extensions-cli --force
pipx ensurepath

# Add gext to the current shell's PATH to ensure it's found
export PATH="$PATH:$HOME/.local/bin"
source ~/.bashrc

# First disable all extensions
# Default Ubuntu extensions
gext disable tiling-assistant@ubuntu.com || true
gext disable ubuntu-appindicators@ubuntu.com || true
gext disable ubuntu-dock@ubuntu.com || true
gext disable ding@rastersoft.com || true

# Custom extensions
extensions_to_install=(
    "tactile@lundal.io"
    "blur-my-shell@aunetx"
    "just-perfection-desktop@just-perfection"
    "space-bar@luchrioh"
    "undecorate@sun.wxg@gmail.com"
    "tophat@fflewddur.github.io"
    "AlphabeticalAppGrid@stuarthayhurst"
)

# Disable all our custom extensions and remove their configuration
echo "Disabling and cleaning up all custom extensions..."
for ext in "${extensions_to_install[@]}"; do
    log_info "Processing cleanup for: $ext"

    # Check if the extension is installed before trying to clean it up
    if ! gext list | grep -q "^$ext$"; then
        log_warn "Extension not found, skipping cleanup."
    else
        # Disable extension
        log_info "Disabling extension..."
        gext disable "$ext" || log_warn "Failed to disable extension (already disabled or error)."

        # Remove extension directory
        extension_dir="$(eval echo ~/.local/share/gnome-shell/extensions/$ext)"
        if [ -d "$extension_dir" ]; then
            log_info "Removing extension directory: $extension_dir"
            rm -rf "$extension_dir"
        fi

        # Remove any existing configuration
        schema_name=$(echo "$ext" | sed 's/@.*//')
        log_info "Resetting gsettings schema: org.gnome.shell.extensions.$schema_name"
        gsettings reset-recursively "org.gnome.shell.extensions.$schema_name" || log_warn "No gsettings schema found to reset."

        # Remove schema if it exists in system schemas
        schema_file="/usr/share/glib-2.0/schemas/org.gnome.shell.extensions.$schema_name.gschema.xml"
        if [ -f "$schema_file" ]; then
            log_info "Removing system schema file: $schema_file"
            sudo rm -f "$schema_file"
        fi
        log_success "Cleanup complete for: $ext"
    fi
    echo ""
done

# Wait for all cleanup operations to complete
log_info "Waiting for cleanup to complete..."
sleep 2

echo ""

# Compile schemas to ensure no stale configurations remain
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/

# Install new extensions with proper error handling
for ext in "${extensions_to_install[@]}"; do
    log_info "Installing extension: $ext"
    
    # Install the extension
    if ! gext install "$ext"; then
        log_warn "Failed to install $ext"
        continue
    fi
    
    # Wait for installation to complete
    sleep 2
    
    # Enable the extension
    if ! gext enable "$ext"; then
        log_warn "Failed to enable $ext"
        continue
    fi
    
    # Wait for enable to complete
    sleep 2
    
    log_success "Successfully installed and enabled: $ext"
done

# Wait for extensions to be fully installed and loaded
log_info "Waiting for extensions to be fully installed and loaded..."

# Create schemas directory if it doesn't exist
sudo mkdir -p /usr/share/glib-2.0/schemas

# First, create schemas directory if it doesn't exist
sudo mkdir -p /usr/share/glib-2.0/schemas

# Copy schema files from each extension
for ext in "${extensions_to_install[@]}"; do
    extension_dir=~/.local/share/gnome-shell/extensions/$ext
    if [ -d "$extension_dir" ]; then
        log_info "Processing extension $ext..."
        
        # First try schemas subdirectory
        schema_dir="$extension_dir/schemas"
        if [ -d "$schema_dir" ]; then
            log_info "Found schemas directory: $schema_dir"
            # Copy all .gschema.xml files from schemas directory
            sudo cp -v "$schema_dir"/*.gschema.xml /usr/share/glib-2.0/schemas/ 2>/dev/null || true
            
            # Check if any files were copied
            if [ $? -eq 0 ]; then
                log_success "Successfully copied schema files from $schema_dir"
            else
                log_warn "Warning: No schema files found in $schema_dir"
            fi
        else
            log_info "No schemas directory found for $ext"
            
            # As a fallback, check root of extension directory
            schema_file="$extension_dir/org.gnome.shell.extensions.$(echo $ext | sed 's/@.*//').gschema.xml"
            if [ -f "$schema_file" ]; then
                log_info "Found schema file: $schema_file"
                sudo cp -v "$schema_file" /usr/share/glib-2.0/schemas/
            else
                log_warn "Warning: No schema file found for $ext"
            fi
        fi
    else
        log_warn "Warning: Extension directory not found: $extension_dir"
    fi
done

# Set proper permissions
sudo chown root:root /usr/share/glib-2.0/schemas/*
sudo chmod 644 /usr/share/glib-2.0/schemas/*

# Compile all schemas
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
sleep 2

# Configure Tactile
gsettings set org.gnome.shell.extensions.tactile col-0 1
gsettings set org.gnome.shell.extensions.tactile col-1 2
gsettings set org.gnome.shell.extensions.tactile col-2 1
gsettings set org.gnome.shell.extensions.tactile col-3 0
gsettings set org.gnome.shell.extensions.tactile row-0 1
gsettings set org.gnome.shell.extensions.tactile row-1 1
gsettings set org.gnome.shell.extensions.tactile gap-size 32

# Configure Just Perfection
gsettings set org.gnome.shell.extensions.just-perfection animation 2
gsettings set org.gnome.shell.extensions.just-perfection dash-app-running true
gsettings set org.gnome.shell.extensions.just-perfection workspace true
gsettings set org.gnome.shell.extensions.just-perfection workspace-popup false

# Configure Blur My Shell
gsettings set org.gnome.shell.extensions.blur-my-shell.appfolder blur false
gsettings set org.gnome.shell.extensions.blur-my-shell.lockscreen blur false
gsettings set org.gnome.shell.extensions.blur-my-shell.screenshot blur false
gsettings set org.gnome.shell.extensions.blur-my-shell.window-list blur false
gsettings set org.gnome.shell.extensions.blur-my-shell.panel blur false
gsettings set org.gnome.shell.extensions.blur-my-shell.overview blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.overview pipeline 'pipeline_default'
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock brightness 0.6
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock sigma 30
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock static-blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock style-dash-to-dock 0

# Configure Space Bar
gsettings set org.gnome.shell.extensions.space-bar.behavior smart-workspace-names false
gsettings set org.gnome.shell.extensions.space-bar.shortcuts enable-activate-workspace-shortcuts false
gsettings set org.gnome.shell.extensions.space-bar.shortcuts enable-move-to-workspace-shortcuts true
gsettings set org.gnome.shell.extensions.space-bar.shortcuts open-menu "@as []"

# Configure TopHat
gsettings set org.gnome.shell.extensions.tophat show-icons true
gsettings set org.gnome.shell.extensions.tophat show-cpu true
gsettings set org.gnome.shell.extensions.tophat show-mem true
gsettings set org.gnome.shell.extensions.tophat show-disk true
gsettings set org.gnome.shell.extensions.tophat show-fs true
gsettings set org.gnome.shell.extensions.tophat network-usage-unit bits

# Configure AlphabeticalAppGrid
gsettings set org.gnome.shell.extensions.alphabetical-app-grid folder-order-position 'end'


# ========================= Configure window manager preferences =========================
echo_header "Configuring window manager preferences..."
# Configure workspace visibility in app switcher and window switcher
gsettings set org.gnome.shell.app-switcher current-workspace-only false
gsettings set org.gnome.shell.window-switcher current-workspace-only false
# Click-to-focus mode (alternative to hover)
gsettings set org.gnome.desktop.wm.preferences focus-mode 'click'
# Raise window when clicked
gsettings set org.gnome.desktop.wm.preferences raise-on-click true
# Disable auto-raise (window raising when mouse hovers)
gsettings set org.gnome.desktop.wm.preferences auto-raise false
# Disable audible bell (beep sound)
gsettings set org.gnome.desktop.wm.preferences audible-bell false

# ========================= Configure Keyboard Shortcuts =========================
echo_header "Configuring keyboard shortcuts..."
# Set Alt+Q to close window
gsettings set org.gnome.desktop.wm.keybindings close "['<Alt>q']"

echo_header "Configuring window management shortcuts..."


# Configure Tiling Assistant shortcuts (if extension is installed)
if gnome-extensions list | grep -q "tiling-assistant"; then
    log_info "Configuring Tiling Assistant shortcuts..."

    # Ensure tiling is enabled
    gsettings set org.gnome.mutter edge-tiling true      


    # Disable GNOME's built-in tiling and maximize shortcuts to prevent conflicts with Tiling Assistant
    gsettings set org.gnome.desktop.wm.keybindings move-to-side-w "['disabled']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-side-e "['disabled']"
    gsettings set org.gnome.desktop.wm.keybindings maximize "['disabled']"
    gsettings set org.gnome.desktop.wm.keybindings unmaximize "['disabled']"

    # Window Management
    gsettings set org.gnome.shell.extensions.tiling-assistant tile-maximize "['<Super>Up']"
    gsettings set org.gnome.shell.extensions.tiling-assistant restore-window "['<Super>Down']"
    
    # Tiling Shortcuts
    gsettings set org.gnome.shell.extensions.tiling-assistant tile-left-half "['<Super>Left']"
    gsettings set org.gnome.shell.extensions.tiling-assistant tile-right-half "['<Super>Right']"

    gsettings set org.gnome.shell.extensions.tiling-assistant tile-top-half "['<Super><Shift>Up']"
    gsettings set org.gnome.shell.extensions.tiling-assistant tile-bottom-half "['<Super><Shift>Down']"
    
    # Quarter Tiling
    gsettings set org.gnome.shell.extensions.tiling-assistant tile-topleft-quarter "['<Super><Control>Left']"
    gsettings set org.gnome.shell.extensions.tiling-assistant tile-topright-quarter "['<Super><Control>Right']"
    gsettings set org.gnome.shell.extensions.tiling-assistant tile-bottomleft-quarter "['<Super><Control><Shift>Left']"
    gsettings set org.gnome.shell.extensions.tiling-assistant tile-bottomright-quarter "['<Super><Control><Shift>Right']"
    
    # Additional Tiling Assistant Settings
    gsettings set org.gnome.shell.extensions.tiling-assistant enable-tiling-popup true
    gsettings set org.gnome.shell.extensions.tiling-assistant window-gap 5
    gsettings set org.gnome.shell.extensions.tiling-assistant single-screen-gap 5
    
else
    log_warn "Tiling Assistant extension not found. Using default GNOME tiling."
    # Fallback to GNOME's built-in tiling if Tiling Assistant is not installed
    gsettings set org.gnome.desktop.wm.keybindings move-to-side-w "['<Super>Left']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-side-e "['<Super>Right']"
    gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"
    gsettings set org.gnome.desktop.wm.keybindings unmaximize "['<Super>Down']"
fi


# Disable recursive search in Files (nautilus)
gsettings set org.gnome.nautilus.preferences recursive-search 'never'

# ========================= Configure overview shortcuts =========================
echo_header "Configuring overview shortcuts..."
# F2: Toggle overview
gsettings set org.gnome.shell.keybindings toggle-overview "['F2']"
# Super+a: Toggle application view
gsettings set org.gnome.shell.keybindings toggle-application-view "['<Super>a']"
# Super+v: Toggle message tray
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>v']"

# ========================= Configure Dock Settings =========================
echo_header "Configuring Dock Settings"
# Configure dock appearance and behavior
log_info "Configuring dock settings..."
# Set Dock to bottom of the screen
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM
# Auto-hide dock
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
# Set icon size to 32
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
# Show on primary display only
gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor false
# Show applications at top of dock
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
# Show favorite applications in dock
gsettings set org.gnome.shell.extensions.dash-to-dock show-favorites true
# Show running applications even if not pinned
gsettings set org.gnome.shell.extensions.dash-to-dock show-running true
# Show mounted drives in dock
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts true
# Configure auto-hide behavior
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
# Set hide delay (in seconds)
gsettings set org.gnome.shell.extensions.dash-to-dock hide-delay 0.2
# Set running indicator style
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS'
# Set background opacity
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.5
# Set transparency mode
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
# Set dock not to extend height
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false

# ========================= Screenshot and Recording =========================
echo_header "Screenshot and recording shortcuts..."
# Screenshot Interactively (Shift+Alt+4)
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Alt>4']"
# Screenshot Window (Shift+Alt+3)
gsettings set org.gnome.shell.keybindings screenshot-window "['<Shift><Alt>3']"
# Screenshot (Shift+Alt+2)
gsettings set org.gnome.shell.keybindings screenshot "['<Shift><Alt>2']"
# Screenrecord (Shift+Alt+5)
gsettings set org.gnome.shell.keybindings show-screen-recording-ui "['<Shift><Alt>5']"

# ========================= Dock Favorites =========================
echo_header "Configuring Dock Favorites"

# Define system apps that should always be in the dock
SYSTEM_APPS=(
    'google-chrome.desktop'
    'firefox_firefox.desktop'
    'code.desktop'
    'slack_slack.desktop'
    'discord_discord.desktop'
    'spotify_spotify.desktop'
    'obsidian_obsidian.desktop'
    'windsurf.desktop'
    'cursor.desktop'
    'localsend_localsend.desktop'
    'jetbrains-toolbox.desktop'
    'obs-studio_obs-studio.desktop'
    'steam_steam.desktop'
    'org.gnome.Nautilus.desktop'
    'org.gnome.Terminal.desktop'
    'org.gnome.Settings.desktop'
)

# Source the web apps configuration if available
WEBAPPS_CONFIG="$(dirname "$0")/../web2app/config.sh"
if [ -f "$WEBAPPS_CONFIG" ]; then
    source "$WEBAPPS_CONFIG"
    
    # Add web apps from config if they exist
    for app in "${!WEB_APPS[@]}"; do
        desktop_file="$app.desktop"
        if [ -f "$HOME/.local/share/applications/$desktop_file" ]; then
            SYSTEM_APPS+=("$desktop_file")
            log_info "Adding web app to favorites: $app"
        fi
    done
else
    log_warn "Web apps configuration not found at $WEBAPPS_CONFIG"
fi

# Get current favorites to preserve any manually added apps
CURRENT_FAVORITES=$(gsettings get org.gnome.shell favorite-apps | tr -d '[]' | tr ',' '\n' | tr -d "' " | grep -v '^$')

# Merge with system apps, removing duplicates
ALL_FAVORITES=("${SYSTEM_APPS[@]}")
while IFS= read -r fav; do
    # Only keep manually added favorites that aren't in our system apps
    # and aren't web apps (we handle those above)
    if [[ ! " ${SYSTEM_APPS[*]} " =~ " ${fav} " ]] && 
       [[ ! "$fav" =~ ^(WhatsApp|GMail|GCal|ChatGPT|Claude|Gemini|Grok)\.desktop$ ]]; then
        ALL_FAVORITES+=("$fav")
        log_info "Preserving manually added favorite: $fav"
    fi
done <<< "$CURRENT_FAVORITES"

# Convert array to gsettings format
FAVORITES="$(printf "'%s'," "${ALL_FAVORITES[@]}" | sed 's/,$//')"

# Set the favorites
log_info "Updating dock favorites..."
gsettings set org.gnome.shell favorite-apps "[${FAVORITES}]"

# ========================= Final System Settings =========================
# Set final system-wide settings
log_info "Configuring final system settings..."
# Disable animations for better performance
gsettings set org.gnome.desktop.interface enable-animations false
# Show date in clock
gsettings set org.gnome.desktop.interface clock-show-date true
# Show weekday in clock
gsettings set org.gnome.desktop.interface clock-show-weekday true
# set dark mode by default
gsettings set org.gnome.desktop.interface color-scheme prefer-dark


# ========================= Window & Terminal Behavior =========================
echo_header "Configuring window behavior..."
# Center new windows when launched
gsettings set org.gnome.mutter center-new-windows true
# Configure terminal shortcut
log_info "Configuring terminal shortcut..."
# Set Ctrl+Alt+T as default terminal shortcut
gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Primary><Alt>t']"


log_success "Ubuntu settings configuration completed successfully!"
