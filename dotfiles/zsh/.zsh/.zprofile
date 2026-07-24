# whothis managed .zprofile

# ~/.zsh/.zprofile - Sourced for LOGIN shells (before .zshrc)
# For PATH modifications and one-time login environment setup

# Homebrew environment first (PATH, FPATH, MANPATH) so `brew` is available
# to later steps. Loops both arches and silently skips if brew isn't installed.
# (setup.sh owns the arch -> prefix decision for provisioning; this probe is
# deliberately independent so login shells work without the repo.)
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$_brew" ]]; then
        eval "$("$_brew" shellenv)"
        break
    fi
done
unset _brew

# Personal bin dirs, prepended after brew so they take priority
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000

# SDKMAN (Java version management), installed via Homebrew tap sdkman/tap/sdkman-cli.
# Guarded so it no-ops cleanly until brew + the formula are installed.
if [[ -n "$HOMEBREW_PREFIX" ]]; then
    # brew guarantees the opt/<formula> symlink, so derive the path directly
    # instead of the slow `brew --prefix sdkman-cli` formula-load fork each login.
    export SDKMAN_DIR="$HOMEBREW_PREFIX/opt/sdkman-cli/libexec"
    [[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"
fi
