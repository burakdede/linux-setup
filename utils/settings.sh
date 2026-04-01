#!/usr/bin/env bash
# Ubuntu System Settings Configuration Script

set -euo pipefail

# Directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
# shellcheck source=/dev/null
source "$SCRIPT_DIR/utils.sh"

trap 'handle_error $? $LINENO' ERR

array_contains() {
    local needle="$1"
    shift

    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done

    return 1
}

# Map extension IDs to their actual gsettings schema names (where they differ from
# the part before @, which is the naive default used in cleanup).
extension_schema_name() {
    local ext="$1"
    case "$ext" in
        just-perfection-desktop@just-perfection) echo "just-perfection" ;;
        AlphabeticalAppGrid@stuarthayhurst)      echo "alphabetical-app-grid" ;;
        *)                                        echo "${ext%@*}" ;;
    esac
}

# Wait until a gsettings schema becomes readable, or time out.
wait_for_schema() {
    local schema="$1"
    local attempts=0
    while ! gsettings list-keys "$schema" &>/dev/null; do
        (( attempts++ ))
        if (( attempts >= 20 )); then
            log_warn "Schema $schema not available after 20 seconds — skipping."
            return 1
        fi
        sleep 1
    done
    return 0
}

configure_gnome_extensions() {
    # ========================= Configure GNOME Extensions =========================
    echo_header "Setting up GNOME Extensions"
    log_info "Installing GNOME Extension Manager and pipx..."
    if ! sudo apt-get install -y gnome-shell-extension-manager pipx; then
        log_warn "Failed to install GNOME extension dependencies. Skipping extension setup."
        return 0
    fi

    log_info "Installing gnome-extensions-cli with pipx..."
    pipx install gnome-extensions-cli --force
    pipx ensurepath

    export PATH="$PATH:$HOME/.local/bin"

    gext disable tiling-assistant@ubuntu.com || true
    gext disable ubuntu-appindicators@ubuntu.com || true
    gext disable ubuntu-dock@ubuntu.com || true
    gext disable ding@rastersoft.com || true

    local extensions_to_install=(
        "tactile@lundal.io"
        "blur-my-shell@aunetx"
        "just-perfection-desktop@just-perfection"
        "space-bar@luchrioh"
        "undecorate@sun.wxg@gmail.com"
        "tophat@fflewddur.github.io"
        "AlphabeticalAppGrid@stuarthayhurst"
    )

    echo "Disabling and cleaning up all custom extensions..."
    local ext extension_dir schema_name schema_file schema_dir
    for ext in "${extensions_to_install[@]}"; do
        log_info "Processing cleanup for: $ext"

        if ! gext list | grep -q "^$ext$"; then
            log_warn "Extension not found, skipping cleanup."
        else
            log_info "Disabling extension..."
            gext disable "$ext" || log_warn "Failed to disable extension (already disabled or error)."

            extension_dir="$HOME/.local/share/gnome-shell/extensions/$ext"
            if [ -d "$extension_dir" ]; then
                log_info "Removing extension directory: $extension_dir"
                rm -rf "$extension_dir"
            fi

            schema_name="$(extension_schema_name "$ext")"
            log_info "Resetting gsettings schema: org.gnome.shell.extensions.$schema_name"
            gsettings reset-recursively "org.gnome.shell.extensions.$schema_name" || log_warn "No gsettings schema found to reset."
            log_success "Cleanup complete for: $ext"
        fi
        echo ""
    done

    log_info "Waiting for cleanup to complete..."
    sleep 2
    echo ""
    sudo glib-compile-schemas /usr/share/glib-2.0/schemas/

    for ext in "${extensions_to_install[@]}"; do
        log_info "Installing extension: $ext"

        if ! gext install "$ext"; then
            log_warn "Failed to install $ext"
            continue
        fi

        sleep 2

        if ! gext enable "$ext"; then
            log_warn "Failed to enable $ext"
            continue
        fi

        sleep 2
        log_success "Successfully installed and enabled: $ext"
    done

    # gext installs schemas into the extension directory under ~/.local — GNOME Shell
    # reads them from there directly. No need to copy to /usr/share or recompile
    # system schemas. Schema availability is checked per-extension before gsettings
    # calls via wait_for_schema below.
    log_info "Extensions installed and enabled."
}

if ! has_desktop_session || ! command_exists gsettings; then
    log_warn "Skipping GNOME settings because no desktop session is active."
    exit 0
fi

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
    gsettings set "org.gnome.desktop.wm.keybindings" "switch-to-workspace-$i" "['<Control>$i']"
    # Ctrl + Shift + Number: Move active window to workspace
    gsettings set "org.gnome.desktop.wm.keybindings" "move-to-workspace-$i" "['<Control><Shift>$i']"
done

configure_gnome_extensions

