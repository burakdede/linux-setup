#!/usr/bin/env bash
# Dotfiles installation script

# Exit on error
set -e

# Source common functions
source "utils.sh"

# Copy and source dotfiles
echo_header "Installing and Sourcing Dotfiles"

# Check if dotfiles directory exists
if [ ! -d "dotfiles" ]; then
    log_error "dotfiles directory not found"
    exit 1
fi

# Enable dotglob to match hidden files (dotfiles)
shopt -s dotglob

# Check if dotfiles directory has any files
if [ -z "$(ls -A dotfiles/ 2>/dev/null)" ]; then
    log_info "dotfiles directory is empty"
    shopt -u dotglob  # Reset dotglob
    exit 0
fi

for file in dotfiles/*; do
    # Skip if no files match (in case of empty directory)
    [ -e "$file" ] || continue
    
    filename="$(basename "$file")"
    log_info "Copying $filename to $HOME/"
    cp -f "$file" "$HOME/$filename"
    
    # Source the file if it's a shell configuration file
    case "$filename" in
        .bashrc|.bash_profile|.zshrc|.profile|.pam_environment|.bash_aliases|.inputrc)
            log_info "Sourcing $filename"
            source "$HOME/$filename"
            ;;
        *)
            log_info "Skipping sourcing for $filename (not a shell config file)"
            ;;
    esac
done

# Reset dotglob to its original state
shopt -u dotglob

log_info "Dotfiles installation completed!"
