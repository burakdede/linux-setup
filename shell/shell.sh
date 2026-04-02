#!/usr/bin/env bash
# Zsh installation and default shell configuration.
#
# Installs zsh from APT (idempotent), changes the login shell to zsh for the
# current user, and ensures mise activation is wired into ~/.zshrc.
#
# Safe to re-run: every step is guarded by a prior state check.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../utils/utils.sh"

trap 'handle_error $? $LINENO' ERR

install_zsh() {
    echo_header "Zsh"

    if command_exists zsh; then
        log_info "zsh is already installed ($(zsh --version 2>/dev/null | head -n1))."
        return 0
    fi

    log_info "Installing zsh..."
    sudo_run apt-get install -y --no-install-recommends zsh
    log_success "zsh installed."
}

set_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh 2>/dev/null || true)"

    if [[ -z "$zsh_path" ]]; then
        log_warn "zsh binary not found; cannot set as default shell."
        return 0
    fi

    # Register zsh in /etc/shells if missing
    if ! grep -Fqx "$zsh_path" /etc/shells 2>/dev/null; then
        log_info "Adding $zsh_path to /etc/shells..."
        printf '%s\n' "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # Check current shell — skip if already correct
    local current_shell
    current_shell="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || true)"

    if [[ "$current_shell" == "$zsh_path" ]]; then
        log_info "Default shell is already $zsh_path."
        return 0
    fi

    if command_exists usermod; then
        sudo_run usermod --shell "$zsh_path" "$USER"
        log_success "Default shell changed to $zsh_path (effective after next login)."
    elif command_exists chsh; then
        chsh -s "$zsh_path"
        log_success "Default shell changed to $zsh_path (effective after next login)."
    else
        log_warn "Neither usermod nor chsh found; set default shell manually:"
        log_info "  chsh -s $zsh_path"
    fi
}

wire_mise_activation() {
    # shellcheck disable=SC2016
    local mise_line='eval "$("$HOME/.local/bin/mise" activate zsh)"'
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
    log_info "Log out and back in (or start a new session) for the change to take effect."
}

main
