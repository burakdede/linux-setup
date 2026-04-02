#!/usr/bin/env bash
# Interactive configuration step.
#
# Prompts for anything that cannot have a machine-independent default:
#   - Git identity (name + email) — written to ~/.gitconfig.local so the
#     symlinked ~/.gitconfig stays clean and uncommitted.
#
# Safe to re-run: existing values are shown as defaults; pressing Enter keeps them.
# Non-interactive environments (CI, piped stdin) are detected and skipped.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../utils/utils.sh"

trap 'handle_error $? $LINENO' ERR

LOCAL_GITCONFIG="$HOME/.gitconfig.local"

# ── Helpers ───────────────────────────────────────────────────────────────────

prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result

    if [[ -n "$default" ]]; then
        printf '%s [%s]: ' "$prompt" "$default"
    else
        printf '%s: ' "$prompt"
    fi

    read -r result
    if [[ -z "$result" ]]; then
        printf '%s' "$default"
    else
        printf '%s' "$result"
    fi
}

git_local_get() {
    git config --file "$LOCAL_GITCONFIG" "$1" 2>/dev/null || true
}

git_global_get() {
    # Read from all levels except the local override file itself to get
    # whatever is currently configured (from system .gitconfig).
    git config --global "$1" 2>/dev/null || true
}

# ── Git identity ──────────────────────────────────────────────────────────────

configure_git_identity() {
    echo_header "Git identity"

    # Current values: local override takes precedence, then global
    local current_name current_email
    current_name="$(git_local_get user.name || git_global_get user.name)"
    current_email="$(git_local_get user.email || git_global_get user.email)"

    if [[ -n "$current_name" && -n "$current_email" ]]; then
        log_info "Current git identity:"
        log_info "  name:  $current_name"
        log_info "  email: $current_email"
        printf '\nPress Enter to keep existing values, or type new ones.\n\n'
    fi

    local name email

    name="$(prompt_with_default "Full name" "$current_name")"
    if [[ -z "$name" ]]; then
        log_warn "Name cannot be empty. Skipping git identity configuration."
        return 0
    fi

    email="$(prompt_with_default "Email address" "$current_email")"
    if [[ -z "$email" ]]; then
        log_warn "Email cannot be empty. Skipping git identity configuration."
        return 0
    fi

    # Validate email format
    if [[ ! "$email" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
        log_warn "Email '$email' does not look valid. Skipping git identity configuration."
        return 0
    fi

    touch "$LOCAL_GITCONFIG"
    git config --file "$LOCAL_GITCONFIG" user.name  "$name"
    git config --file "$LOCAL_GITCONFIG" user.email "$email"

    log_success "Git identity written to $LOCAL_GITCONFIG"
    log_info "  name:  $name"
    log_info "  email: $email"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    if ! is_interactive; then
        log_info "Non-interactive environment detected; skipping configure step."
        log_info "Run 'bash configure/configure.sh' manually to set up git identity."
        return 0
    fi

    configure_git_identity

    echo_header "Configuration complete"
    log_success "Your machine-local settings are in $LOCAL_GITCONFIG"
    log_info "This file is not committed — it stays on this machine only."
}

main
