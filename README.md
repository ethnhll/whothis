# whothis

>_New laptop, whothis?_

A system bootstrap configuration tool for setting up a new macOS (or Linux) laptop. Uses Make for bootstrapping, uv + Ansible for system configuration, and Stow for dotfile management.

## Architecture

```
make
└── installs Homebrew (macOS only) 
    └── installs uv
        └── installs ansible (via pyproject.toml)
            └── runs playbook
                ├── installs packages (brew/apt)
                ├── installs casks (brew)
                ├── installs Apple app store apps (XCode, Strongbox, etc.)
                └── stows dotfiles
```

## Prerequisites

- macOS or Ubuntu Linux
- `make` (pre-installed on macOS, `sudo apt install make` on Ubuntu)
- `curl` (for installing uv/homebrew)

## Quick Start

```shell
git clone <your-repo-url> whothis
cd whothis
make
```

This will:

1. Install Homebrew (macOS) or verify apt (Linux)
2. Install uv
3. Create a Python virtual environment and install Ansible
4. Run the Ansible playbook to install packages and stow dotfiles

## Project Structure

```
whothis/
├── Makefile              # Bootstrap orchestration
├── pyproject.toml        # Python dependencies (ansible)
├── ansible/
│   └── playbook.yml      # System configuration
└── dotfiles/
    ├── vim/
    │   ├── .vimrc
    │   └── .vim/undodir/.gitignore
    ├── git/
    │   └── .gitconfig
    ├── ssh/
    │   └── .ssh/config
    └── zsh/
        └── .zshrc
```

## Make Targets

| Target             | Description                   |
|--------------------|-------------------------------|
| `make`             | Run full setup (all targets)  |
| `make version`     | Show OS and version info      |
| `make pkg-manager` | Install Homebrew (macOS only) |
| `make uv`          | Install uv                    |
| `make ansible`     | Install Ansible via uv        |
| `make playbook`    | Run the Ansible playbook      |

## Customization

### Adding Packages

Edit `ansible/playbook.yml`:

```yaml
vars:
  brew_packages:
    - stow
    - vim
    - your-package-here

  brew_casks:
    - iterm2 
    - your-cask-here
  store_apps:
    - 497799835  # XCode
    - your-app-id-number-here 
```

### Adding Dotfiles

1. Create directory: `dotfiles/<name>/`
2. Mirror the home directory structure inside it
3. Add `<name>` to `dotfile_packages` in `ansible/playbook.yml`

Example for adding tmux config:

```
dotfiles/tmux/.tmux.conf
```

```yaml
dotfile_packages:
  - vim
  - git
  - ssh
  - zsh
  - tmux  # add this
```

### Versioning

Version is derived from git tags:

```bash
git tag v0.1.0
git push --tags
```

## SSH Keys with Strongbox

This setup uses Strongbox as an SSH agent. Keys are stored in your Strongbox database, not on disk.

Setup:

1. Open Strongbox and enable SSH Agent in settings
2. Add/generate SSH keys in Strongbox
3. Add public key to GitHub
4. Open new terminal and test: `ssh -T git@github.com`

## Notes

- Be **VERY** careful not to commit any sensitive credentials
- Dotfiles are symlinked via Stow—edit them in place, and changes apply immediately
- Run `make` again anytime to ensure the system is in sync (idempotent)
- The `.venv/` directory is local and should be gitignored
