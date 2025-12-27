# whothis

A macOS bootstrap and configuration management tool that automates the setup of a new MacBook from scratch.
One script to install all development tools, applications, and personal dotfiles.

## Quick Start

Run this single command on a fresh Mac:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ethnhll/whothis/main/setup.sh)"
```

Or clone and run manually:

```bash
git clone https://github.com/ethnhll/whothis.git ~/whothis
cd ~/whothis
./setup.sh
```

The setup script will:
1. Install Xcode Command Line Tools (if not present)
2. Clone the repository to `~/whothis`
3. Install Homebrew
4. Install uv (Python package manager)
5. Run an ansible playbook (via `uvx`)
6. Symlink dotfiles using GNU stow

## What Gets Installed

### Development Tools
- git, vim, stow
- Docker (via Colima)
- LocalStack
- act (GitHub Actions local testing)

### Applications
- **AI Tooling**: Claude, Claude Code
- **Browsers**: Chromium, Firefox Developer Edition
- **IDEs**: JetBrains Toolbox
- **Productivity**: Obsidian, Proton Drive
- **Security**: KeePassXC, ProtonPass, ProtonVPN, Yubico Authenticator
- **Terminal**: iTerm2
- **Utilities**: Rectangle (window tiling)

### Mac App Store
- Xcode
- Strongbox (password manager)
- iWork Suite (Keynote, Numbers, Pages)

## Project Structure

```
whothis/
├── ansible/
│   ├── main.yml             # Main Ansible playbook
│   ├── default.config.yml   # Package and app configuration
│   ├── requirements.yml     # Ansible collection dependencies
│   └── inventory            # Local inventory
├── dotfiles/                # Stow-managed configuration files
│   ├── cache/               # dumping ground for various programs' temp files
│   ├── claude/              # Claude Code settings
│   ├── git/                 # Git configuration
│   ├── ssh/                 # SSH configuration
│   ├── vim/                 # Vim configuration
│   └── zsh/                 # zsh configuration 
├── Makefile                 # Build orchestration
├── setup.sh                 # Bootstrap script
└── README.md
```

## Dotfiles

Dotfiles are managed using [GNU stow](https://www.gnu.org/software/stow/).
Each subdirectory in `dotfiles/` mirrors the home directory structure and gets symlinked automatically.

To manually stow a specific config:
```bash
cd dotfiles
stow zsh   # Symlinks zsh config to ~
stow vim   # Symlinks vim config to ~
```

## Makefile Targets

```bash
make version              # Display current version (from git tag)
make homebrew             # Install Homebrew
make uv                   # Install uv package manager
make playbook             # Run the Ansible playbook
```

## Customization

Edit `ansible/default.config.yml` to customize:
- `homebrew_packages` - CLI tools to install
- `homebrew_casks` - GUI applications to install

## Requirements

- macOS (tested on macOS Sequoia 15+)
- Internet connection
- Apple ID (for Mac App Store apps)
