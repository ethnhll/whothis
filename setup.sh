#!/bin/sh

# whothis - macOS / Debian-family Linux bootstrap configuration
#
# With no arguments: full bootstrap (preflight, clone/update, provision, fresh
# shell). Individual steps are re-runnable as commands; see `setup.sh help`.

set -e

REPO_URL="https://github.com/indoorhill/whothis.git"
INSTALL_DIR="${HOME}/whothis"

# macOS or Debian-family Linux (Ubuntu, Debian, Mint, ...; anything with apt).
UNAME=$(uname -s)
if [ "$UNAME" = "Darwin" ]; then
    OS_KIND="darwin"
elif [ "$UNAME" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then
    OS_KIND="debian"
else
    echo "error: Unsupported operating system: $UNAME"
    echo "whothis supports macOS and Debian-family Linux (anything with apt)."
    exit 1
fi

if [ "$OS_KIND" = "darwin" ]; then
    # Homebrew paths (absolute; PATH may not be set up yet on a fresh box).
    # The playbook derives the same arch -> prefix decision from Ansible facts
    # in default.config.yml; dotfiles/zsh/.zsh/.zprofile independently probes
    # both prefixes at shell startup so login shells work without the repo.
    if [ "$(uname -m)" = "arm64" ]; then
        BREW_PREFIX="/opt/homebrew"
    else
        BREW_PREFIX="/usr/local"
    fi
    BREW="$BREW_PREFIX/bin/brew"
    UVX="$BREW_PREFIX/bin/uvx"
    TOOL_BIN="$BREW_PREFIX/bin"
else
    # mise plays Homebrew's role on Linux: fixed user path, no arch branching
    # needed (the playbook derives the same paths in default.config.yml).
    MISE="$HOME/.local/bin/mise"
    MISE_SHIMS="$HOME/.local/share/mise/shims"
    UVX="$MISE_SHIMS/uvx"
    TOOL_BIN="$MISE_SHIMS"
fi

# Pin the Ansible runtime. With no pins, uvx resolves ansible-core against
# whatever Python it happens to find; on a fresh box that was an old 3.9, which
# pulls ansible-core 2.15 (too old for community.general 13 -> warnings/failures)
# and lacks prebuilt wheels for some deps (forcing a Rust source build). Forcing
# a modern managed Python + matching ansible-core avoids both.
ANSIBLE_PY="3.12"
ANSIBLE_CORE="ansible-core>=2.17"

# Resolves to the checkout containing this script for the provisioning commands.
# (Meaningless when the script is curl-piped, but the no-argument bootstrap path
# re-runs the fresh checkout's copy before any of these are used.)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ANSIBLE_DIR="$SCRIPT_DIR/ansible"

# Homebrew and mise both refuse to run as root, so neither do we. Running the
# whole bootstrap under sudo is the most common setup mistake; fail early with
# a clear message instead of letting Homebrew/mise abort halfway through.
if [ "$(id -u)" -eq 0 ]; then
    echo "error: do not run whothis as root or with sudo."
    echo "Run it as your normal admin user. You'll be prompted for your password"
    echo "when a step that needs it (like installing Homebrew, mise, or apt"
    echo "packages) runs."
    exit 1
fi

ensure_clt() {
    # Command Line Tools. `xcode-select -p` succeeding is NOT enough: the active
    # developer directory can point at a broken/partial Xcode.app (e.g. a half-
    # finished App Store download), which makes make/clang fail with "unable to
    # locate xcodebuild". So verify the toolchain actually resolves, and fall back
    # to the Command Line Tools if it doesn't.
    CLT_DIR="/Library/Developer/CommandLineTools"
    if ! xcode-select -p >/dev/null 2>&1; then
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        CLT_PACKAGE=$(softwareupdate --list | grep "Label: Command Line Tools" | head -1 | awk -F: '{print $2}' | xargs)
        echo "Installing Command Line Tools..."
        softwareupdate -i "$CLT_PACKAGE" --agree-to-license
        echo "Command Line Tools successfully installed."
        rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    elif ! /usr/bin/make --version >/dev/null 2>&1; then
        echo "warning: active developer dir ($(xcode-select -p)) has no working toolchain."
        if [ -x "$CLT_DIR/usr/bin/make" ]; then
            echo "Pointing xcode-select at the Command Line Tools (needs sudo)..."
            sudo xcode-select --switch "$CLT_DIR"
        else
            echo "error: no working toolchain and no Command Line Tools present."
            echo "Install them with: xcode-select --install"
            exit 1
        fi
    else
        echo "Command Line Tools already installed."
    fi
}

ensure_apt_baseline() {
    # Guarantees the tools needed to clone the repo and run mise's installer
    # exist on a fresh box, mirroring ensure_clt's role on macOS.
    if command -v git >/dev/null 2>&1 && command -v curl >/dev/null 2>&1 && command -v cc >/dev/null 2>&1; then
        echo "Baseline packages (git, curl, build-essential) already installed."
    else
        echo "Installing baseline apt packages (git, curl, build-essential)..."
        sudo apt-get update
        sudo apt-get install -y git curl ca-certificates build-essential
    fi
}

clone_or_update() {
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
}

install_homebrew() {
    if [ -x "$BREW" ]; then
        echo "$("$BREW" --version | head -1) is already installed."
    else
        # Homebrew requires admin privileges
        if ! dseditgroup -o checkmember -m "$(whoami)" admin >/dev/null 2>&1; then
            echo "error: User must be an Administrator to install Homebrew."
            echo "Add this user to the admin group in System Settings > Users & Groups."
            exit 1
        fi
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

install_mise() {
    if [ -x "$MISE" ]; then
        echo "$("$MISE" --version) is already installed."
    else
        echo "Installing mise..."
        curl -fsSL https://mise.run | sh
    fi
}

install_uv() {
    if [ -x "$UVX" ]; then
        echo "uv is already installed."
    elif [ "$OS_KIND" = "darwin" ]; then
        echo "Installing uv..."
        "$BREW" install uv
    else
        echo "Installing uv..."
        "$MISE" use --global uv
    fi
}

# Run a tool from the pinned Ansible runtime (ansible-playbook, ansible-galaxy).
# --no-build: everything in this stack ships wheels, so refuse source builds.
# Without it, a bad resolution (e.g. the old-Python path above) tries to compile
# cryptography from source and fails asking for OpenSSL + a Rust toolchain.
run_ansible() {
    "$UVX" --no-build --python "$ANSIBLE_PY" --from "$ANSIBLE_CORE" "$@"
}

run_playbook() {
    cd "$ANSIBLE_DIR"
    echo "Installing Ansible collections (from requirements.yml)..."
    run_ansible ansible-galaxy collection install -r requirements.yml

    # become over ansible_connection=local is a long-standing Ansible bug:
    # privilege escalation assumes a pty that the local connection plugin
    # doesn't allocate, so it fails to prompt reliably ("Duplicate become
    # password prompt"), and a sudo timestamp primed in THIS shell (tty-scoped)
    # isn't visible to Ansible's module subprocesses (no controlling tty), so
    # `sudo -n` there still asks for a password. Grant a temporary NOPASSWD
    # sudoers rule for the run instead; become_flags=-n in ansible.cfg then
    # never needs to prompt at all. Removed on exit, success or failure.
    echo "Granting temporary passwordless sudo for the provisioning run..."
    sudo -v
    sudoers_snippet="$(mktemp)"
    echo "$(whoami) ALL=(ALL) NOPASSWD: ALL" >"$sudoers_snippet"
    chmod 440 "$sudoers_snippet"
    sudo visudo -c -f "$sudoers_snippet"
    sudo install -m 440 "$sudoers_snippet" /etc/sudoers.d/whothis-bootstrap
    rm -f "$sudoers_snippet"
    trap 'sudo rm -f /etc/sudoers.d/whothis-bootstrap' EXIT

    echo "Running playbook..."
    run_ansible ansible-playbook \
        --timeout 60 \
        --extra-vars ansible_python_interpreter=python3 \
        "$@" \
        main.yml

    sudo rm -f /etc/sudoers.d/whothis-bootstrap
    trap - EXIT
}

provision() {
    if [ "$OS_KIND" = "darwin" ]; then
        OS_DESC="macos $(sw_vers -productVersion)"
    else
        OS_DESC="$(. /etc/os-release && echo "$PRETTY_NAME")"
    fi
    echo "=== whothis $(git -C "$SCRIPT_DIR" describe --tags --always 2>/dev/null || echo dev) on $OS_DESC ==="
    if [ "$OS_KIND" = "darwin" ]; then
        install_homebrew
    else
        install_mise
    fi
    install_uv
    run_playbook
}

usage() {
    cat <<'EOF'
Usage: setup.sh [command]

  (no command)   full bootstrap: preflight, clone/update the repo, then
                 provision from the fresh checkout and start a new shell
  provision      homebrew/mise + uv + collections + playbook (no clone/update)
  homebrew       install Homebrew if missing (macOS)
  uv             install uv if missing
  playbook       run the Ansible playbook; extra args are passed through,
                 e.g. `./setup.sh playbook --tags hardening`
  check          shellcheck + playbook syntax check + ansible-lint

Environment:
  WHOTHIS_FORCE=1        hard-reset an existing clone to origin/main
EOF
}

check() {
    SC=$(command -v shellcheck || true)
    if [ -z "$SC" ] && [ -x "$TOOL_BIN/shellcheck" ]; then
        SC="$TOOL_BIN/shellcheck"
    fi
    if [ -n "$SC" ]; then
        echo "Checking setup.sh (shellcheck)..."
        "$SC" "$SCRIPT_DIR/setup.sh"
    else
        echo "shellcheck not installed; skipping shell lint."
    fi
    cd "$ANSIBLE_DIR"
    echo "Checking playbook syntax..."
    run_ansible ansible-playbook --syntax-check main.yml
    echo "Linting playbook (ansible-lint)..."
    # ansible-lint isn't part of ansible-core, so it can't go through
    # run_ansible's --from pin; --no-build for the same source-build safety.
    "$UVX" --no-build --python "$ANSIBLE_PY" ansible-lint main.yml
    echo "All checks passed."
}

CMD="${1:-bootstrap}"
if [ $# -gt 0 ]; then shift; fi

case "$CMD" in
    bootstrap)
        if [ "$OS_KIND" = "darwin" ]; then
            ensure_clt
        else
            ensure_apt_baseline
        fi
        clone_or_update
        # Provision with the fresh checkout's copy of this script, so a
        # curl-piped (possibly stale) copy never drives the provisioning.
        sh "$INSTALL_DIR/setup.sh" provision
        # Start fresh shell with new configuration
        exec zsh -l
        ;;
    provision) provision ;;
    homebrew) install_homebrew ;;
    uv) install_uv ;;
    playbook) run_playbook "$@" ;;
    check) check ;;
    help|-h|--help) usage ;;
    *)
        echo "error: unknown command: $CMD"
        usage
        exit 1
        ;;
esac
