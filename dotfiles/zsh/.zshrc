# whothis managed .zshrc

# Zsh settings
KEYTIMEOUT=1
ZSH_CACHE_DIR=~/.zsh/cache
mkdir -p "$ZSH_CACHE_DIR"
HISTFILE="$ZSH_CACHE_DIR/history"

# Completions (FPATH already set by .zprofile)
autoload -Uz compinit
compinit -d "$ZSH_CACHE_DIR/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Vi mode
bindkey -v
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M vicmd '^R' history-incremental-search-backward

# Prompt
eval "$(starship init zsh)"

# Tool completions
eval "$(uv generate-shell-completion zsh)"
