#!/usr/bin/env bash
# Zsh installation and default shell configuration.
#
# Installs zsh from APT, changes the login shell to zsh for the current user,
# and ensures the dotfile scaffolds (.zshrc, .zshenv, .zprofile) are wired up.

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

install_zsh() {
    echo_header "Zsh"

    if command_exists zsh; then
        log_info "zsh is already installed."
    else
        log_info "Installing zsh..."
        sudo_run apt-get update
        sudo_run apt-get install -y --no-install-recommends zsh
        log_success "zsh installed."
    fi
}

set_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh 2>/dev/null || true)"

    if [[ -z "$zsh_path" ]]; then
        log_warn "zsh binary not found; cannot set as default shell."
        return 0
    fi

    # Register zsh in /etc/shells if it isn't already there
    if ! grep -Fqx "$zsh_path" /etc/shells; then
        log_info "Adding $zsh_path to /etc/shells..."
        echo "$zsh_path" | sudo_run tee -a /etc/shells >/dev/null
    fi

    local current_shell
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"

    if [[ "$current_shell" == "$zsh_path" ]]; then
        log_info "Default shell is already $zsh_path."
        return 0
    fi

    # chsh is interactive when called directly; use usermod if available
    if command_exists usermod; then
        sudo_run usermod --shell "$zsh_path" "$USER"
        log_success "Default shell changed to $zsh_path (effective after next login)."
    elif command_exists chsh; then
        chsh -s "$zsh_path"
        log_success "Default shell changed to $zsh_path (effective after next login)."
    else
        log_warn "Neither usermod nor chsh found; cannot change default shell automatically."
        log_info "Run: chsh -s $zsh_path"
    fi
}

wire_mise_activation() {
    # Ensure mise is activated inside zsh sessions too.
    local mise_line
    # shellcheck disable=SC2016
    mise_line='eval "$("$HOME/.local/bin/mise" activate zsh)"'
    ensure_line_in_file "$mise_line" "$HOME/.zshrc"
    log_success "mise activation wired into ~/.zshrc"
}

main() {
    check_root
    export PATH="$HOME/.local/bin:$PATH"

    install_zsh
    set_default_shell
    wire_mise_activation

    echo_header "Shell setup complete"
    log_success "zsh is installed and set as the default shell."
    log_info "Configs: ~/.zshrc  ~/.zshenv  ~/.zprofile"
    log_info "Log out and back in (or start a new session) for the shell change to take effect."
}

main
