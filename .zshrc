# Environment
export PATH="$HOME/bin:$HOME/code/scripts:$HOME/.local/bin:/opt/homebrew/bin/:$PATH"
export EDITOR="cursor --wait"

# Tools
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
eval "$(zoxide init zsh)"

# Device-specific config
if [[ -f "$HOME/dotfiles/zsh/local.zsh" ]]; then
  source "$HOME/dotfiles/zsh/local.zsh"
fi

# Aliases
source "$HOME/dotfiles/zsh/aliases.zsh"

# Oh My Posh shell prompt
source "$HOME/dotfiles/zsh/oh-my-posh.zsh"

# Ghostty terminal enhancements
source "$HOME/dotfiles/zsh/ghostty.zsh"

# Kill pagers in Cursor's terminal so tools print plain output
# Re-activate mise for Cursor Agent to ensure shims are in PATH
if [ "$CURSOR_AGENT" = "1" ]; then
  export PAGER=cat
  export GIT_PAGER=cat
  export MANPAGER=cat
  export PSQL_PAGER=cat
  export DELTA_PAGER=cat
  export LESS=
  export DISABLE_SPRING=1
  eval "$(mise activate zsh)"
fi
