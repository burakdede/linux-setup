#!/usr/bin/env bash
# Ubuntu System Settings Configuration Script

# Exit on error
set -e

# Source common functions
source "utils.sh"

# Backup existing settings
backup_gnome_settings

# Show backup and restore instructions
show_backup_instructions

echo_header "Configuring Ubuntu Settings"

# Configure Workspace Settings
# This section sets up the multi-workspace environment with 4 workspaces
# and custom keyboard shortcuts for workspace management
echo_header "Setting up Workspaces"

# Set the number of workspaces to 4
gsettings set org.gnome.desktop.wm.preferences num-workspaces 4

# Configure workspace switching shortcuts
# Set up keyboard shortcuts for switching between workspaces and moving windows
echo "Configuring workspace switching shortcuts..."
for i in {1..4}; do
    # Ctrl + Number: Switch to workspace
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Control>$i']"
    # Ctrl + Shift + Number: Move active window to workspace
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Control><Shift>$i']"
done

# Configure hot corners
# Set up corner shortcuts for quick access to different views
echo "Configuring hot corners..."
# Top-left corner: Show overview (Super+Shift+Home)
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-nw "['<Super><Shift>Home']"
# Top-right corner: Show desktop (Super+Shift+End)
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-ne "['<Super><Shift>End']"
# Bottom-left corner: Show applications (Super+Shift+Prior)
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-sw "['<Super><Shift>Prior']"
# Bottom-right corner: Show notifications (Super+Shift+Next)
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-se "['<Super><Shift>Next']"

# Configure window manager preferences
# Set window behavior and focus settings
echo "Configuring window manager preferences..."
# Click-to-focus mode (alternative to hover)
gsettings set org.gnome.desktop.wm.preferences focus-mode 'click'
# Raise window when clicked
gsettings set org.gnome.desktop.wm.preferences raise-on-click true
# Disable auto-raise (window raising when mouse hovers)
gsettings set org.gnome.desktop.wm.preferences auto-raise false
# Disable audible bell (beep sound)
gsettings set org.gnome.desktop.wm.preferences audible-bell false

# Disable recursive search in Files (nautilus)
gsettings set org.gnome.nautilus.preferences recursive-search 'never'

# Configure overview shortcuts
# Set up keyboard shortcuts for accessing different views
echo "Configuring overview shortcuts..."
# Super+s: Toggle overview
gsettings set org.gnome.shell.keybindings toggle-overview "['<Super>s']"
# Super+a: Toggle application view
gsettings set org.gnome.shell.keybindings toggle-application-view "['<Super>a']"
# Super+v: Toggle message tray
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>v']"

# Configure startup applications
echo "Configuring startup applications..."

# Add startup applications
echo "Adding essential startup applications..."

# Add ULauncher
if [ -f "~/.config/autostart/ulauncher.desktop" ]; then
    echo "ULauncher already set for startup"
else
    mkdir -p ~/.config/autostart
    cat > ~/.config/autostart/ulauncher.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=ULauncher
Comment=Quick launch application
Exec=/usr/bin/ulauncher
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=ULauncher
Comment[en_US]=Quick launch application
Name[en]=ULauncher
Comment[en]=Quick launch application
Icon=ulauncher
Terminal=false
Categories=Utility;
StartupNotify=true
StartupWMClass=ulauncher
EOF
fi

# Add JetBrains Toolbox
if [ -f "~/.config/autostart/jetbrains-toolbox.desktop" ]; then
    echo "JetBrains Toolbox already set for startup"
else
    cat > ~/.config/autostart/jetbrains-toolbox.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=JetBrains Toolbox
Comment=JetBrains IDE management tool
Exec=/opt/jetbrains-toolbox/jetbrains-toolbox
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=JetBrains Toolbox
Comment[en_US]=JetBrains IDE management tool
Name[en]=JetBrains Toolbox
Comment[en]=JetBrains IDE management tool
Icon=jetbrains-toolbox
Terminal=false
Categories=Development;
StartupNotify=true
StartupWMClass=jetbrains-toolbox
EOF
fi

# Configure Dock Settings
# This section sets up the GNOME dock (Dash to Dock) with custom appearance and behavior
echo_header "Configuring Dock Settings"

# Configure dock appearance and behavior
echo "Configuring dock settings..."
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
# Show mounted drives in dock
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts true

# Configure auto-hide behavior
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
# Set hide delay (in seconds)
gsettings set org.gnome.shell.extensions.dash-to-dock hide-delay 0.2

# Clear existing dock favorites
echo "Clearing existing dock favorites..."
gsettings set org.gnome.shell favorite-apps "[]"

# Screenshot and Recording
echo "Screenshot and recording shortcuts..."
# Screenshot Interactively (Shift+Alt+4)
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Alt>4']"
# Screenshot Window (Shift+Alt+3)
gsettings set org.gnome.shell.keybindings screenshot-window "['<Shift><Alt>3']"
# Screenshot (Shift+Alt+2)
gsettings set org.gnome.shell.keybindings screenshot "['<Shift><Alt>2']"
# Screenrecord (Shift+Alt+5)
gsettings set org.gnome.shell.keybindings show-screen-recording-ui "['<Shift><Alt>5']"

# Set our predefined favorites list
echo "Setting up dock favorites..."
# Set the exact list of applications to pin to dock
gsettings set org.gnome.shell favorite-apps "['code.desktop', 'slack_slack.desktop', 'discord_discord.desktop', 'google-chrome.desktop', 'firefox_firefox.desktop', 'spotify_spotify.desktop', 'obsidian_obsidian.desktop', 'windsurf_windsurf.desktop', 'cursor_cursor.desktop', 'localsend_localsend.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'gnome-control-center_gnome-control-center.desktop']"

# Verify dock configuration
echo_header "Verifying Dock Configuration"
verify_dock_apps

echo_header "Final System Settings"
# Set final system-wide settings
echo "Configuring final system settings..."
# Disable animations for better performance
gsettings set org.gnome.desktop.interface enable-animations false
# Show date in clock
gsettings set org.gnome.desktop.interface clock-show-date true
# Show weekday in clock
gsettings set org.gnome.desktop.interface clock-show-weekday true

# Configure window behavior
# This section sets up window behavior and placement settings
echo "Configuring window behavior..."

# Center new windows when launched
gsettings set org.gnome.mutter center-new-windows true

# Configure terminal shortcut
echo "Configuring terminal shortcut..."
# Set Ctrl+Alt+T as default terminal shortcut
gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Primary><Alt>t']"

echo "Ubuntu settings configuration completed successfully!"
