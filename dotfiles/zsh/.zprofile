# whothis managed .zprofile

# Homebrew environment (PATH, FPATH, etc.)
eval "$(/usr/local/bin/brew shellenv)"

# Additional completions (zsh-completions package)
FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

# Environment for child processes
export SSH_AUTH_SOCK=~/.strongbox/agent.sock

# Added by Jetbrains Toolbox App
export PATH="$PATH:/usr/local/bin"
