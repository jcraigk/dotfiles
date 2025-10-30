# Environment
export PATH="$HOME/bin:$HOME/code/scripts:$HOME/.local/bin:/opt/homebrew/bin/:$PATH"
export EDITOR="cursor --wait"

# Tools
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
eval "$(zoxide init zsh)"

# Cursor-only: kill pagers so tools print plain output
if [ "$CURSOR_AGENT" = "1" ]; then
  export PAGER=cat
  export GIT_PAGER=cat
  export MANPAGER=cat
  export PSQL_PAGER=cat
  export DELTA_PAGER=cat
  export LESS=
fi

# Device-specific config
if [[ -f "${0:A:h}/zsh_config/local.zsh" ]]; then
  source "${0:A:h}/zsh_config/local.zsh"
fi

# Aliases
source "${0:A:h}/zsh_config/aliases.zsh"

# Oh-my-posh
eval "$(oh-my-posh init zsh --config ~/dotfiles/zsh_config/oh-my-posh.json)"
