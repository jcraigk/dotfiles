# Separator line between commands (like Warp)
_sep_newshell=true
_sep_prev_icon=""

function _draw_separator() {
  if $_sep_newshell; then
    _sep_newshell=false
    return
  fi
  local icon="${_sep_prev_icon:-◆}"
  local center="◇  ${icon}  ◇"
  local pad=$(( COLUMNS / 4 ))
  local side=$(( (COLUMNS - pad * 2 - ${#center}) / 2 ))
  print -P "%F{234}${(l:$pad:: :)}${(l:$side::─:)}${center}${(l:$side::─:)}%f"
}

function _save_separator_icon() {
  _sep_prev_icon="$POSH_ICON"
}

precmd_functions+=(_draw_separator)
precmd_functions+=(_save_separator_icon)
