#!/usr/bin/env bash
# Dotfiles installation script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../utils/utils.sh"

trap 'handle_error $? $LINENO' ERR

BACKUP_ROOT="$HOME/.local/state/linux-setup/dotfiles-backups/$(date +%Y%m%d-%H%M%S)"

backup_target() {
    local target="$1"
    local relative="${target#"$HOME"/}"
    local backup_path="$BACKUP_ROOT/$relative"

    if [[ ! -e "$target" && ! -L "$target" ]]; then
        return 0
    fi

    mkdir -p "$(dirname "$backup_path")"
    cp -a "$target" "$backup_path"
}

install_path() {
    local source_path="$1"
    local name
    name="$(basename "$source_path")"
    local target_path="$HOME/$name"

    backup_target "$target_path"
    mkdir -p "$(dirname "$target_path")"

    if [[ -d "$source_path" ]]; then
        rm -rf "$target_path"
        cp -a "$source_path" "$target_path"
    else
        cp -a "$source_path" "$target_path"
    fi

    log_success "Installed ${name}"
}

main() {
    echo_header "Dotfiles"
    mkdir -p "$BACKUP_ROOT"

    shopt -s dotglob nullglob
    local path
    for path in "$SCRIPT_DIR"/*; do
        [[ "$(basename "$path")" == "dotfiles.sh" ]] && continue
        install_path "$path"
    done
    shopt -u dotglob nullglob

    log_info "Backups stored in $BACKUP_ROOT"
}

main
