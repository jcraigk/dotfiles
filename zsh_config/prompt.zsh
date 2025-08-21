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

# Git fork icon using Unicode point U+E0A0
typeset -g GIT_ICON=$'\ue0a0'

# Cache variables
typeset -g _PROMPT_IN_GIT=""
typeset -g _PROMPT_GIT_BRANCH=""
typeset -g _PROMPT_GIT_DIRTY=""

# Fast git info function - only updates when needed
fast_git_info() {
  # Check if we're in a git repo
  local git_dir=$(git rev-parse --git-dir 2>/dev/null)
  
  if [[ -n "$git_dir" ]]; then
    _PROMPT_IN_GIT="1"
    # Get branch name efficiently
    _PROMPT_GIT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    
    # Check if repo is dirty (limit to first result for speed)
    if [[ -n "$(git status --porcelain 2>/dev/null | head -1)" ]]; then
      _PROMPT_GIT_DIRTY="1"
    else
      _PROMPT_GIT_DIRTY=""
    fi
  else
    _PROMPT_IN_GIT=""
    _PROMPT_GIT_BRANCH=""
    _PROMPT_GIT_DIRTY=""
  fi
}

# Build prompt string
build_prompt() {
  local dir_part
  local git_part=""
  
  # Directory part
  if [[ -n "$_PROMPT_IN_GIT" ]]; then
    dir_part="${FG[068]}%1~%{$reset_color%}"  # Just last segment in git repos
    
    # Git part
    if [[ -n "$_PROMPT_GIT_DIRTY" ]]; then
      git_part=" ${FG[088]}${GIT_ICON} %{$reset_color%}${FG[245]}${_PROMPT_GIT_BRANCH}"
    else
      git_part=" ${FG[245]}${GIT_ICON} %{$reset_color%}${FG[245]}${_PROMPT_GIT_BRANCH}"
    fi
  else
    dir_part="${FG[068]}%~%{$reset_color%}"  # Full path when not in git
  fi
  
  echo -n "${dir_part}${git_part}"
}

# Pre-command hook to update git info
precmd() {
  fast_git_info
}

PROMPT='$(build_prompt) ${FG[245]}➜%{$reset_color%} '
RPROMPT=''
