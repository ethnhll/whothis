#!/bin/sh

# whothis - Macbook bootstrap configuration

set -e

REPO_URL="https://github.com/indoorhill/whothis.git"
INSTALL_DIR="${HOME}/whothis"

UNAME=$(uname -s)

# only macOS is supported
if [ "$UNAME" != "Darwin" ]; then
    echo "error: Unsupported operating system: $UNAME"
    exit 1
fi

# Homebrew refuses to run as root, so neither do we. Running the whole bootstrap
# under sudo is the most common setup mistake; fail early with a clear message
# instead of letting Homebrew abort halfway through.
if [ "$(id -u)" -eq 0 ]; then
    echo "error: do not run whothis as root or with sudo."
    echo "Run it as your normal admin user. You'll be prompted for your password"
    echo "when a step that needs it (like installing Homebrew) runs."
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

# Clone or update repository.
# Default is a non-destructive fast-forward. Set WHOTHIS_FORCE=1 to discard
# local changes (including untracked files) and hard-reset to upstream.
if [ -d "$INSTALL_DIR" ]; then
    git -C "$INSTALL_DIR" fetch origin
    if [ "${WHOTHIS_FORCE:-0}" = "1" ]; then
        echo "WHOTHIS_FORCE=1: discarding local changes and resetting to origin/main..."
        git -C "$INSTALL_DIR" reset --hard origin/main
        git -C "$INSTALL_DIR" clean -fd
    else
        echo "Updating (fast-forward only)..."
        if ! git -C "$INSTALL_DIR" merge --ff-only origin/main; then
            echo "error: local changes block a fast-forward update."
            echo "Commit or stash them, or re-run with WHOTHIS_FORCE=1 to discard local changes."
            exit 1
        fi
    fi
else
    echo "Cloning whothis..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Run the bootstrap. Set WHOTHIS_PERSONAL=true on the personal-Apple-ID machine
# to also install personal-only App Store apps (e.g. Strongbox).
cd "$INSTALL_DIR"
make PERSONAL="${WHOTHIS_PERSONAL:-false}"

# Start fresh shell with new configuration
exec zsh -l
