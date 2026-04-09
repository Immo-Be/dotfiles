# Dotfiles (Managed with GNU Stow)

This repository contains configuration files for tools like `nvim`, `tmux`, `zsh`, etc., managed using [GNU Stow](https://www.gnu.org/software/stow/).

---

## 📦 Structure

Each directory corresponds to a tool or app and contains its config files in the correct relative path.
Example:

```
dotfiles/
├── nvim/
│   └── .config/
│       └── nvim/
├── tmux/
│   └── .tmux.conf
├── zsh/
│   └── .zshrc
```

---

## 🛠️ Installation

### 1. Install GNU Stow

#### macOS (with Homebrew)

```sh
brew install stow
```

#### Debian/Ubuntu

```sh
sudo apt install stow
```

---

### 2. Clone the repo

```sh
git clone https://github.com/your-username/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

---

### 3. Stow configs

Use `--target=$HOME` to ensure correct symlink paths.

```sh
stow --target=$HOME nvim
stow --target=$HOME tmux
stow --target=$HOME zsh
```

---

## 🧼 Unstow (Remove Symlinks)

```sh
stow -D --target=$HOME nvim
```

---

## ➕ Add a New Config

1. Create a directory in the repo that mirrors the target path under `$HOME`.
2. Put the config file at the correct relative location inside that directory.
3. Run `stow --target=$HOME <dir>` from the repo root.

Example for Ghostty:

```text
ghostty/
└── .config/
    └── ghostty/
        └── config
```

```sh
stow --target=$HOME ghostty
```

---

## ⚠️ Gotchas

- If you see errors like:
  ```
  WARNING! stowing xyz would cause conflicts...
  ```
  it means a file (like `.DS_Store`) already exists in the target location. Either:

  - Remove the conflicting file manually
  - Use `--adopt` to move it into your stow repo:
    ```sh
    stow --target=$HOME --adopt nvim
    ```

- Ignore `.DS_Store` and similar clutter in `.gitignore`:
  ```gitignore
  .DS_Store
  ```

---

## 🧠 Tips

- Use one folder per app (`nvim`, `tmux`, `zsh`, `git`, etc.)
- Keep file paths **relative to `$HOME`**
- Use `--target=$HOME` consistently for simplicity
- Track everything in Git so you can clone and stow on a new machine quickly
- Write a `bootstrap.sh` script to restore everything in one go (optional)

---

## ✅ Bootstrap Example

```sh
#!/bin/bash

set -e

cd ~/dotfiles

for dir in */ ; do
  stow --target=$HOME "$dir"
done
```

---

## 🔒 Dotfiles Philosophy

- Source-controlled  
- Symlinked for atomic updates  
- Reproducible across machines
