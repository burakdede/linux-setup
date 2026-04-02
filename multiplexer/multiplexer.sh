#!/usr/bin/env bash
# Tmux multiplexer setup.
#
# tmux is already listed in system/apt-packages.txt and installed by system.sh.
# This script ensures the XDG-compatible config directory exists so that
# ~/.config/tmux/tmux.conf (installed by dotfiles.sh) is picked up correctly.
#
# tmux 3.1+ reads ~/.config/tmux/tmux.conf when XDG_CONFIG_HOME is set, or
# when ~/.tmux.conf is absent.  We create a compatibility shim for older tmux.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../utils/utils.sh"

trap 'handle_error $? $LINENO' ERR

ensure_tmux_config() {
    echo_header "Tmux"

    if ! command_exists tmux; then
        log_warn "tmux is not installed. Run the system step first."
        return 0
    fi

    local version
    version="$(tmux -V | awk '{print $2}')"
    log_info "tmux version: $version"

    local config_dir="$HOME/.config/tmux"
    mkdir -p "$config_dir"

    # Create a shim ~/.tmux.conf for tmux < 3.1 that just sources the XDG path.
    local shim="$HOME/.tmux.conf"
    local xdg_conf="$config_dir/tmux.conf"
    local shim_line="source-file $xdg_conf"

    if [[ ! -f "$shim" ]]; then
        printf '%s\n' "$shim_line" > "$shim"
        log_info "Created ~/.tmux.conf shim pointing to $xdg_conf"
    else
        if ! grep -Fq "$shim_line" "$shim"; then
            log_info "~/.tmux.conf already exists; not overwriting."
        fi
    fi

    # Install TPM (Tmux Plugin Manager) if git is available
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$tpm_dir" ]] && command_exists git; then
        log_info "Installing TPM (Tmux Plugin Manager)..."
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
        log_success "TPM installed at $tpm_dir"
        log_info "Press <prefix> + I inside tmux to install configured plugins."
    elif [[ -d "$tpm_dir" ]]; then
        log_info "TPM is already installed."
    fi

    log_success "Tmux config: $xdg_conf"
}

main() {
    check_root
    ensure_tmux_config
    echo_header "Multiplexer setup complete"
}

main
