# whothis managed .zprofile

# ~/.zsh/.zprofile - Sourced for LOGIN shells (before .zshrc)
# For PATH modifications and environment setup

# Homebrew environment (PATH, FPATH, MANPATH, etc.)
eval "$(/usr/local/bin/brew shellenv)"

# Additional completions (must be set before compinit in .zshrc)
FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
