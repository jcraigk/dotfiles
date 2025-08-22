# Oh My Zsh
ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="muse"
source "$ZSH/oh-my-zsh.sh"

# Prompt
source "$HOME/code/dotfiles/zsh_config/prompt.zsh"

# Tools
fpath=(/usr/local/share/zsh-completions $fpath)
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# Environment
export CLICOLOR=1;
export PATH="$HOME/bin:$HOME/code/scripts:$HOME/.local/bin:$PATH"
source "$HOME/.aliases"
export EDITOR="cursor --wait"

# Load work configuration if it exists, otherwise activate mise
if [[ -f "$HOME/code/dotfiles/zsh_config/employer.zsh" ]]; then
  source "$HOME/code/dotfiles/zsh_config/employer.zsh"
else
  eval "$(mise activate zsh)"
fi
