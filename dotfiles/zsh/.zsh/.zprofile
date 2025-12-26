# whothis managed .zprofile

# ~/.zsh/.zprofile - Sourced for LOGIN shells (before .zshrc)
# For PATH modifications and environment setup

# Homebrew environment (PATH, FPATH, MANPATH, etc.)
if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Additional completions (must be set before compinit in .zshrc)
FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
