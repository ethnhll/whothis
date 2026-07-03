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
1. Ensure a working Xcode Command Line Tools toolchain (installs it if missing,
   and repairs the case where `xcode-select` points at a broken developer dir)
2. Clone the repository to `~/whothis`
3. Install Homebrew (prompts for your password interactively)
4. Install uv (Python package manager)
5. Run an Ansible playbook (via `uvx`) that installs packages/apps, provisions
   language toolchains, applies macOS defaults, and hardens security settings
6. Symlink dotfiles using GNU stow

Pass `WHOTHIS_PERSONAL=true` (env) to also install personal-Apple-ID-only App
Store apps, and `WHOTHIS_FORCE=1` to hard-reset an existing clone to `origin/main`.

## What Gets Installed

The full, authoritative list lives in
[`ansible/default.config.yml`](ansible/default.config.yml). Edit that file to
change what gets installed; it is not duplicated here because the list used to
drift. The three install lanes are:

- `homebrew_packages`: CLI tools (git, vim, stow, ripgrep, fnm for Node, Docker
  via Colima, LocalStack, act, SDKMAN for Java, and more)
- `homebrew_casks`: GUI apps (Claude, Claude Code, Chromium, Firefox Developer
  Edition, JetBrains Toolbox, Obsidian, WezTerm, Proton suite, KeePassXC,
  Yubico Authenticator, Rectangle, and more)
- `mac_app_store_apps`: App Store apps via `mas` (Xcode, Keynote, Numbers, Pages,
  AlgoApp, Obsidian Web Clipper, Proton Pass for Safari, Vimlike). Apps tied to a
  personal Apple ID (e.g. Strongbox) live in `mac_app_store_apps_personal` and are
  installed only when `personal=true`.

Beyond installs, the playbook also provisions language toolchains (Java 8/11/17
plus latest via SDKMAN, latest Python via uv, latest LTS Node via fnm), applies a
large set of macOS `defaults` (Finder, Dock, keyboard, trackpad, etc.), and runs
security hardening (firewall, Touch ID for sudo, disable Remote Login, and more).

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
│   ├── ideavim/             # IdeaVim configuration (JetBrains IDEs)
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
make                      # all: version + homebrew + uv + playbook (default)
make help                 # List available targets
make version              # Display current version (from git tag)
make homebrew             # Install Homebrew
make uv                   # Install uv package manager
make playbook             # Run the Ansible playbook
```

Pass `PERSONAL=true` to any invocation (e.g. `make PERSONAL=true`) to include the
personal-Apple-ID-only App Store apps.

## Customization

Edit `ansible/default.config.yml` to customize:
- `homebrew_packages` - CLI tools to install
- `homebrew_casks` - GUI applications to install
- `mac_app_store_apps` / `mac_app_store_apps_personal` - App Store apps via `mas`
- `dotfile_packages` - which `dotfiles/` subdirs get stowed
- `sdkman_java_majors` - Java major versions to install (newest build of each)
- `personal` - default for the personal-Apple-ID gate (overridable per run)
- `finder_defaults`, `dock_defaults`, `global_defaults`, `other_defaults` -
  macOS `defaults` grouped by domain, applied by the `macOS defaults — …` tasks

## Manual Steps

A few things can't be automated and need doing once after the first run:

- **sudo password**: the playbook runs with `--ask-become-pass`, so it prompts
  once for your password to apply the privileged hardening tasks.
- **Mac App Store**: sign in to the App Store app before `mas` can install
  anything. The playbook prompts and warns rather than failing if you aren't
  signed in.
- **FileVault**: not auto-enabled (it generates a recovery key you must save).
  The playbook warns if full-disk encryption is off — turn it on in System
  Settings > Privacy & Security > FileVault and store the recovery key safely.
- **Remote Login**: disabling it via `systemsetup` may need Full Disk Access for
  your terminal. If the playbook can't turn it off, it warns; disable it in
  System Settings > General > Sharing > Remote Login, or grant FDA and re-run
  `ansible-playbook --tags hardening main.yml`.
- **JetBrains Toolbox shell launchers**: open Toolbox, turn on *Generate shell
  scripts* in Settings, and set the scripts location to `~/.local/bin` (already
  on `PATH` via `.zprofile`). IDEs are then launchable from the terminal. The
  per-IDE launcher names are editable in each tool's settings.

## Requirements

- macOS 15 Sequoia or later (developed against macOS 26 Tahoe)
- Administrator account (Homebrew requires it; the script refuses to run as root)
- Internet connection
- Apple ID (for Mac App Store apps)
