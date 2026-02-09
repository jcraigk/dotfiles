# Environment
export PATH="$HOME/bin:$HOME/code/scripts:$HOME/.local/bin:/opt/homebrew/bin/:$PATH"
export EDITOR="cursor --wait"

# Tools
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
eval "$(zoxide init zsh)"

# Device-specific config
if [[ -f "${0:A:h}/zsh_config/local.zsh" ]]; then
  source "${0:A:h}/zsh_config/local.zsh"
fi

# Aliases
source "${0:A:h}/zsh_config/aliases.zsh"

# Oh My Posh shell prompt
source "${0:A:h}/zsh_config/oh-my-posh.zsh"

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
