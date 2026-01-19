
#######################################################################
# Cross-Platform Zsh Setup
#
# This config works on macOS and Debian/Ubuntu-based Linux.
#
# --- STEP 1: Install Oh My Zsh ---
# sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#
# --- STEP 2: Install Dependencies ---
#
# For macOS (using Homebrew):
#   brew install fzf ripgrep bat eza zoxide nvm pyenv
#   brew install romkatv/powerlevel10k/powerlevel10k
#
# For Debian / Ubuntu (using apt):
#   sudo apt update && sudo apt install -y fzf ripgrep bat zoxide git curl
#
#   # Manual installs may be needed for the following on Linux:
#   # eza: See https://github.com/eza-community/eza/blob/main/INSTALL.md
#   # nvm: See https://github.com/nvm-sh/nvm#installing-and-updating
#   # pyenv: See https://github.com/pyenv/pyenv-installer
#   # p10k: See https://github.com/romkatv/powerlevel10k#oh-my-zsh
#
# --- STEP 3: Reload Shell ---
#   source ~/.zshrc
#
# --- TOOL USAGE NOTES ---
#   - Oh My Zsh: Manages plugins/themes. Edit ~/.zshrc, then `omz reload`.
#   - fzf: Fuzzy finder. Press `Ctrl+R` for history, `Ctrl+T` for files.
#   - ripgrep: Fast grep alternative. Usage: `rg 'pattern' [path]`.
#   - bat: A `cat` clone. On Debian, may be `batcat`. If so: `alias bat=batcat`.
#   - eza: Modern `ls`. Aliased to `ls` and `ll` if you uncomment the aliases below.
#   - zoxide: Smarter `cd`. Aliased to `cd`. Usage: `cd project` to jump.
#   - zsh-autosuggestions: Suggests commands. Press `Ctrl+L` to accept.
#   - zsh-syntax-highlighting: Highlights commands. No action needed.
#   - nvm: Node.js manager. Usage: `nvm install 20`, `nvm use 20`.
#   - pyenv: Python manager. Usage: `pyenv install 3.12`, `pyenv global 3.12`.
#   - powerlevel10k: The prompt theme. Run `p10k configure` to customize.
#
#######################################################################


##### p10k instant prompt — keep at very top (disabled for Oh My Posh)
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# Optional: silence warning without disabling
# typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

##### Homebrew prefix (Apple Silicon)
HOMEBREW_PREFIX="/opt/homebrew"
export PATH="$HOMEBREW_PREFIX/bin:$PATH"

##### Oh My Zsh + theme
export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="powerlevel10k/powerlevel10k" # Disabled for Oh My Posh
ZSH_THEME="" # Set to empty when using Oh My Posh

plugins=(git web-search zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"   # <-- this already runs compinit

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

#Vi Mode
# see https://www.youtube.com/watch?v=OKuUoZaPiwE

bindkey -v # Enable vi keybindings in zsh
export KEYTIMEOUT=1 # Reduce delay for key sequences

# Press 'v' in normal mode to open the current command line in $EDITOR
export EDITOR='nvim'
autoload edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

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



yad() {
  yazi "${1:-$PWD}" "$HOME/Downloads"
}
# alias ls="eza -F --group --icons"
# alias ll="eza -lah --group --icons"

##### zsh-autosuggestions — accept suggestion with Ctrl+L
bindkey '^L' autosuggest-accept

##### Oh My Posh prompt (replaces Powerlevel10k)
# Pick a theme: https://ohmyposh.dev/docs/themes
# Example themes: agnoster, atomic, blue-owl, catppuccin, paradox, powerlevel10k_rainbow
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh-custom.json)"

##### Powerlevel10k prompt (disabled for Oh My Posh)
# [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# --- NVM (simple, no wrappers)
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" --no-use

# Switch once to your default if it exists (fast, no network)
if command -v nvm >/dev/null 2>&1; then
  nvm use --silent default >/dev/null 2>&1 || true
fi

mvproj() {
  local src dest project_root

  # 1️⃣ Pick source file (from ~/Downloads)
  src="${1:-$(ls -t ~/Downloads | fzf --prompt='Select file> ')}"
  [[ -z "$src" ]] && echo "❌ No file selected" && return 1

  # 2️⃣ Pick project root (from ~/projects/)
  project_root="${2:-$(ls -d ~/Documents/projects/*/ | fzf --prompt='Select project root> ')}"
  [[ -z "$project_root" ]] && echo "❌ No project selected" && return 1

  # 3️⃣ Pick destination directory (inside project, excluding junk dirs)
  dest="$(find "$project_root" -type d \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" 2>/dev/null | \
    fzf --prompt='Select destination dir> ')"
  [[ -z "$dest" ]] && echo "❌ No destination directory selected" && return 1

  # 4️⃣ Move the file
  mv -i "$HOME/Downloads/$src" "$dest/" && \
    echo "✅ Moved $src → $dest/"
}

##### pyenv
#
##### pyenv — fast init (no rehash during source)
# export PYENV_ROOT="$HOME/.pyenv"

# Make pyenv and its shims available.
# if [[ -d "$PYENV_ROOT" ]]; then
#   export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
#   # Avoid any implicit rehashing during startup
#   export PYENV_DISABLE_REHASH=1
#   # OPTIONAL: if you really want shell functions but not rehash/completions:
#   # command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init - 2>/dev/null)" || true
# fi
export GOOGLE_CLOUD_PROJECT="ubilabs-dev"

# Added by Antigravity
export PATH="/Users/immo/.antigravity/antigravity/bin:$PATH"


#chpwd hook
# execute ls after cd 
chpwd() {
 ls
}
