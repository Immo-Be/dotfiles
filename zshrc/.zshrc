
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
export PATH="$HOME/dotfiles/scripts:$HOMEBREW_PREFIX/bin:$PATH"

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


# ctrl + space for accepting suggestion
bindkey '^ ' autosuggest-accept
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

# Create a Git worktree and open it in a new tmux window.
# Usage: wt <branch> [base]
wt() {
  local branch="$1"
  local base="${2:-HEAD}"
  local common_dir repo_root repo_name worktrees_dir worktree_dir window_name

  if [[ -z "$branch" ]]; then
    echo "Usage: wt <branch> [base]"
    return 2
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "wt: not inside a Git repository"
    return 1
  fi

  if ! git check-ref-format --branch "$branch" >/dev/null 2>&1; then
    echo "wt: invalid branch name: $branch"
    return 1
  fi

  # --git-common-dir points back to the primary checkout, even when wt is
  # invoked from another worktree.
  common_dir="$(git rev-parse --path-format=absolute --git-common-dir)" || return 1
  repo_root="${common_dir:h}"
  repo_name="${repo_root:t}"
  worktrees_dir="${repo_root:h}/${repo_name}.worktrees"
  worktree_dir="${worktrees_dir}/${branch//\//-}"

  if [[ -e "$worktree_dir" ]]; then
    echo "wt: path already exists: $worktree_dir"
    return 1
  fi

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$worktree_dir" "$branch" || return 1
  else
    git worktree add -b "$branch" "$worktree_dir" "$base" || return 1
  fi

  window_name="${branch//\//-}"
  if [[ -n "$TMUX" ]]; then
    tmux new-window -c "$worktree_dir" -n "$window_name"
  else
    echo "wt: not inside tmux; entering $worktree_dir"
    cd "$worktree_dir"
  fi
}

# Remove a Git worktree while keeping its branch.
# Usage: wtrm [branch]
wtrm() {
  local branch="$1"
  local current_root primary_root target line candidate

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "wtrm: not inside a Git repository"
    return 1
  fi

  current_root="$(git rev-parse --show-toplevel)" || return 1
  primary_root="$(git worktree list --porcelain | sed -n '1s/^worktree //p')"

  if [[ -z "$branch" ]]; then
    target="$current_root"
  else
    candidate=""
    while IFS= read -r line; do
      case "$line" in
        "worktree "*) candidate="${line#worktree }" ;;
        "branch refs/heads/$branch") target="$candidate"; break ;;
      esac
    done < <(git worktree list --porcelain)

    if [[ -z "$target" ]]; then
      echo "wtrm: no worktree found for branch: $branch"
      return 1
    fi
  fi

  if [[ "$target" == "$primary_root" ]]; then
    echo "wtrm: refusing to remove the primary worktree"
    return 1
  fi

  # Git refuses by default when the worktree contains uncommitted changes.
  git -C "$primary_root" worktree remove "$target" || return 1

  if [[ "$target" == "$current_root" ]]; then
    if [[ -n "$TMUX" ]]; then
      tmux display-message "Removed worktree; branch kept"
      tmux kill-window
    else
      cd "$primary_root"
      echo "wtrm: removed worktree and entered $primary_root (branch kept)"
    fi
  else
    echo "wtrm: removed $target (branch kept)"
  fi
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
 ls -a
}
