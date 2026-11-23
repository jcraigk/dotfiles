#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Homebrew and packages (macOS only; see README for Linux)
if [[ "$(uname)" == "Darwin" ]]; then
  if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Put brew on PATH for the rest of this script (Apple Silicon or Intel)
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  echo "Installing brew packages..."
  brew install \
    awscli \
    eza \
    git-delta \
    mise \
    oh-my-posh \
    zoxide \
    zsh-fast-syntax-highlighting
  brew install --cask font-jetbrains-mono-nerd-font
fi

# Symlink repo to ~/dotfiles (skip if already there)
if [[ "$DOTFILES_DIR" != "$HOME/dotfiles" ]]; then
  if [ -L "$HOME/dotfiles" ]; then
    rm "$HOME/dotfiles"
  elif [ -e "$HOME/dotfiles" ]; then
    echo "Error: ~/dotfiles exists and is not a symlink"
    exit 1
  fi
  ln -s "$DOTFILES_DIR" "$HOME/dotfiles"
  echo "  ~/dotfiles -> $DOTFILES_DIR"
else
  echo "  Already at ~/dotfiles — skipping symlink"
fi

# Symlink individual dotfiles
link() {
  local src="$HOME/dotfiles/$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  [ -L "$dest" ] && rm "$dest"
  ln -s "$src" "$dest"
  echo "  $dest -> $src"
}

link .gitconfig "$HOME/.gitconfig"
link .irbrc "$HOME/.irbrc"
link .zshrc "$HOME/.zshrc"
link ghostty "$HOME/.config/ghostty"

echo "Done!"