# Configure Tactile
if wait_for_schema org.gnome.shell.extensions.tactile; then
    gsettings set org.gnome.shell.extensions.tactile col-0 1
    gsettings set org.gnome.shell.extensions.tactile col-1 2
    gsettings set org.gnome.shell.extensions.tactile col-2 1
    gsettings set org.gnome.shell.extensions.tactile col-3 0
    gsettings set org.gnome.shell.extensions.tactile row-0 1
    gsettings set org.gnome.shell.extensions.tactile row-1 1
    gsettings set org.gnome.shell.extensions.tactile gap-size 32
fi

# Configure Just Perfection
if wait_for_schema org.gnome.shell.extensions.just-perfection; then
    gsettings set org.gnome.shell.extensions.just-perfection animation 2
    gsettings set org.gnome.shell.extensions.just-perfection dash-app-running true
    gsettings set org.gnome.shell.extensions.just-perfection workspace true
    gsettings set org.gnome.shell.extensions.just-perfection workspace-popup false
fi

# Configure Blur My Shell
if wait_for_schema org.gnome.shell.extensions.blur-my-shell; then
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
fi

# Configure Space Bar
if wait_for_schema org.gnome.shell.extensions.space-bar; then
    gsettings set org.gnome.shell.extensions.space-bar.behavior smart-workspace-names false
    gsettings set org.gnome.shell.extensions.space-bar.shortcuts enable-activate-workspace-shortcuts false
    gsettings set org.gnome.shell.extensions.space-bar.shortcuts enable-move-to-workspace-shortcuts true
    gsettings set org.gnome.shell.extensions.space-bar.shortcuts open-menu "@as []"
fi

# Configure TopHat
if wait_for_schema org.gnome.shell.extensions.tophat; then
    gsettings set org.gnome.shell.extensions.tophat show-icons true
    gsettings set org.gnome.shell.extensions.tophat show-cpu true
    gsettings set org.gnome.shell.extensions.tophat show-mem true
    gsettings set org.gnome.shell.extensions.tophat show-disk true
    gsettings set org.gnome.shell.extensions.tophat network-usage-unit bits
fi

# Configure AlphabeticalAppGrid
if wait_for_schema org.gnome.shell.extensions.alphabetical-app-grid; then
    gsettings set org.gnome.shell.extensions.alphabetical-app-grid folder-order-position 'end'
fi


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


# GNOME built-in tiling keybindings (tiling-assistant@ubuntu.com removed from repos;
# Tactile handles grid tiling via its own gsettings above)
gsettings set org.gnome.mutter edge-tiling true
gsettings set org.gnome.desktop.wm.keybindings move-to-side-w "['<Super>Left']"
gsettings set org.gnome.desktop.wm.keybindings move-to-side-e "['<Super>Right']"
gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"
gsettings set org.gnome.desktop.wm.keybindings unmaximize "['<Super>Down']"


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
gsettings set org.gnome.shell.extensions.ubuntu-dock dock-position BOTTOM
# Auto-hide dock
gsettings set org.gnome.shell.extensions.ubuntu-dock dock-fixed false
# Set icon size to 32
gsettings set org.gnome.shell.extensions.ubuntu-dock dash-max-icon-size 32
# Show on primary display only
gsettings set org.gnome.shell.extensions.ubuntu-dock multi-monitor false
# Show applications at top of dock
gsettings set org.gnome.shell.extensions.ubuntu-dock show-apps-at-top true
# Show favorite applications in dock
gsettings set org.gnome.shell.extensions.ubuntu-dock show-favorites true
# Show running applications even if not pinned
gsettings set org.gnome.shell.extensions.ubuntu-dock show-running true
# Show mounted drives in dock
gsettings set org.gnome.shell.extensions.ubuntu-dock show-mounts true
# Configure auto-hide behavior
gsettings set org.gnome.shell.extensions.ubuntu-dock autohide true
# Set hide delay (in seconds)
gsettings set org.gnome.shell.extensions.ubuntu-dock hide-delay 0.2
# Set running indicator style
gsettings set org.gnome.shell.extensions.ubuntu-dock running-indicator-style 'DOTS'
# Set background opacity
gsettings set org.gnome.shell.extensions.ubuntu-dock background-opacity 0.5
# Set transparency mode
gsettings set org.gnome.shell.extensions.ubuntu-dock transparency-mode 'FIXED'
# Set dock not to extend height
gsettings set org.gnome.shell.extensions.ubuntu-dock extend-height false

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
    'obsidian_obsidian.desktop'
    'localsend_localsend.desktop'
    'obs-studio_obs-studio.desktop'
    'alacritty.desktop'
    'org.gnome.Nautilus.desktop'
    'org.gnome.Terminal.desktop'
    'org.gnome.Settings.desktop'
)

# Get current favorites to preserve any manually added apps
CURRENT_FAVORITES=$(gsettings get org.gnome.shell favorite-apps | tr -d '[]' | tr ',' '\n' | tr -d "' " | grep -v '^$')

# Merge with system apps, removing duplicates
ALL_FAVORITES=("${SYSTEM_APPS[@]}")
while IFS= read -r fav; do
    # Only keep manually added favorites that aren't in our system apps
    # and aren't web apps (we handle those above)
    if ! array_contains "$fav" "${SYSTEM_APPS[@]}"; then
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
