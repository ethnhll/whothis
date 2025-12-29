# whothis managed .zshenv

# ~/.zshenv - Sourced for ALL shells (first file read)
# Must be in $HOME to set ZDOTDIR before other dotfiles are found
ZDOTDIR=$HOME/.zsh
ZSH_CACHE_DIR=$HOME/.cache/zsh
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p $ZSH_CACHE_DIR

# Environment variables needed by all shells (including non-interactive)
