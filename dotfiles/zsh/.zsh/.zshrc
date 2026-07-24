# whothis managed .zshrc

# ~/.zsh/.zshrc - Sourced for INTERACTIVE shells
# For aliases, functions, prompt, keybindings, completions

# --- Completion Setup ---
if type brew &>/dev/null; then
    # .zprofile already exported HOMEBREW_PREFIX via `brew shellenv`; only fork a
    # subprocess for non-login shells where .zprofile didn't run.
    brew_prefix="${HOMEBREW_PREFIX:-$(brew --prefix)}"
    FPATH="$brew_prefix/share/zsh/site-functions:$brew_prefix/share/zsh-completions:$FPATH"
fi
autoload bashcompinit && bashcompinit
autoload -Uz compinit
# Once-a-day security check; skip it (compinit -C) on subsequent shells for speed
if [[ -n "$ZSH_CACHE_DIR/zcompdump"(#qN.mh+24) ]]; then
    compinit -d "$ZSH_CACHE_DIR/zcompdump"
else
    compinit -C -d "$ZSH_CACHE_DIR/zcompdump"
fi
_comp_options+=(globdots)

# command -v is a builtin (no subprocess, unlike `which`)
AWS_COMPLETER=$(command -v aws_completer)
if [[ -n "$AWS_COMPLETER" ]]; then
    complete -C "$AWS_COMPLETER" aws
    complete -C "$AWS_COMPLETER" awslocal
fi

# Cache uv completion instead of regenerating it every startup
if command -v uv &>/dev/null; then
    _uv_completion="$ZSH_CACHE_DIR/uv-completion.zsh"
    [[ -s "$_uv_completion" ]] || uv generate-shell-completion zsh >| "$_uv_completion"
    source "$_uv_completion"
fi

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# --- Settings ---
KEYTIMEOUT=1
setopt AUTO_PUSHD           # cd pushes to directory stack
setopt CORRECT              # suggest corrections for typos
setopt PUSHD_IGNORE_DUPS    # no duplicates in dir stack
setopt EXTENDED_GLOB        # advanced glob operators (^ ~ ** and qualifiers)
setopt GLOB_DOTS            # globs match dotfiles without a leading .
setopt NO_CASE_GLOB         # case-insensitive globbing
setopt INTERACTIVE_COMMENTS # allow # comments at the interactive prompt

# --- History ---
HISTFILE="$ZSH_CACHE_DIR/history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY        # share history across terminal sessions
setopt HIST_IGNORE_DUPS     # don't save consecutive duplicates
setopt HIST_IGNORE_SPACE    # commands starting with space aren't saved
setopt EXTENDED_HISTORY        # record timestamp + duration for each command
setopt HIST_EXPIRE_DUPS_FIRST  # when trimming history, drop duplicates first
setopt HIST_REDUCE_BLANKS      # strip superfluous whitespace before saving
setopt HIST_VERIFY             # show a history expansion (e.g. !!) before running

# --- Vi Mode ---
bindkey -v
# bindkey -v rebinds backspace to vi-backward-delete-char, which enforces
# real vi's rule that you can't delete past where insert mode started.
# Rebind it to the plain widget so backspace always works normally.
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M vicmd '^R' history-incremental-search-backward
export CLICOLOR=1

# --- Node (fnm) ---
# Fast Node Manager: sets PATH for the default Node and auto-switches when a
# directory has a .nvmrc/.node-version file.
if command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

# --- Prompt ---
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# --- Syntax highlighting (must be sourced LAST, after all widgets/keybindings) ---
_zsh_hl="${brew_prefix:-$HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[[ -r "$_zsh_hl" ]] && source "$_zsh_hl"
unset _zsh_hl
