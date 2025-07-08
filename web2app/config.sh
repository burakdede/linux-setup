#!/usr/bin/env bash
# Web Apps Configuration
# This file contains the list of web apps to be installed and configured

# Define web apps to install
# Format: ["AppName"]="URL ICON_URL"
declare -gA WEB_APPS=(
    ["WhatsApp"]="https://web.whatsapp.com https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/whatsapp.png"
    ["GMail"]="https://mail.google.com https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/gmail.png"
    ["GCal"]="https://calendar.google.com https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/google-calendar.png"
    ["ChatGPT"]="https://chatgpt.com https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/chatgpt.png"
    ["Claude"]="https://claude.ai https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/claude-ai-light.png"
    ["Gemini"]="https://gemini.google.com https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/google-gemini.png"
    ["Grok"]="https://grok.com https://images.seeklogo.com/logo-png/61/1/grok-logo-png_seeklogo-613403.png"
)

# Function to get web app names as a regex pattern for matching
# Usage: if [[ "$app" =~ ^($(get_webapp_pattern))\.desktop$ ]]
get_webapp_pattern() {
    local pattern=""
    for app in "${!WEB_APPS[@]}"; do
        pattern+="$app|"
    done
    # Remove trailing | and return
    echo "${pattern%|}"
}
