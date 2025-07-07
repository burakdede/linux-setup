#!/usr/bin/env bash
# Ubuntu Developer Machine Setup Orchestration Script

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Source common functions
source "utils.sh"

# Function to run a script
run_script() {
    local script_name="$1"
    local description="$2"
    
    if [ ! -f "$script_name" ]; then
        log_error "❌ Script $script_name not found!"
        return 1
    fi
    
    echo_header "🚀 Starting: $description"
    echo # Add spacing
    
    # Run script with live output
    if bash "$script_name"; then
        echo # Add spacing
        echo_header "✅ Completed: $description"
    else
        echo # Add spacing
        log_error "❌ Failed: $description"
        return 1
    fi
    
    # Pause for user to see result
    echo "Press Enter to continue..."
    read -r
}

# Main execution
main() {
    echo_header "🚀 Starting full installation..."
    
    local scripts=("system.sh" "dotfiles.sh" "sdk.sh" "git.sh" "settings.sh")
    local descriptions=("System packages" "Dotfiles" "SDKMAN" "GitHub setup" "OS settings")
    
    for i in "${!scripts[@]}"; do
        if [ -f "${scripts[$i]}" ]; then
            echo
            echo_header "Step $((i+1))/5: ${descriptions[$i]}"
            run_script "${scripts[$i]}" "${descriptions[$i]}"
        fi
    done
    
    echo_header "🎉 Full installation completed!"
}

# Run main function
main