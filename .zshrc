# Oh My Zsh
ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="muse"
source "$ZSH/oh-my-zsh.sh"

# Prompt and aliases
source "${0:A:h}/zsh_config/prompt.zsh"
source "${0:A:h}/zsh_config/aliases.zsh"

# Tools
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# Environment
export CLICOLOR=1;
export PATH="$HOME/bin:$HOME/code/scripts:$HOME/.local/bin:/opt/homebrew/bin/:$PATH"
export EDITOR="cursor --wait"

# Device-specific config
if [[ -f "${0:A:h}/zsh_config/employer.zsh" ]]; then
  source "${0:A:h}/zsh_config/employer.zsh"
else
  if [[ -f "${0:A:h}/zsh_config/private.zsh" ]]; then
    source "${0:A:h}/zsh_config/private.zsh"
  fi
  eval "$(mise activate zsh)"
fi
