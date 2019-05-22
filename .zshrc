export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="muse"

COMPLETION_WAITING_DOTS=false

# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
plugins=(git)

source $ZSH/oh-my-zsh.sh

fpath=(/usr/local/share/zsh-completions $fpath)
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#########################
# jck config

export CLICOLOR=1;
export PATH=/Users/jcraigkuhn/bin:/j/scripts:$PATH:

source "$HOME/.aliases"

export PATH="$PATH:$HOME/.rvm/bin"
export EDITOR="atom"
