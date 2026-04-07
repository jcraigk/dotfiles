# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# Environment
if [[ "$(uname)" == "Darwin" ]]; then
  export PATH="$HOME/bin:$HOME/code/scripts:$HOME/.local/bin:/opt/homebrew/bin:$PATH"
else
  export PATH="$HOME/bin:$HOME/code/scripts:$HOME/.local/bin:$PATH"
fi
WORDCHARS=''
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
command -v code &>/dev/null && export EDITOR="code --wait"

# Tools
if [[ -z "$SSH_CONNECTION" ]]; then
  _fsh_paths=(
    /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
    /usr/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
    "$HOME/.local/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
  )
  for _fsh in "${_fsh_paths[@]}"; do
    [[ -f "$_fsh" ]] && { source "$_fsh"; break; }
  done
  unset _fsh _fsh_paths
fi
zle_highlight=(paste:none)

command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
command -v mise &>/dev/null && eval "$(mise activate --shims zsh)"

# Aliases
source "$HOME/dotfiles/zsh/aliases.zsh"

# Device-specific config (loaded last so it can override aliases/tools)
if [[ -f "$HOME/dotfiles/zsh/local.zsh" ]]; then
  source "$HOME/dotfiles/zsh/local.zsh"
fi

# Oh My Posh shell prompt
if command -v oh-my-posh &>/dev/null; then
  source "$HOME/dotfiles/zsh/oh-my-posh.zsh"
fi

# Ghostty terminal enhancements
source "$HOME/dotfiles/zsh/ghostty.zsh"

# # Kill pagers in Cursor's terminal so tools print plain output
# if [ "$CURSOR_AGENT" = "1" ]; then
#   export PAGER=cat
#   export GIT_PAGER=cat
#   export MANPAGER=cat
#   export PSQL_PAGER=cat
#   export DELTA_PAGER=cat
#   export LESS=
#   export DISABLE_SPRING=1
#   command -v mise &>/dev/null && eval "$(mise activate zsh --shims)"
# fi
