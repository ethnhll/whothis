# whothis

A macOS bootstrap and configuration management tool that automates the setup of a new MacBook from scratch.
One script to install all development tools, applications, and personal dotfiles.

## Quick Start

Run this single command on a fresh Mac:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/indoorhill/whothis/main/setup.sh)"
```

Or clone and run manually:

```bash
git clone https://github.com/indoorhill/whothis.git ~/whothis
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

The full, authoritative list lives in
[`ansible/default.config.yml`](ansible/default.config.yml). Edit that file to
change what gets installed; it is not duplicated here because the list used to
drift. The three install lanes are:

- `homebrew_packages`: CLI tools (git, vim, stow, Docker via Colima, LocalStack,
  act, SDKMAN for Java, and more)
- `homebrew_casks`: GUI apps (Claude, Claude Code, Chromium, Firefox Developer
  Edition, JetBrains Toolbox, Obsidian, WezTerm, Proton suite, KeePassXC,
  Yubico Authenticator, Rectangle, and more)
- `mac_app_store_apps`: App Store apps via `mas` (Xcode, Keynote, Numbers, Pages)

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
│   ├── config/              # XDG ~/.config files (e.g. gh)
│   ├── git/                 # Git configuration
│   ├── ssh/                 # SSH configuration
│   ├── vim/                 # Vim configuration
│   ├── wezterm/             # WezTerm terminal configuration
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
- `mac_app_store_apps` - App Store apps to install via `mas`

## Manual Steps

A few things can't be automated and need doing once after the first run:

- **Mac App Store**: sign in to the App Store app before `mas` can install
  anything. The playbook prompts and warns rather than failing if you aren't
  signed in.
- **JetBrains Toolbox shell launchers**: open Toolbox, turn on *Generate shell
  scripts* in Settings, and set the scripts location to `~/.local/bin` (already
  on `PATH` via `.zprofile`). IDEs are then launchable from the terminal. The
  per-IDE launcher names are editable in each tool's settings.

## Requirements

- macOS (tested on macOS Sequoia 15+)
- Internet connection
- Apple ID (for Mac App Store apps)
