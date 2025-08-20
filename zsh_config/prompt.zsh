# Zsh Prompt Configuration
# This file should be sourced AFTER oh-my-zsh to override the theme's prompt

# Theme knobs
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_STAGED=""
ZSH_THEME_GIT_PROMPT_UNTRACKED=""

# Enable prompt substitution
setopt promptsubst

# Custom function to show full path when not in git repo, last segment when in git
prompt_dir() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    # In a git repo - show only last segment
    echo "%1~"
  else
    # Not in a git repo - show full path
    echo "%~"
  fi
}

# Custom function to handle all git info with proper spacing
git_info() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    # Git fork icon using Unicode point U+E0A0
    local git_icon=$'\ue0a0'
    local branch=$(git_current_branch 2>/dev/null)
    
    # Check if there are any changes (unstaged or staged)
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
      echo " ${FG[088]}${git_icon} %{$reset_color%}${FG[245]}${branch}"  # Red icon for dirty
    else
      echo " ${FG[245]}${git_icon} %{$reset_color%}${FG[245]}${branch}"  # Light grey icon for clean
    fi
  fi
}

PROMPT='${FG[068]}$(prompt_dir)%{$reset_color%}$(git_info) %(?.${FG[245]}➜.${FG[088]}➜)%{$reset_color%} '
RPROMPT=''
