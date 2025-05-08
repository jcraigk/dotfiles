export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="muse"

COMPLETION_WAITING_DOTS=false
ZSH_DISABLE_COMPFIX=true

# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
plugins=(git)

source $ZSH/oh-my-zsh.sh

fpath=(/usr/local/share/zsh-completions $fpath)
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# JCK
export CLICOLOR=1;
export PATH="$HOME/bin:$HOME/code/scripts:$PATH:"
source "$HOME/.aliases"
export EDITOR="cursor --wait"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. /opt/homebrew/opt/asdf/libexec/asdf.sh

eval "$(/opt/homebrew/bin/brew shellenv)"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
