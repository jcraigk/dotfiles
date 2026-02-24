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
  local right=" ${raw_ts/%[AP]M/${(L)raw_ts[-2,-1]}} "
  local center_len=${#center}

  local left_content
  if [[ "$icon" == "$_sep_home_icon" ]]; then
    left_content="${HOST%.local}"
  else
    left_content="${_sep_prev_path}"
    if (( ${#left_content} > 25 )); then
      left_content="…${left_content: -24}"
    fi
  fi

  local pad=$(( COLUMNS / 8 ))
  (( pad < 4 )) && pad=4
  local inner=$(( COLUMNS - pad * 2 ))

  local left_zone=$(( (inner - center_len) / 2 ))
  local right_zone=$(( inner - center_len - left_zone ))

  local max_left=$(( left_zone - 10 ))
  if (( ${#left_content} > max_left )); then
    (( max_left < 15 )) && max_left=15
    left_content="${left_content:0:$max_left}"
  fi

  local left="${left_content:+ ${left_content} }"
  local ll lr
  if [[ -n "$left" ]]; then
    ll=$(( (left_zone - ${#left}) / 2 ))
    lr=$(( left_zone - ${#left} - ll ))
  else
    ll=$left_zone lr=0
  fi
  local rl=$(( (right_zone - ${#right}) / 2 ))
  local rr=$(( right_zone - ${#right} - rl ))

  (( ll < 0 )) && ll=0
  (( lr < 0 )) && lr=0
  (( rl < 0 )) && rl=0
  (( rr < 0 )) && rr=0

  print -P "%F{236}${(l:$pad:: :)}${(l:$ll::─:)}${left}${(l:$lr::─:)}${center}${(l:$rl::─:)}${right}${(l:$rr::─:)}%f"
}

function _save_separator_context() {
  _sep_prev_icon="$POSH_ICON"
  _sep_prev_path="$POSH_PATH"
}

precmd_functions+=(_draw_separator)
precmd_functions+=(_save_separator_context)
