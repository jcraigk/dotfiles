alias dotfiles="cd ~/dotfiles && cursor ."

# Shell
alias ll="eza -al"
pd() {
  cd "$HOME/code/$1"
}
alias run="mise run"
alias see="overmind connect"

# Git
alias gs="git status --short"
gd() {
  git add -N .
  git diff
}
alias gdc="git diff --cached"
alias gdl="git diff | delta --line-numbers"
alias ga="git add -A"
alias gap="git add -p"
git_commit() {
  git commit -m "$1"
}
git_commit_no_verify() {
  git commit --no-verify -m "$1"
}
alias gcn=git_commit_no_verify
alias gc=git_commit
alias gp="git push"
alias gpp="git push -u origin HEAD"
alias gpu="git pull"
alias gb="git branch"
alias gbd="git branch -D"
alias gco="git checkout"
alias gcob="git checkout -b"
alias greset="git reset --hard"
git_log() {
  git log -${1:-3}
}
alias gl=git_log
gsq() {
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
alias gr="git rebase"
alias gcss="git commit --amend --no-edit --no-verify"
gdelworktrees() {
  git worktree list --porcelain | \
   grep 'worktree ' | awk '{print $2}' | \
   grep -v "$(git rev-parse --show-toplevel)" | \
   xargs -I {} bash -c 'echo "Removing {}" && git worktree remove --force "{}"'
}

# Rails
alias br="bundle exec rspec"
alias bx="bundle exec"
alias bc="bundle exec bin/rails console -- --noautocomplete"
rails_db_test_rebuild() {
  bundle exec rails db:drop RAILS_ENV=test
  bundle exec rails db:create RAILS_ENV=test
  bundle exec rails db:schema:load RAILS_ENV=test
}
alias db-test-rebuild=rails_db_test_rebuild
alias rclean=make_clean_with_rails_reset
make_clean_with_rails_reset() {
  run cleanforce
  run services
  sleep 3
  rails db:reset
  run dev
}
alias spec="RUBYOPT='-W0' rspec"
alias railsc="bundle exec rails console"
alias bupdate="bundle update --all"
alias binstall="bundle install"

# Docker
alias dbash="docker compose run --service-ports app bash"
alias dc="docker compose"
alias dca="docker compose run app"
alias dcb="docker compose build"
alias dcu="docker compose up"
alias dokpub="git push dokku main:main"
alias dps='docker ps --format "table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Ports}}"'
alias dpsa='docker ps --format "table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Ports}}" -a'
alias dspec="RAILS_ENV=test docker compose run app rspec"
alias dstop="docker stop $(docker ps -aq)"
alias dvolprune="docker volume rm $(docker volume ls -q | awk '!/_/' | tr '\n' ' ')"
alias dx="docker exec -it"
alias dxa="docker compose exec app"
alias ld="lazydocker"
drestart() {
  docker compose stop app
  docker compose start app
}

# Tools
alias a="cursor ."
crules() {
  echo "symlinking cursor config files..."
  mkdir -p ./.cursor/rules
  find ./.cursor/rules -maxdepth 1 -type l -delete
  for f in ~/dotfiles/cursor/rules/*.mdc; do
    ln -sf "$f" ./.cursor/rules/
    echo "rules/$(basename "$f")"
  done
  mkdir -p ./.cursor/commands
  find ./.cursor/commands -maxdepth 1 -type l -delete
  for f in ~/dotfiles/cursor/commands/*; do
    ln -sf "$f" ./.cursor/commands/
    echo "commands/$(basename "$f")"
  done
  echo "...done"
}
alias minspect="npx @modelcontextprotocol/inspector@latest http://localhost:8787/mcp"

gclean() {
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not a git repo"
    return 1
  fi

  current_branch=$(git rev-parse --abbrev-ref HEAD)

  # Get all worktrees with their branches
  declare -A worktree_paths
  while IFS= read -r line; do
    if [[ $line == worktree* ]]; then
      wt_path="${line#worktree }"
    elif [[ $line == branch* ]]; then
      wt_branch="${line#branch refs/heads/}"
      worktree_paths[$wt_branch]="$wt_path"
    fi
  done < <(git worktree list --porcelain)

  # Loop over all local branches
  for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do

    # Skip main and current branch
    if [ "$branch" = "main" ] || [ "$branch" = "$current_branch" ]; then
      continue
    fi

    # Check if branch has a worktree
    if [[ -n "${worktree_paths[$branch]}" ]]; then
      print -n "Delete \033[38;2;95;179;255m$branch\033[0m (with worktree at ${worktree_paths[$branch]})? "
    else
      print -n "Delete \033[38;2;95;179;255m$branch\033[0m ? "
    fi

    read ans
    case "$ans" in
      [Yy]* )
        # Remove worktree first if it exists
        if [[ -n "${worktree_paths[$branch]}" ]]; then
          echo "  Removing worktree at ${worktree_paths[$branch]}"
          git worktree remove --force "${worktree_paths[$branch]}"
        fi
        git branch -D "$branch"
        ;;
    esac
  done
}
