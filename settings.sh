#!/usr/bin/env bash
# Ubuntu System Settings Configuration Script

# Exit on error
set -e

# Source common functions
source "utils.sh"

echo_header "Configuring Ubuntu Settings"

echo_header "Setting up Workspaces"
# Set number of workspaces
gsettings set org.gnome.desktop.wm.preferences num-workspaces 4

# Configure workspace switching shortcuts
echo "Configuring workspace switching shortcuts..."
for i in {1..4}; do
    # Set Ctrl + Number to switch to workspace
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Control>$i']"
    # Set Ctrl + Shift + Number to move window to workspace
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Control><Shift>$i']"
done

# Configure keyboard repeat settings
echo "Configuring keyboard repeat settings..."
# Set repeat delay to 250ms (default is 500ms)
gsettings set org.gnome.desktop.peripherals.keyboard repeat-delay 250
# Set repeat interval to 30ms (default is 30ms)
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 30
# Enable keyboard repeat
gsettings set org.gnome.desktop.peripherals.keyboard repeat true

# Configure hot corners
echo "Configuring hot corners..."
# Enable hot corners
gsettings set org.gnome.shell enabled-extensions "['hot-corners@gnome-shell-extensions.gcampax.github.com']"
# Set top-left corner to show overview
gsettings set org.gnome.shell.extensions.hot-corners hot-corners "['top-left']"
# Configure top-left corner action
gsettings set org.gnome.shell.extensions.hot-corners corner-action-0 "overview"

echo_header "Configuring Other Settings"

# Configure dock settings
echo "Configuring dock settings..."
# Configure dock appearance
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
gsettings set org.gnome.shell.extensions.dash-to-dock show-favorites false
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
# Configure auto-hide
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings set org.gnome.shell.extensions.dash-to-dock autohide-sensitivity 20

echo_header "Final Settings"
# Set some additional settings
gsettings set org.gnome.desktop.interface enable-animations false
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

# Configure screenshot settings
echo_header "Configuring Screenshot Settings"
# Set Alt+Shift+4 for area screenshot to clipboard
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot-clip "['<Alt><Shift>4']"
# Disable default screenshot shortcuts
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['']"
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot "['']"

# Configure workspace assignments
echo_header "Configuring Workspace Assignments"

# To add a new application to a workspace:
# 1. Find the window class name using: xprop WM_CLASS
# 2. Add the window class to window_classes array with its name
# 3. Add the workspace assignment to workspace_assignments array

# Format for window_classes:
# window_classes["command-name"]="Window Class Name"
# Format for workspace_assignments:
# workspace_assignments["command-name"]="workspace-number"

# The workspace numbers are:
# 1 = Leftmost workspace
# 2 = Second workspace
# 3 = Third workspace
# 4 = Rightmost workspace

# Workspace 1: Browsing
window_classes["firefox"]="Firefox"
window_classes["google-chrome"]="Google-chrome"
workspace_assignments["firefox"]="1"
workspace_assignments["google-chrome"]="1"

# Workspace 2: Coding
# Note: JetBrains Toolbox will float on all workspaces
window_classes["code"]="Code"
window_classes["intellij-idea-community"]="IntelliJ IDEA Community Edition"
window_classes["pycharm-community"]="PyCharm Community Edition"
window_classes["datagrip"]="DataGrip"
window_classes["postman"]="Postman"
workspace_assignments["code"]="2"
workspace_assignments["intellij-idea-community"]="2"
workspace_assignments["pycharm-community"]="2"
workspace_assignments["datagrip"]="2"
workspace_assignments["postman"]="2"

# Workspace 3: Terminal
window_classes["gnome-terminal"]="Terminal"
workspace_assignments["gnome-terminal"]="3"

# Workspace 4: Media
window_classes["vlc"]="VLC media player"
window_classes["obs"]="OBS Studio"
window_classes["steam"]="Steam"
window_classes["spotify"]="Spotify"
window_classes["slack"]="Slack"
window_classes["discord"]="Discord"
workspace_assignments["vlc"]="4"
workspace_assignments["obs"]="4"
workspace_assignments["steam"]="4"
workspace_assignments["spotify"]="4"
workspace_assignments["slack"]="4"
workspace_assignments["discord"]="4"


# Apply workspace assignments
for window_class in "${!window_classes[@]}"; do
    if [ -n "${workspace_assignments[$window_class]}" ]; then
        echo "Assigning ${window_classes[$window_class]} to workspace ${workspace_assignments[$window_class]}"
        gsettings set org.gnome.shell.window-placement "window-classes" "{'${window_classes[$window_class]}': ${workspace_assignments[$window_class]}}"
    fi
done

# Function to verify workspace assignments
verify_workspace_assignment() {
    local app_name="$1"
    local expected_workspace="$2"
    
    # Get current workspace assignments
    local current_assignments=$(gsettings get org.gnome.shell.window-placement window-classes)
    
    # Check if the assignment exists
    if echo "$current_assignments" | grep -q "${app_name}: ${expected_workspace}"; then
        echo "✓ $app_name is correctly assigned to workspace $expected_workspace"
    else
        echo "✗ Warning: $app_name is not assigned to workspace $expected_workspace"
        echo "Current assignments: $current_assignments"
    fi
}

# Verify workspace assignments
echo_header "Verifying Workspace Assignments"
for window_class in "${!window_classes[@]}"; do
    if [ -n "${workspace_assignments[$window_class]}" ]; then
        verify_workspace_assignment "${window_classes[$window_class]}" "${workspace_assignments[$window_class]}"
    fi
done

echo "Ubuntu settings configuration completed successfully!"

# Manual Installation Notes:
# 1. GNOME Extensions to install manually:
#    - Tactile (Tile windows): https://extensions.gnome.org/extension/4548/tactile/
#    - Space Bar (Workspace naming and enumeration): https://extensions.gnome.org/extension/5090/space-bar/
#    - Alphabetic App Grid - https://extensions.gnome.org/extension/4269/alphabetical-app-grid/
#    
# 2. To install any extension:
#    - Visit the extension's page on https://extensions.gnome.org/
#    - Click the "ON/OFF" switch to install
#    - Enable the extension in GNOME Tweaks if needed
#    
# 3. After installation:
#    - Some extensions may require GNOME Shell restart
#    - Use GNOME Tweaks to configure extension settings
