# Linux Machine Setup Guide

This installation script helps you set up a new development environment with all necessary tools after a fresh install of Ubuntu.

## Manual Steps Prior to Script Run

Before running the setup script, perform the following manual steps:

1. **Install Chrome** (Optional: Skip if you prefer Firefox).
2. **Install a Password Manager** (Optional: Skip if you do not use a password manager).
3. **Install Git**:
   - Run `sudo apt install git` (until Git becomes a default package).
4. **Clone this Repository**:
   - Use HTTPS to clone this repository as SSH access to GitHub is not set up at this point.

## How to Run

To execute the setup script, run the following command:

```bash
./run.sh
```

## Run Script Breakdown

In addition to the main `run.sh` script, individual scripts can be run separately depending on your needs:

### `install.sh` - Install Updates

Run `install.sh` to:

- Get the latest updates via `apt`.
- Install essential packages required for the next steps (e.g., clipboard copy command).
- Install additional `apt` packages listed in the `apt-packages` file.
- Install necessary Snap packages.

### `git.sh` - Git & GitHub Setup

Run `git.sh` to:

- Generate a new SSH key for GitHub and copy it to your clipboard.
- Launch the SSH agent and configure it to cache the new key.
- Open GitHub settings to add the new SSH key for the current machine.
- Test the new SSH key against GitHub.
- Set the SSH agent cache Time-To-Live (TTL) to 1 hour.

### `sdk.sh` - SDKMAN Installation

Run `sdk.sh` to:

- Install SDKMAN.
- Install all necessary language runtimes and frameworks.

## Notes

- This script is designed for setting up a development environment on Ubuntu and similar Debian-based systems. Compatibility with other distributions may vary.
- Ensure that you perform the manual steps prior to running the script to avoid any issues during setup.

