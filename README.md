# Ubuntu Developer Machine Setup

## Quick Start

1. Install Git:
   ```bash
   sudo apt install git
   ```

2. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/linux-setup
   cd linux-setup
   ```

3. Run the setup:
   ```bash
   ./run.sh
   ```

## What's Included

- System updates and package installations
- Development tools and IDEs
- Git configuration and GitHub setup
- SDKMAN and language runtimes
- Custom dotfiles configuration

## Project Structure

```
├── apt-packages.txt          # APT package list
├── snap-packages.txt         # Snap package list
├── vscode-extensions.txt     # VS Code extension list
├── system.sh               # System package installation
├── git.sh                  # GitHub SSH key setup
├── sdk.sh                  # SDKMAN installation
├── settings.sh             # GNOME desktop settings
├── dotfiles/               # Configuration files
│   ├── .bashrc
│   ├── .vimrc
│   └── .gitconfig
└── run.sh                  # Main orchestration script
```

## Notes

- This script is designed for Ubuntu systems
- Keep `apt-packages.txt`, `snap-packages.txt`, and `vscode-extensions.txt` up to date
- The setup is idempotent and can be run multiple times safely
- Installs APT packages from `apt-packages.txt`
- Installs Snap packages from `snap-packages.txt`
- Installs VS Code extensions from `vscode-extensions.txt`
- Sets up basic development environment
- Configures GNOME desktop settings

### `git.sh`
- Configures Git with SSH key
- Sets up GitHub integration
- Configures global Git settings

### `sdk.sh`
- Installs SDKMAN
- Sets up language runtimes
- Configures development tools

### `settings.sh`
- Configures GNOME desktop settings
- Sets up workspaces and shortcuts
- Configures dock and window snapping
- Assigns applications to specific workspaces
- Configures keyboard repeat settings
- Configures screenshot shortcuts
- Sets up GNOME extensions:
  - Tactile (Tile windows)
  - Space Bar (Workspace naming and enumeration)
  - Alphabetic App Grid

### GNOME Extensions
- Some features require manual installation of GNOME extensions:
  1. Visit https://extensions.gnome.org/
  2. Click the "ON/OFF" switch to install
  3. Enable in GNOME Tweaks if needed
  4. Some extensions may require GNOME Shell restart

