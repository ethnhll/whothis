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

Pass `WHOTHIS_FORCE=1` (env) to hard-reset an existing clone to `origin/main`.

## What Gets Installed

The full, authoritative list lives in
[`ansible/default.config.yml`](ansible/default.config.yml). Edit that file to
change what gets installed; it is not duplicated here because the list used to
drift. The three install lanes are:

- `homebrew_packages`: CLI tools (git, vim, stow, ripgrep, fnm for Node, Docker
  via Colima, LocalStack, act, SDKMAN for Java, `xcodes` for Xcode, and more)
- `homebrew_casks`: GUI apps (Claude, Claude Code, Chromium, Firefox Developer
  Edition, JetBrains Toolbox, Obsidian, WezTerm, Proton suite, KeePassXC,
  Yubico Authenticator, Rectangle, AlgoApp, and more)
- `app_store_manual_apps`: apps with no distribution outside the App Store
  (Keynote, Numbers, Pages, and several Safari extensions, which Apple requires
  to ship via the App Store). We stopped using `mas` to install these because
  it now needs sudo and can't check sign-in status, so the playbook just
  prints their App Store links for a one-time manual install/update.

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
├── setup.sh                 # Bootstrap + orchestration script
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

## setup.sh Commands

```bash
./setup.sh                # full bootstrap: preflight + clone/update + provision
./setup.sh help           # List available commands
./setup.sh provision      # homebrew + uv + playbook (no clone/update)
./setup.sh homebrew       # Install Homebrew
./setup.sh uv             # Install uv package manager
./setup.sh playbook       # Run the Ansible playbook (extra args pass through,
                          # e.g. ./setup.sh playbook --tags app_store)
./setup.sh check          # shellcheck + playbook syntax check + ansible-lint
```

## Customization

Edit `ansible/default.config.yml` to customize:
- `homebrew_packages` - CLI tools to install
- `homebrew_casks` - GUI applications to install
- `app_store_manual_apps` - apps to print App Store links for (no `mas` install)
- `dotfile_packages` - which `dotfiles/` subdirs get stowed
- `sdkman_java_majors` - Java major versions to install (newest build of each)
- `login_items` - apps registered to launch at login
- `finder_defaults`, `dock_defaults`, `global_defaults`, `other_defaults` -
  macOS `defaults` grouped by domain, applied by the `macOS defaults - ...` tasks

## Manual Steps

A few things can't be automated and need doing once after the first run:

- **sudo password**: the playbook runs with `--ask-become-pass`, so it prompts
  once for your password to apply the privileged hardening tasks.
- **Mac App Store apps**: the playbook prints App Store links for the handful
  of apps that have no other distribution (`app_store_manual_apps`, mostly
  Safari extensions). Install/update those manually; sign in to the App Store
  app first if you haven't.
- **Xcode**: installed via `xcodes` (not the App Store). Run
  `xcodes install --latest` once and sign in with your Apple ID when prompted.
- **FileVault**: not auto-enabled (it generates a recovery key you must save).
  The playbook warns if full-disk encryption is off; turn it on in System
  Settings > Privacy & Security > FileVault and store the recovery key safely.
- **Remote Login**: disabling it via `systemsetup` may need Full Disk Access for
  your terminal. If the playbook can't turn it off, it warns; disable it in
  System Settings > General > Sharing > Remote Login, or grant FDA and re-run
  `./setup.sh playbook --tags hardening`.
- **Default password manager**: in System Settings > General > AutoFill &
  Passwords, enable **Proton Pass** as the AutoFill provider and switch off the
  built-in **Passwords** app. The playbook disables Safari's own password
  autofill (needs Full Disk Access), but the system provider choice has no
  automation surface.
- **Automation prompts**: the login-items task asks once to let your terminal
  control System Events; allow it, or re-run `./setup.sh playbook --tags login`.
- **JetBrains Toolbox shell launchers**: open Toolbox, turn on *Generate shell
  scripts* in Settings, and set the scripts location to `~/.local/bin` (already
  on `PATH` via `.zprofile`). IDEs are then launchable from the terminal. The
  per-IDE launcher names are editable in each tool's settings.

## Requirements

- macOS 15 Sequoia or later (developed against macOS 26 Tahoe)
- Administrator account (Homebrew requires it; the script refuses to run as root)
- Internet connection
- Apple ID (for Mac App Store apps)
