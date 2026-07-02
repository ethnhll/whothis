# whothis managed .zshenv
# XDG Base Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# ~/.zshenv - Sourced for ALL shells (first file read)
# Must be in $HOME to set ZDOTDIR before other dotfiles are found
ZDOTDIR=$HOME/.zsh
ZSH_CACHE_DIR=$HOME/.cache/zsh
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p $ZSH_CACHE_DIR

# Environment variables needed by all shells (including non-interactive)
export EDITOR='vim'         # default editor
export SSH_AUTH_SOCK=$HOME/.ssh/proton-pass-agent.sock
export HOMEBREW_NO_ANALYTICS=1  # opt out of Homebrew usage analytics
