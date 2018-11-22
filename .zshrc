# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:/usr/local/sbin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=/Users/jcraigkuhn/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
#ZSH_THEME="random"
#ZSH_THEME="agnoster"
#ZSH_THEME="macovsky-ruby"
#ZSH_THEME="3den"
#ZSH_THEME="smt"
#ZSH_THEME="murilasso"
#ZSH_THEME="josh"
#ZSH_THEME="gallifrey"
#ZSH_THEME="jreese"
ZSH_THEME="muse"
#ZSH_THEME="sporty_256"
#ZSH_THEME="robbyrussell"

#print $RANDOM_THEME <-- to discover which is the current random theme

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

#########################
# jcraigk config

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

fpath=(/usr/local/share/zsh-completions $fpath)
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
