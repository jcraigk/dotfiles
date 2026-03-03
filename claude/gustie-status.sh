#!/bin/bash
# gustie-status — Configure Claude Code statusline layout and width.
#
# Usage:
#   gustie-status                      # cycle to next mode
#   gustie-status full                 # jump directly to full
#   gustie-status compact              # jump directly to compact
#   gustie-status minimal              # jump directly to minimal
#   gustie-status debug                # toggle debug overlay on/off (independent of mode)
#   gustie-status logos                # toggle Gusto/Bedrock logos on/off (independent of mode)
#   gustie-status style                # toggle output style label on/off (independent of mode)
#   gustie-status flair                # toggle progress bar decorations on/off (icon + texture)
#   gustie-status color                # cycle color mode: default → mono → dim → default
#   gustie-status --width 60           # set bar width to 60
#   gustie-status --width auto         # reset to auto (terminal width)
#   gustie-status compact --width 50   # set mode and width together
#
# State is persisted in ~/.claude/statusline-state.json
# The statusline script reads this file on every render.

STATE_FILE="$HOME/.claude/statusline-state.json"
VALID_MODES="full compact minimal"

# Ensure the directory exists
mkdir -p "$(dirname "$STATE_FILE")"

# Read current state (defaults: mode=full, width=auto, debug=false, logos=true, style=true, flair=true, color_mode=default)
current_mode="full"
current_width="auto"
current_debug="false"
current_logos="true"
current_style="true"
current_flair="true"
current_color_mode="default"
if [[ -f "$STATE_FILE" ]]; then
  current_mode=$(cat "$STATE_FILE" | grep -o '"mode"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"/\1/')
  current_width=$(cat "$STATE_FILE" | grep -o '"width"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"/\1/')
  current_debug=$(cat "$STATE_FILE" | grep -o '"debug"[[:space:]]*:[[:space:]]*[a-z]*' | head -1 | sed 's/.*:[[:space:]]*//')
  current_logos=$(cat "$STATE_FILE" | grep -o '"logos"[[:space:]]*:[[:space:]]*[a-z]*' | head -1 | sed 's/.*:[[:space:]]*//')
  current_style=$(cat "$STATE_FILE" | grep -o '"style"[[:space:]]*:[[:space:]]*[a-z]*' | head -1 | sed 's/.*:[[:space:]]*//')
  current_flair=$(cat "$STATE_FILE" | grep -o '"flair"[[:space:]]*:[[:space:]]*[a-z]*' | head -1 | sed 's/.*:[[:space:]]*//')
  current_color_mode=$(cat "$STATE_FILE" | grep -o '"color_mode"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"/\1/')
  current_mode="${current_mode:-full}"
  current_width="${current_width:-auto}"
  current_debug="${current_debug:-false}"
  current_logos="${current_logos:-true}"
  current_style="${current_style:-true}"
  current_flair="${current_flair:-true}"
  current_color_mode="${current_color_mode:-default}"
  # Migrate: if mode was "debug", reset to "full" and enable debug flag
  if [[ "$current_mode" == "debug" ]]; then
    current_mode="full"
    current_debug="true"
  fi
fi

# ── Parse arguments ──────────────────────────────────────────────
next_mode=""
next_width=""
toggle_debug=false
toggle_logos=false
toggle_style=false
toggle_flair=false
toggle_color=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --width|-w)
      if [[ -z "$2" ]]; then
        printf '\033[38;2;224;108;117m✗ --width requires a value (number or "auto")\033[0m\n'
        exit 1
      fi
      if [[ "$2" == "auto" ]]; then
        next_width="auto"
      elif [[ "$2" =~ ^[0-9]+$ ]] && (( $2 >= 50 && $2 <= 150 )); then
        next_width="$2"
      else
        printf '\033[38;2;224;108;117m✗ Width must be 50–150 or "auto"\033[0m\n'
        exit 1
      fi
      shift 2
      ;;
    debug)
      toggle_debug=true
      shift
      ;;
    logos)
      toggle_logos=true
      shift
      ;;
    style)
      toggle_style=true
      shift
      ;;
    flair)
      toggle_flair=true
      shift
      ;;
    color)
      toggle_color=true
      shift
      ;;
    *)
      # Treat as mode
      if [[ -z "$next_mode" ]]; then
        if ! echo "$VALID_MODES" | grep -qw "$1"; then
          printf '\033[38;2;224;108;117m✗ Unknown mode "%s"\033[0m\n' "$1"
          printf '  Valid modes: %s\n' "$VALID_MODES"
          printf '  Toggles: debug, logos, style, flair, color\n'
          printf '  Options: --width <20–200|auto>\n'
          exit 1
        fi
        next_mode="$1"
      fi
      shift
      ;;
  esac
