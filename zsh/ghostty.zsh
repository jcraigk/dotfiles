# Separator line between commands (like Warp)
_sep_newshell=true
_sep_prev_icon=""
_sep_prev_path=""
_sep_home_icon=$'\uf015'

function _draw_separator() {
  if $_sep_newshell; then
    _sep_newshell=false
    return
  fi

  local icon="${_sep_prev_icon:-$_sep_home_icon}"
  local center="◇  ${icon}  ◇"
  local raw_ts="$(date +"%-b %-d, %-I:%M%p")"
  local path_str="${_sep_prev_path}"
  if (( ${#path_str} > 25 )); then
    path_str="…${path_str: -24}"
  fi
  local left="${path_str:+ ${path_str} }"
  [[ "$icon" == "$_sep_home_icon" ]] && left=""
  local right=" ${raw_ts/%[AP]M/${(L)raw_ts[-2,-1]}} "

  local pad=$(( COLUMNS / 4 ))
  local inner=$(( COLUMNS - pad * 2 ))
  local center_len=${#center}
  local left_zone=$(( (inner - center_len) / 2 ))
  local right_zone=$(( inner - center_len - left_zone ))

  if [[ -n "$left" ]]; then
    local ll=$(( (left_zone - ${#left}) / 2 ))
    local lr=$(( left_zone - ${#left} - ll ))
  else
    local ll=$left_zone lr=0
  fi
  local rl=$(( (right_zone - ${#right}) / 2 ))
  local rr=$(( right_zone - ${#right} - rl ))

  print -P "%F{233}${(l:$pad:: :)}${(l:$ll::─:)}${left}${(l:$lr::─:)}${center}${(l:$rl::─:)}${right}${(l:$rr::─:)}%f"
}

function _save_separator_context() {
  _sep_prev_icon="$POSH_ICON"
  _sep_prev_path="$POSH_PATH"
}

precmd_functions+=(_draw_separator)
precmd_functions+=(_save_separator_context)
