#!/usr/bin/env bash
# WezTerm terminal emulator installation and configuration.
#
# Installs WezTerm from the official GitHub releases (wez/wezterm).
# Optionally sets WezTerm as the default terminal emulator when a
# GNOME desktop session is active.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../utils/utils.sh"

trap 'handle_error $? $LINENO' ERR

flag_enabled() {
    local value="${1:-0}"
    case "$value" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

should_skip_step() {
    local step_name="$1"
    local var_name="LINUX_SETUP_SKIP_${step_name}"
    flag_enabled "${!var_name:-0}"
}

upgrade_enabled() {
    flag_enabled "${LINUX_SETUP_UPGRADE:-0}"
}

install_wezterm() {
    echo_header "WezTerm terminal emulator"

    if command_exists wezterm && ! upgrade_enabled; then
        log_info "WezTerm is already installed. (set LINUX_SETUP_UPGRADE=1 to upgrade)"
        return 0
    fi

    local temp_dir metadata_file download_url deb_path
    temp_dir="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$temp_dir'" RETURN
    metadata_file="$temp_dir/release.json"

    log_info "Fetching latest WezTerm release metadata..."
    curl -fsSL "https://api.github.com/repos/wez/wezterm/releases/latest" \
        -o "$metadata_file"

    if jq -e '.message' "$metadata_file" &>/dev/null; then
        log_warn "GitHub API error: $(jq -r '.message' "$metadata_file"). Skipping WezTerm."
        return 0
    fi

    # Prefer Ubuntu 24.04 .deb; fall back to any .deb asset
    download_url="$(jq -r \
        '.assets[] | select(.name | test("Ubuntu24\\.04\\.deb$")) | .browser_download_url' \
        "$metadata_file" | head -n1)"

    if [[ -z "$download_url" || "$download_url" == "null" ]]; then
        download_url="$(jq -r \
            '.assets[] | select(.name | test("\\.deb$")) | .browser_download_url' \
            "$metadata_file" | head -n1)"
    fi

    if [[ -z "$download_url" || "$download_url" == "null" ]]; then
        log_warn "Could not find a WezTerm .deb release asset. Skipping."
        return 0
    fi

    log_info "Downloading WezTerm from: $download_url"
    deb_path="$temp_dir/wezterm.deb"
    curl -fsSL "$download_url" -o "$deb_path"
    sudo_run apt-get install -y "$deb_path"
    rm -rf "$temp_dir"
    log_success "WezTerm installed."
}

set_default_terminal() {
    if ! has_desktop_session; then
        log_info "No desktop session active; skipping default terminal configuration."
        return 0
    fi

    if ! command_exists gsettings; then
        log_info "gsettings not available; skipping default terminal configuration."
        return 0
    fi

    log_info "Setting WezTerm as the default GNOME terminal..."
    gsettings set org.gnome.desktop.default-applications.terminal exec 'wezterm'
    gsettings set org.gnome.desktop.default-applications.terminal exec-arg ''

    # Also register with update-alternatives if available
    if command_exists update-alternatives && command_exists wezterm; then
        local wezterm_path
        wezterm_path="$(command -v wezterm)"
        sudo_run update-alternatives --install /usr/bin/x-terminal-emulator \
            x-terminal-emulator "$wezterm_path" 50 || true
        sudo_run update-alternatives --set x-terminal-emulator "$wezterm_path" || true
    fi

    log_success "WezTerm set as default terminal."
}

main() {
    check_root
    export PATH="$HOME/.local/bin:$PATH"

    if ! should_skip_step WEZTERM; then
        install_wezterm
        set_default_terminal
    else
        log_info "Skipping WezTerm (LINUX_SETUP_SKIP_WEZTERM is set)."
    fi

    echo_header "Terminal setup complete"
    log_success "WezTerm is ready. Config: ~/.config/wezterm/wezterm.lua"
}

main
