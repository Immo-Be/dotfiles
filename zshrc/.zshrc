
#######################################################################
# Requirements for this ~/.zshrc (manual installs via Homebrew)
#
# Framework (install first):
#   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#
# Core utilities:
#   brew install fzf ripgrep bat eza zoxide
#
# Shell enhancements:
#   brew install zsh-autosuggestions zsh-syntax-highlighting
#
# Prompt theme (choose one):
#   brew install romkatv/powerlevel10k/powerlevel10k
#   # or brew install starship (if you prefer Starship instead of p10k)
#
# Version managers:
#   brew install nvm pyenv
#
# Notes:
#   - Oh My Zsh: provides the plugin framework and themes
#   - fzf: fuzzy finder (Ctrl-R, `zi` with zoxide, etc.)
#   - ripgrep: fast recursive grep (`rg`)
#   - bat: cat with syntax highlighting (`bat`)
#   - eza: modern ls replacement (`ls`/`ll`)
#   - zoxide: smarter cd (`z`, `zi`, `j`)
#   - zsh-autosuggestions + zsh-syntax-highlighting: command hints & colors
#   - nvm: Node.js version manager (lazy-loaded in this config)
#   - pyenv: Python version manager
#   - powerlevel10k: prompt theme (already configured below)
#
# After installing, reload this file with: source ~/.zshrc
#######################################################################


##### p10k instant prompt — keep at very top
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Optional: silence warning without disabling
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

##### Homebrew prefix (Apple Silicon)
HOMEBREW_PREFIX="/opt/homebrew"
export PATH="$HOMEBREW_PREFIX/bin:$PATH"

##### Oh My Zsh + theme
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)
source "$ZSH/oh-my-zsh.sh"   # <-- this already runs compinit


# Use vi keybindings in ZLE (command line editor)
bindkey -v

# Make ESC show you're in normal mode by changing the cursor shape (optional)
# (works in iTerm2, kitty, Alacritty, most modern terminals)
function zle-keymap-select {
  case $KEYMAP in
    vicmd)      print -n '\e[4 q' ;;  # underscore cursor in NORMAL mode
    viins|main) print -n '\e[0 q' ;;  # default cursor in INSERT mode
  esac
}
zle -N zle-keymap-select
zle-line-init() { zle -K viins; zle-keymap-select }
zle -N zle-line-init
print -n '\e[5 q'  # default to beam on shell startup

### --- Vim-like convenience bindings ---

# jk in INSERT mode behaves like <Esc>
bindkey -M viins 'jk' vi-cmd-mode

# History navigation like in Vim's <C-p>/<C-n>
bindkey '^P' up-history
bindkey '^N' down-history

# Line start/end like Vim 0/$
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# Delete previous word (like Ctrl-w in Vim insert mode)
bindkey '^W' backward-kill-word

# Search history with / in NORMAL mode
bindkey -M vicmd '/' history-incremental-search-backward



##### Google Cloud SDK (quiet)
[[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/google-cloud-sdk/path.zsh.inc" >/dev/null 2>&1

##### QoL shell options
setopt autocd autopushd pushdignoredups pushdsilent
setopt no_beep noclobber interactivecomments
setopt histignoredups histignorespace sharehistory
setopt extendedglob correct

##### Completion styling (keep, but don't rerun compinit)
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|=*' 'l:|=*'
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'

##### fzf (key-bindings + completion)
[[ -r "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]] && source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
[[ -r "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"    ]] && source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"

##### zoxide — smarter cd
eval "$(zoxide init zsh)"
alias j='zi'
alias cd='z'

##### Aliases
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ll="ls -lah"
# alias ls="eza -F --group --icons"
# alias ll="eza -lah --group --icons"

##### zsh-autosuggestions — accept suggestion with Ctrl+L
bindkey '^L' autosuggest-accept

##### Powerlevel10k prompt
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

##### nvm — true lazy load, no precmd hook
export NVM_DIR="$HOME/.nvm"
export NVM_DEFAULT="lts/*"   # or set a concrete version like "v22.11.0"
__nvm_loaded=0
_load_nvm() {
  [[ $__nvm_loaded == 1 ]] && return
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
  __nvm_loaded=1
  # Switch once to default (fast if already active; no per-prompt penalty)
  if [[ -n "$NVM_DEFAULT" ]] && command -v nvm >/dev/null 2>&1; then
    # Only switch if not already on a matching version
    if ! nvm current | grep -qE "$(nvm version "$NVM_DEFAULT" 2>/dev/null | sed 's/[.^$*+?()[\]{}|]/\\&/g')"; then
      nvm use "$NVM_DEFAULT" >/dev/null 2>&1
    fi
  fi
}
for cmd in node npm npx pnpm corepack; do
  eval "
  $cmd() {
    _load_nvm
    command $cmd \"\$@\"
  }"
done

##### pyenv
#
##### pyenv — fast init (no rehash during source)
export PYENV_ROOT="$HOME/.pyenv"

# Make pyenv and its shims available.
if [[ -d "$PYENV_ROOT" ]]; then
  export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
  # Avoid any implicit rehashing during startup
  export PYENV_DISABLE_REHASH=1
  # OPTIONAL: if you really want shell functions but not rehash/completions:
  # command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init - 2>/dev/null)" || true
fi
