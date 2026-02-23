# Environment
if [[ "$(uname)" == "Darwin" ]]; then
  export PATH="$HOME/bin:$HOME/code/scripts:$HOME/.local/bin:/opt/homebrew/bin:$PATH"
else
  export PATH="$HOME/bin:$HOME/code/scripts:$HOME/.local/bin:$PATH"
fi
WORDCHARS=''
command -v cursor &>/dev/null && export EDITOR="cursor --wait"

# Tools
_fsh_paths=(
  /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
  /usr/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
  "$HOME/.local/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
)
for _fsh in "${_fsh_paths[@]}"; do
  [[ -f "$_fsh" ]] && { source "$_fsh"; break; }
done
unset _fsh _fsh_paths

command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
command -v mise &>/dev/null && eval "$(mise activate --shims zsh)"

# Device-specific config
if [[ -f "$HOME/dotfiles/zsh/local.zsh" ]]; then
  source "$HOME/dotfiles/zsh/local.zsh"
fi

# Aliases
source "$HOME/dotfiles/zsh/aliases.zsh"

# Oh My Posh shell prompt
if command -v oh-my-posh &>/dev/null; then
  source "$HOME/dotfiles/zsh/oh-my-posh.zsh"
fi

# Ghostty terminal enhancements
source "$HOME/dotfiles/zsh/ghostty.zsh"

# Kill pagers in Cursor's terminal so tools print plain output
if [ "$CURSOR_AGENT" = "1" ]; then
  export PAGER=cat
  export GIT_PAGER=cat
  export MANPAGER=cat
  export PSQL_PAGER=cat
  export DELTA_PAGER=cat
  export LESS=
  export DISABLE_SPRING=1
  command -v mise &>/dev/null && eval "$(mise activate zsh)"
fi
