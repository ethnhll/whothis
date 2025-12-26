#!/usr/bin/sh

# whothis - Macbook bootstrap configuration

set -e

REPO_URL="https://github.com/ethnhll/whothis.git"
INSTALL_DIR="${HOME}/whothis"

UNAME=$(uname -s)

# only macOS is supported
if [ "$UNAME" != "Darwin" ]; then
    echo "error: Unsupported operating system: $UNAME"
    exit 1
fi

# Homebrew requires admin privileges
if ! dseditgroup -o checkmember -m "$(whoami)" admin >/dev/null 2>&1; then
    echo "error: User must be an Administrator to install Homebrew."
    echo "Add this user to the admin group in System Settings > Users & Groups."
    exit 1
fi

# Install CLT only if not already present
if ! xcode-select -p >/dev/null 2>&1; then
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    CLT_PACKAGE=$(softwareupdate --list | grep "Label: Command Line Tools" | head -1 | awk -F: '{print $2}' | xargs)
    echo "Installing Command Line Tools..."
    softwareupdate -i "$CLT_PACKAGE" --agree-to-license
    echo "Command Line Tools successfully installed."
    rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
else
    echo "Command Line Tools already installed."
fi

# Clone or update repository
if [ -d "$INSTALL_DIR" ]; then
    echo "Updating existing installation..."
    git -C "$INSTALL_DIR" pull
else
    echo "Cloning whothis..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Run the bootstrap
cd "$INSTALL_DIR"
make

exit 0
