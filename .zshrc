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
export EDITOR="code"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

. /opt/homebrew/opt/asdf/libexec/asdf.sh
