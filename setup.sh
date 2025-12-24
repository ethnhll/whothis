#!/usr/bin/sh

# whothis - Macbook bootstrap configuration

set -e;

UNAME=$(shell uname -s);

# only macOS is supported
if [ "$UNAME" != "Darwin" ]; then
    echo "error Unsupported operating system: $UNAME"
fi

# Create marker file that triggers CLT availability in softwareupdate
touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
CLT_PACKAGE=$(softwareupdate --list | grep "Label: Command Line Tools for Xcode" | head -1 | cut -d: -f2);
echo "Installing Command Line Tools...";
softwareupdate -i "$CLT_PACKAGE" --agree-to-license;
echo "Command Line Tools successfully installed."
# Clean up marker
rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

make

exit 0
