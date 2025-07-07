# .bash_aliases - Personal bash functions and aliases

# Web2App - Turn WebApp to Desktop App
# Create a desktop launcher for a web app
# Usage: web2app <AppName> <AppURL> <IconURL> [Browser] [Width] [Height]
# Example: web2app "MyApp" "https://example.com" "https://example.com/icon.svg" "firefox" 1024 768
web2app() {
    local DEFAULT_BROWSER="google-chrome"
    local DEFAULT_WIDTH=2560
    local DEFAULT_HEIGHT=1440
    
    if [ "$#" -lt 3 ]; then
        echo "Usage: web2app <AppName> <AppURL> <IconURL> [Browser] [Width] [Height]"
        echo "Example: web2app \"MyApp\" \"https://example.com\" \"https://example.com/icon.svg\" \"firefox\" 1024 768"
        return 1
    fi

    local APP_NAME="$1"
    local APP_URL="$2"
    local ICON_URL="$3"
    local BROWSER="${4:-$DEFAULT_BROWSER}"
    local WIDTH="${5:-$DEFAULT_WIDTH}"
    local HEIGHT="${6:-$DEFAULT_HEIGHT}"

    # Validate inputs
    if ! [[ "$APP_URL" =~ ^https?:// ]]; then
        echo "Error: Invalid URL format. URL must start with http:// or https://"
        return 1
    fi

    if ! [[ "$ICON_URL" =~ ^https?:// ]]; then
        echo "Error: Invalid icon URL format. URL must start with http:// or https://"
        return 1
    fi

    local ICON_DIR="$HOME/.local/share/applications/icons"
    local DESKTOP_FILE="$HOME/.local/share/applications/${APP_NAME}.desktop"
    local ICON_PATH="${ICON_DIR}/${APP_NAME}.png"

    echo "Creating web app shortcut for $APP_NAME..."
    
    # Create directories
    if [ ! -d "$ICON_DIR" ]; then
        mkdir -p "$ICON_DIR" || { echo "Error: Failed to create icon directory"; return 1; }
    fi

    if ! [[ "$ICON_URL" =~ ^https?:// ]]; then
        echo "Error: Invalid icon URL format. URL must start with http:// or https://"
        return 1
    fi

    # Download icon with progress
    echo "Downloading icon from $ICON_URL..."
    if ! curl -sL -o "$ICON_PATH" "$ICON_URL"; then
        echo "Error: Failed to download icon from $ICON_URL"
        return 1
    fi

    # Create desktop file
    echo "Creating desktop entry..."
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Name=$APP_NAME
Comment=$APP_NAME Web Application
Exec=$BROWSER --app="$APP_URL" --name="$APP_NAME" --class="$APP_NAME" --window-size=$WIDTH,$HEIGHT
Terminal=false
Type=Application
Icon=$ICON_PATH
Categories=GTK;Network;
MimeType=text/html;text/xml;application/xhtml_xml;
StartupNotify=true
EOF

    chmod +x "$DESKTOP_FILE" || { echo "Error: Failed to make desktop file executable"; return 1; }
    
    # Add to dock favorites
    local DESKTOP_ID=$(basename "$DESKTOP_FILE")
    echo "Adding $APP_NAME to dock favorites..."
    
    # Get current favorites
    local CURRENT_FAVORITES=$(gsettings get org.gnome.shell favorite-apps)
    
    # Add new app to favorites if not already present
    if ! echo "$CURRENT_FAVORITES" | grep -q "\"$DESKTOP_ID\""; then
        gsettings set org.gnome.shell favorite-apps "[\"$DESKTOP_ID\", ${CURRENT_FAVORITES:1:-1}]"
        echo "$APP_NAME has been added to dock favorites"
    else
        echo "$APP_NAME is already in dock favorites"
    fi
    
    echo "Successfully created web app shortcut for $APP_NAME"
}

# Remove a web app shortcut
# Usage: web2app-remove <AppName>
# Example: web2app-remove "MyApp"
web2app-remove() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: web2app-remove <AppName>"
        echo "Example: web2app-remove \"MyApp\""
        return 1
    fi

    local APP_NAME="$1"
    local ICON_DIR="$HOME/.local/share/applications/icons"
    local DESKTOP_FILE="$HOME/.local/share/applications/${APP_NAME}.desktop"
    local ICON_PATH="${ICON_DIR}/${APP_NAME}.png"

    # Check if files exist
    if [ ! -f "$DESKTOP_FILE" ] && [ ! -f "$ICON_PATH" ]; then
        echo "Error: No shortcut found for $APP_NAME"
        return 1
    fi

    # Remove files
    echo "Removing web app shortcut for $APP_NAME..."
    if [ -f "$DESKTOP_FILE" ]; then
        rm "$DESKTOP_FILE"
    fi
    if [ -f "$ICON_PATH" ]; then
        rm "$ICON_PATH"
    fi

    # Clean up empty directory
    if [ -d "$ICON_DIR" ] && [ -z "$(ls -A "$ICON_DIR")" ]; then
        rmdir "$ICON_DIR"
    fi

    echo "Successfully removed web app shortcut for $APP_NAME"
}

# Move a reference to a .desktop file to a folder
# Usage: app2folder <desktop_file.desktop> <folder_name>
# Example: app2folder "Spotify.desktop" "Xtra"
app2folder() {
    if [ "$#" -ne 2 ]; then
        local FOLDERS=$(gsettings get org.gnome.desktop.app-folders folder-children | tr -d "[',]")
        echo "Usage: app2folder <desktop_file.desktop> <folder_name>"
        echo "Available folders: $FOLDERS"
        echo "Note: Don't use full path for the .desktop file"
        return 1
    fi

    local DESKTOP_FILE="$1"
    local FOLDER="$2"
    local SCHEMA="org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/$FOLDER/"
    
    # Validate folder exists
    local FOLDERS=$(gsettings get org.gnome.desktop.app-folders folder-children | tr -d "[',]")
    if [[ ! " $FOLDERS " =~ " $FOLDER " ]]; then
        echo "Error: Folder '$FOLDER' does not exist. Available folders: $FOLDERS"
        return 1
    fi

    # Validate desktop file exists
    if [ ! -f "$HOME/.local/share/applications/$DESKTOP_FILE" ]; then
        echo "Error: Desktop file '$DESKTOP_FILE' not found in ~/.local/share/applications/"
        return 1
    fi

    local CURRENT_APPS=$(gsettings get "$SCHEMA" apps)
    
    if [[ "$CURRENT_APPS" != *"$DESKTOP_FILE"* ]]; then
        local TRIMMED=$(echo "$CURRENT_APPS" | sed "s/^\[//;s/\]$//")
        gsettings set "$SCHEMA" apps "[$TRIMMED, '$DESKTOP_FILE']" || {
            echo "Error: Failed to add app to folder"
            return 1
        }
        echo "Successfully moved $DESKTOP_FILE to folder $FOLDER"
    else
        echo "$DESKTOP_FILE is already in folder $FOLDER"
    fi
}
