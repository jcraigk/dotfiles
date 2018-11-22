export ZSH=/Users/jcraigkuhn/.oh-my-zsh
ZSH_THEME="muse"

ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

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

# Aliases
alias cj='cd /j; l'
alias ll='ls -al'
alias gs="git status"
alias gd="git diff"
alias ga="git add -A"
git_commit() {
  git commit -m "$1"
}
alias gc=git_commit
alias gp="git push"
alias gpu="git pull"
alias gb="git branch"
alias gco="git checkout"
git_log() {
  git log -${1:-3}
}
alias gl=git_log
git_squash() {
  NUM=${1:-2}
  read -r -p "Commit and squash last $NUM commits? [y/N] " response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
  then
    ga
    gc "Misc cleanup (squash me!)"
    git reset --soft HEAD~$NUM &&
    git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"
  fi
}
alias gsq=git_squash
alias gr="git rebase"
alias gcss="git commit --amend --no-edit"

alias capstag="cap staging deploy"
alias caplive="cap live deploy"

# DB Reset test database (Rails)
rake_db_test_rebuild() {
  bundle exec rake db:drop RAILS_ENV=test
  bundle exec rake db:create RAILS_ENV=test
  bundle exec rake db:schema:load RAILS_ENV=test
}
alias db-test-rebuild=rake_db_test_rebuild
alias dc="docker-compose"
alias bx="bundle exec"

alias dstop='docker stop $(docker ps -aq)'
alias dps='docker ps --format "table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Ports}}"'
alias dpsa='docker ps --format "table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Ports}}" -a'
alias dx='docker exec -it'
alias dxa='docker-compose exec app'
alias dcu='docker-compose up'
# alias dcd='docker-compose down'
alias dcb='docker-compose build'
alias dca='docker-compose run app'
alias dspec='RAILS_ENV=test docker-compose run app rspec'
alias dbash='docker-compose run --service-ports app bash'
alias dvolprune="docker volume rm $(docker volume ls -q | awk '!/_/' | tr '\n' ' ')"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