done

# Handle debug toggle separately
next_debug="$current_debug"
if [[ "$toggle_debug" == "true" ]]; then
  if [[ "$current_debug" == "true" ]]; then
    next_debug="false"
  else
    next_debug="true"
  fi
fi

# Handle logos toggle separately
next_logos="$current_logos"
if [[ "$toggle_logos" == "true" ]]; then
  if [[ "$current_logos" == "true" ]]; then
    next_logos="false"
  else
    next_logos="true"
  fi
fi

# Handle style toggle separately
next_style="$current_style"
if [[ "$toggle_style" == "true" ]]; then
  if [[ "$current_style" == "true" ]]; then
    next_style="false"
  else
    next_style="true"
  fi
fi

# Handle flair toggle separately
next_flair="$current_flair"
if [[ "$toggle_flair" == "true" ]]; then
  if [[ "$current_flair" == "true" ]]; then
    next_flair="false"
  else
    next_flair="true"
  fi
fi

# Handle color mode cycle: default → mono → dim → default
next_color_mode="$current_color_mode"
if [[ "$toggle_color" == "true" ]]; then
  case "$current_color_mode" in
    default) next_color_mode="mono" ;;
    mono)    next_color_mode="dim" ;;
    dim)     next_color_mode="default" ;;
    *)       next_color_mode="default" ;;
  esac
fi

# If no mode given AND no toggles changed AND width wasn't set — cycle layout
if [[ -z "$next_mode" && "$toggle_debug" == "false" && "$toggle_logos" == "false" && "$toggle_style" == "false" && "$toggle_flair" == "false" && "$toggle_color" == "false" && -z "$next_width" ]]; then
  case "$current_mode" in
    full)    next_mode="compact" ;;
    compact) next_mode="minimal" ;;
    *)       next_mode="full" ;;
  esac
fi

# Apply: keep current values for anything not explicitly changed
next_mode="${next_mode:-$current_mode}"
next_width="${next_width:-$current_width}"

# Write new state
cat > "$STATE_FILE" << EOF
{"mode": "$next_mode", "width": "$next_width", "debug": $next_debug, "logos": $next_logos, "style": $next_style, "flair": $next_flair, "color_mode": "$next_color_mode"}
EOF

# ── Visual feedback ──────────────────────────────────────────────
CYAN='\033[38;2;86;182;194m'
DIM='\033[38;2;120;135;155m'
GREEN='\033[38;2;152;195;121m'
RED='\033[38;2;224;108;117m'
RST='\033[0m'

case "$next_mode" in
  full)    mode_desc="3 rows — folder/branch, progress bar, logo/cost" ;;
  compact) mode_desc="2 rows — folder/branch, progress bar (cost in bar)" ;;
  minimal) mode_desc="1 row  — progress bar only" ;;
esac

printf "${CYAN}⟳ Statusline → %s${RST} (%s)" "$next_mode" "$mode_desc"

if [[ "$next_width" == "auto" ]]; then
  printf " ${DIM}width: auto${RST}"
else
  printf " ${DIM}width: %s${RST}" "$next_width"
fi

if [[ "$next_debug" == "true" ]]; then
  printf " ${GREEN}debug: on${RST}"
else
  printf " ${DIM}debug: off${RST}"
fi

if [[ "$next_logos" == "true" ]]; then
  printf " ${GREEN}logos: on${RST}"
else
  printf " ${DIM}logos: off${RST}"
fi

if [[ "$next_style" == "true" ]]; then
  printf " ${GREEN}style: on${RST}"
else
  printf " ${DIM}style: off${RST}"
fi

if [[ "$next_flair" == "true" ]]; then
  printf " ${GREEN}flair: on${RST}"
else
  printf " ${DIM}flair: off${RST}"
fi

if [[ "$next_color_mode" == "default" ]]; then
  printf " ${DIM}color: default${RST}"
elif [[ "$next_color_mode" == "mono" ]]; then
  printf " ${GREEN}color: mono${RST}"
elif [[ "$next_color_mode" == "dim" ]]; then
  printf " ${GREEN}color: dim${RST}"
fi
printf '\n'
