# Oh My Posh shell prompt
eval "$(oh-my-posh init zsh --config ~/dotfiles/zsh_config/oh-my-posh.json)"

# Custom prompt context (must be AFTER oh-my-posh init, which creates an empty stub)
function set_poshcontext() {
  local cwd=$(pwd -P)

  # Path segment
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local root=$(git rev-parse --show-toplevel)
    local rel=${cwd#$root}
    if [[ -z "$rel" ]]; then
      export POSH_PATH=$(basename "$root")
    else
      export POSH_PATH="$(basename "$root")$rel"
    fi
  elif [[ "$cwd" = "$HOME" ]]; then
    export POSH_PATH=" "
  elif [[ "$cwd" == "$HOME"/* ]]; then
    export POSH_PATH=" ${cwd#$HOME}"
  else
    local -a parts=(${(s:/:)cwd})
    if (( ${#parts[@]} > 3 )); then
      export POSH_PATH="/${parts[1]}/…/${parts[-1]}"
    else
      export POSH_PATH="$cwd"
    fi
  fi

  # Git segment
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
      if (( ${#branch} > 24 )); then
        branch="${branch:0:22}…"
      fi
      if [[ -n "$(git status --porcelain --ignore-submodules=dirty 2>/dev/null)" ]]; then
        export POSH_GIT_COLOR="#cc6666"
      else
        export POSH_GIT_COLOR="#808080"
      fi
      export POSH_GIT_BRANCH=" $branch"
    else
      export POSH_GIT_BRANCH=""
    fi
  else
    export POSH_GIT_BRANCH=""
  fi

  # Random icon (only if not at HOME)
  if [[ "$cwd" != "$HOME" ]]; then
    local icons=("󰇊" "󰇋" "󰇌" "󰇍" "󰇎" "󰇏" "󱢣" "󱢧" "󱢫" "󱢯" "" "󰊠" "󱚡" "" "󱇪" "󱎶" "" "" "" "" "" "󰴈" "" "󰹡" "" "󰷚" "" "" "󰌪" "" "" "" "" "󰃠" "" "" "󰹻" "")
    export POSH_ICON="${icons[$((RANDOM % ${#icons[@]} + 1))]}"
  else
    export POSH_ICON=""
  fi
}
