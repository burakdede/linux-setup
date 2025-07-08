#!/usr/bin/env bash
# Dotfiles installation script

# Exit on error
set -e

# Directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/../utils/utils.sh"

# Copy and source dotfiles
echo_header "Installing and Sourcing Dotfiles"

# The dotfiles are in the same directory as the script
DOTFILES_DIR="$SCRIPT_DIR"

# Enable dotglob to match hidden files (dotfiles)
shopt -s dotglob

# Check if dotfiles directory has any files
if [ -z "$(ls -A "$DOTFILES_DIR"/ 2>/dev/null)" ]; then
    log_info "dotfiles directory is empty"
    shopt -u dotglob  # Reset dotglob
    exit 0
fi

for file in "$DOTFILES_DIR"/*; do
    # Skip if no files match (in case of empty directory)
    [ -e "$file" ] || continue
    
        filename="$(basename "$file")"

    # Skip the script itself
    if [ "$filename" == "dotfiles.sh" ]; then
        continue
    fi

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
