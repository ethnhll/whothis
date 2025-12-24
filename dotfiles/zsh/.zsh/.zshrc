# whothis managed .zshrc

# ~/.zsh/.zshrc - Sourced for INTERACTIVE shells
# For aliases, functions, prompt, keybindings, completions

# --- Settings ---
KEYTIMEOUT=1

# --- Cache/History ---
HISTFILE="$ZSH_CACHE_DIR/history"

# --- Completions ---
# (FPATH already set by .zprofile)
autoload -Uz compinit
compinit -d "$ZSH_CACHE_DIR/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Tool completions
eval "$(uv generate-shell-completion zsh)"

# --- Vi Mode ---
bindkey -v
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M vicmd '^R' history-incremental-search-backward

# --- Prompt ---
eval "$(starship init zsh)"
