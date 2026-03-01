#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# ── Extract fields from Claude Code JSON ──────────────────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')

# Model: extract friendly name + version from ID
raw_model=$(echo "$input" | jq -r '.model.id // .model.display_name // .model // empty')
model=""
if [[ "$raw_model" =~ (opus|sonnet|haiku) ]]; then
  name="${BASH_REMATCH[1]}"
  # Capitalize first letter
  model="$(tr '[:lower:]' '[:upper:]' <<< "${name:0:1}")${name:1}"
  # Extract version like "4-6" → "4.6"
  if [[ "$raw_model" =~ [0-9]+-[0-9]+ ]]; then
    ver="${BASH_REMATCH[0]}"
    model+=" ${ver//-/.}"
  fi
else
  model="$raw_model"
fi

cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
total_duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
total_api_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // empty')
output_style=$(echo "$input" | jq -r '.output_style.name // empty')
# lines_added/lines_removed: computed from git diff below (not from Claude's cost fields)

# Context window — may or may not be present
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')


# MCP servers — aggregate from global ~/.claude.json and project .mcp.json
mcp_total=0
mcp_enabled=0
for mcp_file in "$HOME/.claude.json" "${project_dir}/.mcp.json" "${cwd}/.mcp.json"; do
  if [[ -f "$mcp_file" ]]; then
    file_total=$(jq -r '.mcpServers // {} | length' "$mcp_file" 2>/dev/null)
    file_disabled=$(jq -r '[.mcpServers // {} | to_entries[] | select(.value.disabled == true)] | length' "$mcp_file" 2>/dev/null)
    mcp_total=$(( mcp_total + ${file_total:-0} ))
    mcp_enabled=$(( mcp_enabled + ${file_total:-0} - ${file_disabled:-0} ))
  fi
done

# ── Colors (4-color palette + brand) ──────────────────────────────
# Primary: workspace identity
BLUE="\033[38;2;95;179;255m"
MAGENTA="\033[38;2;198;120;221m"
CYAN="\033[38;2;86;182;194m"
# Muted: secondary info (MCP, mode, timing)
MAUVE="\033[38;2;145;130;155m"
# Accent: money
DARK_GREEN="\033[38;2;110;155;95m"
# Alert: warnings (unsaved, SSO expiring, progress bar caution)
ALERT="\033[38;2;220;175;100m"
# Danger: critical (progress bar 80%+, SSO expired)
RED="\033[38;2;224;108;117m"
# Progress bar healthy state
GREEN="\033[38;2;152;195;121m"
# Brand
GUSTO_CORAL="\033[1;38;2;245;93;72m"
# AWS
MUSTARD="\033[38;2;170;150;90m"
# Utility
DIM="\033[38;2;85;90;100m"
RESET="\033[0m"

SEP="  "
BULLET="${DIM} · ${RESET}"

# ── Detect effective git repo (current dir or one level deep) ────
git_dir=""
if [[ -n "$cwd" ]]; then
  cd "$cwd" 2>/dev/null
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_dir="$cwd"
  else
    # Look one level deep for a git repo (wrapper folder pattern)
    # Only adopt it if there's exactly ONE git subfolder
    git_subs=()
    for sub in "$cwd"/*/; do
      if [[ -d "$sub/.git" ]]; then
        git_subs+=("${sub%/}")
      fi
    done
    if (( ${#git_subs[@]} == 1 )); then
      git_dir="${git_subs[0]}"
    fi
  fi
fi

# ── Helper: format number with commas ──────────────────────────
_fmt_num() {
  printf "%'d" "$1" 2>/dev/null || printf "%d" "$1"
}

# ── Uncommitted files segment ────────────────────────────────────
dirty_segment=""
if [[ -n "$git_dir" ]]; then
  cd "$git_dir" 2>/dev/null
  dirty_count=$(git -c core.useBuiltinFSMonitor=false status --porcelain --ignore-submodules=dirty 2>/dev/null | wc -l | tr -d ' ')
  if (( dirty_count > 0 )); then
    dirty_icon=$(printf '\xef\x81\x84')  # U+F044
    dirty_segment="${ALERT}${dirty_icon} $(_fmt_num "$dirty_count")${RESET}"
    # Compute lines added/removed from git diff (staged + unstaged)
    lines_added=0
    lines_removed=0
    while IFS=$'\t' read -r added removed _; do
      [[ "$added" == "-" ]] && continue  # skip binary files
      (( lines_added += added ))
      (( lines_removed += removed ))
    done < <(git diff --numstat HEAD 2>/dev/null || git diff --numstat 2>/dev/null)
    # Also count untracked files' lines as added
    while IFS= read -r ufile; do
      ulines=$(wc -l < "$ufile" 2>/dev/null | tr -d ' ')
      (( lines_added += ${ulines:-0} ))
    done < <(git ls-files --others --exclude-standard 2>/dev/null)
    # Append lines added/removed
    plus_icon=$(printf '\xef\x81\xa7')   # U+F067
    minus_icon=$(printf '\xef\x81\xa8')  # U+F068
    diff_parts=""
    if (( lines_added > 0 )); then
      diff_parts+="${GREEN}${plus_icon}$(_fmt_num "$lines_added")${RESET}"
    fi
    if (( lines_removed > 0 )); then
      [[ -n "$diff_parts" ]] && diff_parts+=" "
      diff_parts+="${RED}${minus_icon}$(_fmt_num "$lines_removed")${RESET}"
    fi
    if [[ -n "$diff_parts" ]]; then
      dirty_segment+=" ${DIM}[${RESET}${diff_parts}${DIM}]${RESET}"
    fi
  fi
fi

# ── Nerd Font ellipsis for truncation ────────────────────────────
ELLIPSIS=$(printf '\xef\x85\x81')  # U+F141
MIN_BRANCH=10        # branch gets at least this many chars

# ── Folder + branch segment ──────────────────────────────────────
# Raw folder/branch names — truncation happens later in row 1 budgeting
folder_name=""
branch=""
folder_segment=""
if [[ -n "$cwd" ]]; then
  if [[ -n "$git_dir" ]]; then
    cd "$git_dir" 2>/dev/null
    root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ "$git_dir" == "$cwd" ]]; then
      rel="${cwd#$root}"
      if [[ -z "$rel" ]]; then
        folder_name=$(basename "$root")
      else
        folder_name="$(basename "$root")$rel"
      fi
    else
      folder_name=$(basename "$git_dir")
    fi
    branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  elif [[ "$cwd" == "$HOME" ]]; then
    folder_name="~"
  else
    folder_name=$(basename "$cwd")
  fi
fi

# Model + style segment: built later in row 1 budgeting

# ── Helper: format milliseconds ──────────────────────────────────
# Seconds/minutes: whole numbers only. Hours: up to 2 decimals, trim trailing zeros.
_fmt_duration() {
  local ms=$1
  local total_secs=$(( ms / 1000 ))
  local total_mins=$(( total_secs / 60 ))
  if (( total_mins >= 60 )); then
    # Decimal hours: e.g. 1.25h, 2.5h, 3h — with commas for 1,000+
    local hundredths=$(( total_mins * 100 / 60 ))
    local whole=$(( hundredths / 100 ))
    local frac=$(( hundredths % 100 ))
    local whole_fmt
    whole_fmt=$(_fmt_num "$whole")
    if (( frac == 0 )); then
      printf '%sh' "$whole_fmt"
    elif (( frac % 10 == 0 )); then
      printf '%s.%dh' "$whole_fmt" "$(( frac / 10 ))"
    else
      printf '%s.%02dh' "$whole_fmt" "$frac"
    fi
  elif (( total_mins > 0 )); then
    printf '%dm' "$total_mins"
  else
    printf '%ds' "$total_secs"
  fi
}

# ── MCP servers segment ─────────────────────────────────────────
mcp_segment=""
if (( mcp_enabled > 0 )); then
  mcp_icon=$(printf '\xf3\xb1\x81\xa4')  # U+F1064
  mcp_segment="\033[38;2;120;135;155m${mcp_icon} ${mcp_enabled} MCP${RESET}"
fi


# ── AWS SSO expiry segment ──────────────────────────────────────
sso_segment=""
sso_cache_dir="$HOME/.aws/sso/cache"
sso_icon=$(printf '\xef\x83\xaf')  # U+F0EF nf-fa-cloud

if [[ -d "$sso_cache_dir" ]]; then
  sso_expiry=""
  for sso_file in "$sso_cache_dir"/*.json; do
    [[ -f "$sso_file" ]] || continue
    has_url=$(jq -r '.startUrl // empty' "$sso_file" 2>/dev/null)
    if [[ -n "$has_url" ]]; then
      sso_expiry=$(jq -r '.expiresAt // empty' "$sso_file" 2>/dev/null)
      break
    fi
  done

  if [[ -n "$sso_expiry" ]]; then
    expiry_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$sso_expiry" "+%s" 2>/dev/null || date -d "$sso_expiry" "+%s" 2>/dev/null)
    now_epoch=$(date "+%s")

    if [[ -n "$expiry_epoch" ]]; then
      remaining=$(( expiry_epoch - now_epoch ))

      if (( remaining <= 0 )); then
        sso_segment="${RED}${sso_icon}  Bedrock (expired)${RESET}"
      elif (( remaining < 900 )); then
        sso_segment="${RED}${sso_icon}  Bedrock${RESET}"
      elif (( remaining < 3600 )); then
        sso_segment="${ALERT}${sso_icon}  Bedrock${RESET}"
      else
        sso_segment="${MUSTARD}${sso_icon}  Bedrock${RESET}"
      fi
    fi
  fi
fi

# ── Context usage segment ───────────────────────────────────────
ctx_segment=""
ctx_total=200000  # default context window size

if [[ -n "$used_pct" && -n "$input_tokens" && -n "$ctx_size" ]]; then
  # We have full context_window data from Claude Code
  total_used=$((input_tokens + ${output_tokens:-0}))
  ctx_total="$ctx_size"
  pct="$used_pct"
else
  # Fall back: parse last usage entry from transcript JSONL
  transcript=$(echo "$input" | jq -r '.transcript_path // empty')
  if [[ -n "$transcript" && -f "$transcript" ]]; then
    last_usage=$(grep '"usage"' "$transcript" 2>/dev/null | tail -1 | jq -r '.message.usage // empty' 2>/dev/null)
    if [[ -n "$last_usage" && "$last_usage" != "null" ]]; then
      u_input=$(echo "$last_usage" | jq -r '.input_tokens // 0')
      u_cache_create=$(echo "$last_usage" | jq -r '.cache_creation_input_tokens // 0')
      u_cache_read=$(echo "$last_usage" | jq -r '.cache_read_input_tokens // 0')
      u_output=$(echo "$last_usage" | jq -r '.output_tokens // 0')
      total_used=$(( u_input + u_cache_create + u_cache_read + u_output ))
      pct=$(( total_used * 100 / ctx_total ))
      (( pct > 100 )) && pct=99
    fi
  fi
fi

# Default to 0 usage so we always show the context gauge (even on startup)
if [[ -z "$total_used" ]] || ! (( total_used > 0 )) 2>/dev/null; then
  total_used=0
  pct=0
fi

if (( total_used >= 1000 )); then
  used_fmt="$(( total_used / 1000 ))k"
else
  used_fmt="$total_used"
fi
if (( ctx_total >= 1000 )); then
  size_fmt="$(( ctx_total / 1000 ))k"
else
  size_fmt="$ctx_total"
fi

if (( pct >= 70 )); then
  ctx_color="$RED"
elif (( pct >= 40 )); then
  ctx_color="$ALERT"
else
  ctx_color="$GREEN"
fi

# Context label for embedding in progress bar
ctx_label="${used_fmt}/${size_fmt} (${pct}%)"

# ── Logo segment ──────────────────────────────────────────────────
logo_icon=$(printf '\xf3\xb1\x80\x86')  # U+F1006
logo_segment="${GUSTO_CORAL}${logo_icon} gusto${RESET}"

# ── Helper: visible width of an ANSI string ──────────────────────
_vis_len() {
  # Strip ANSI escapes, then count characters (wc -m handles multibyte)
  local stripped
  stripped=$(printf '%b' "$1" | sed $'s/\033\\[[0-9;]*m//g')
  printf '%s' "$stripped" | wc -m | tr -d ' '
}

# ── Helper: join parts with separator ────────────────────────────
_join_parts() {
  local result="\033[0m"
  local i=0
  for part in "$@"; do
    (( i > 0 )) && result+="${SEP}"
    result+="$part"
    (( i++ ))
  done
  printf '%s' "$result"
}

# ── Helper: build justified row (left parts | padding | right parts)
# Usage: _justified_row max_width left_parts_str sep right_parts_str
_justified_row() {
  local max_w=$1
  shift
  local left_str="$1"
  local right_str="$2"
  local left_len=$(_vis_len "$left_str")
  local right_len=$(_vis_len "$right_str")
  local pad_len=$(( max_w - left_len - right_len ))
  (( pad_len < 1 )) && pad_len=1
  local pad=""
  for (( p=0; p<pad_len; p++ )); do pad+=" "; done
  printf '%b%s%b%b' "$left_str" "$pad" "$right_str" "${RESET}"
}

# ── Total row width = bar max + 2 caps, capped at terminal ───────
MAX_BAR=80
ROW_WIDTH=$(( MAX_BAR + 2 ))
term_width=$(tput cols 2>/dev/null || echo 80)
(( ROW_WIDTH > term_width )) && ROW_WIDTH=$term_width

# ── Row 1: proactive budget-based truncation ──────────────────────
# Right side (dirty segment) is never truncated — measure it first
row1_right="\033[0m"
[[ -n "$dirty_segment" ]] && row1_right+="$dirty_segment"
right_width=$(_vis_len "$row1_right")

# Left side budget = total width minus right side minus 3 char min padding
left_budget=$(( ROW_WIDTH - right_width - 3 ))
(( left_budget < 20 )) && left_budget=20

# Chrome overhead on the left side (icons + spaces, not counting text):
#   folder: "󰉋 " (2)  branch: " 󰘬 " (3)  bullet: " · " (3)  model: "icon " (2)
# With branch:  2 + folder_name + 3 + branch + 3 + 2 + model_text = 10 + text
# Without branch: 2 + folder_name + 3 + 2 + model_text = 7 + text
model_icon=$(printf '\xef\x94\x9b')  # U+F51B

# Build model text (may include style)
model_text="$model"
if [[ -n "$output_style" && "$output_style" != "default" ]]; then
  model_text+=" (${output_style})"
fi

# Calculate chrome: folder_icon(2) + [bullet(3) + branch_icon(2) if branch] + bullet(3) + model_icon(2)
chrome=7  # folder_icon(2) + bullet(3) + model_icon(2)
[[ -n "$branch" ]] && chrome=12  # add bullet(3) + branch_icon(2)

# Available text budget after chrome
text_budget=$(( left_budget - chrome ))
(( text_budget < 10 )) && text_budget=10

# Allocate: path/branch get priority, model gets the remainder
model_text_len=${#model_text}
path_len=${#folder_name}
branch_len=${#branch}
path_branch_len=$(( path_len + branch_len ))

# Model needs at least 10 chars so "icon + name" stays readable (e.g. " Opus 4.6")
min_model=10
model_budget=$(( text_budget - path_branch_len ))
(( model_budget < min_model )) && model_budget=$min_model

# Path+branch budget is what remains after model
pb_budget=$(( text_budget - model_budget ))
# But if model fits fully, give all remaining back to path+branch
if (( model_text_len <= model_budget )); then
  model_budget=$model_text_len
  pb_budget=$(( text_budget - model_budget ))
fi

# Truncate path and branch to fit pb_budget
if (( path_branch_len > pb_budget )); then
  if [[ -n "$branch" ]]; then
    # Split budget 50/50, but if one side fits, give surplus to the other
    half=$(( pb_budget / 2 ))
    if (( path_len <= half )); then
      # Path fits in its half — branch gets the rest
      max_path=$path_len
      max_branch=$(( pb_budget - max_path ))
    elif (( branch_len <= half )); then
      # Branch fits in its half — path gets the rest
      max_branch=$branch_len
      max_path=$(( pb_budget - max_branch ))
    else
      # Both contest — split evenly
      max_path=$half
      max_branch=$(( pb_budget - max_path ))
    fi
    (( max_path < 4 )) && max_path=4
    (( max_branch < 4 )) && max_branch=4
    if (( branch_len > max_branch )); then
      branch="${branch:0:$((max_branch - 1))}${ELLIPSIS}"
    fi
    if (( ${#folder_name} > max_path )); then
      folder_name="${folder_name:0:$((max_path - 1))}${ELLIPSIS}"
    fi
  else
    if (( path_len > pb_budget )); then
      folder_name="${folder_name:0:$((pb_budget - 1))}${ELLIPSIS}"
    fi
  fi
fi

# Truncate model text if needed (drop style first, then truncate name)
if (( model_text_len > model_budget )); then
  # Step 1: drop the style parens
  model_text="$model"
  model_text_len=${#model_text}
  # Step 2: truncate model name if still too long
  if (( model_text_len > model_budget )); then
    model_text="${model_text:0:$((model_budget - 1))}${ELLIPSIS}"
  fi
fi

# Assemble folder segment
if [[ -n "$folder_name" ]]; then
  if [[ -n "$branch" ]]; then
    folder_segment="${BLUE}󰉋 ${folder_name}${BULLET}${MAGENTA}󰘬 ${branch}${RESET}"
  else
    folder_segment="${BLUE}󰉋 ${folder_name}${RESET}"
  fi
fi

# Assemble model segment
model_segment=""
if [[ -n "$model_text" ]]; then
  model_segment="${CYAN}${model_icon} ${model_text}${RESET}"
fi

# Build row 1 left
row1_left="\033[0m"
[[ -n "$folder_segment" ]] && row1_left+="$folder_segment"
if [[ -n "$model_segment" ]]; then
  [[ -n "$folder_segment" ]] && row1_left+="${BULLET}"
  row1_left+="$model_segment"
fi

_justified_row "$ROW_WIDTH" "$row1_left" "$row1_right"

# ── Build time + cost segments for row 3 ─────────────────────────
time_segment=""
cost_icon=$(printf '\xef\x85\x95')       # U+F155 dollar
time_icon=$(printf '\xee\xbc\xac')       # U+EF2C cloud+lightning

TIME_COLOR="\033[38;2;120;135;155m"  # muted slate-blue
if [[ -n "$total_api_ms" && "$total_api_ms" -gt 999 ]] 2>/dev/null; then
  api_fmt=$(_fmt_duration "$total_api_ms")
  time_segment="${TIME_COLOR}${time_icon} ${api_fmt}${RESET}"
fi

COST_COLOR="${DARK_GREEN}"
formatted_cost=$(printf '%.2f' "${cost:-0}")
cost_segment=""
if [[ "$formatted_cost" != "0.00" ]]; then
  cost_segment="${COST_COLOR}${cost_icon}${formatted_cost}${RESET}"
fi

# ── Row 3 (built here, printed last): left: gusto · bedrock · mcp | right: time · cost
row3_left="\033[0m"
[[ -n "$logo_segment" ]] && row3_left+="$logo_segment"
if [[ -n "$sso_segment" ]]; then
  [[ -n "$logo_segment" ]] && row3_left+="${BULLET}"
  row3_left+="$sso_segment"
fi
if [[ -n "$mcp_segment" ]]; then
  row3_left+="${BULLET}${mcp_segment}"
fi

row3_right="\033[0m"
if [[ -n "$time_segment" ]]; then
  row3_right+="${time_segment}"
  [[ -n "$cost_segment" ]] && row3_right+="${BULLET}"
fi
[[ -n "$cost_segment" ]] && row3_right+="$cost_segment"

# ── Row 2: progress bar with Powerline caps ─────────────────────
bar_width=$(tput cols 2>/dev/null || echo 80)

# Bar fill colors (background) — solid color based on percentage
GREEN_BG="\033[48;2;80;110;72m"
ALERT_BG="\033[48;2;220;175;100m"
RED_BG="\033[48;2;224;108;117m"
EMPTY_BG="\033[48;2;35;38;45m"
BRIGHT_FG="\033[38;2;200;205;215m"  # bright text on dark filled bg
DARK_FG="\033[38;2;40;35;30m"      # dark text on bright filled bg (alert)
LIGHT_FG="\033[38;2;85;90;100m"    # dim text on empty bg

# Matching foreground colors for Powerline caps
GREEN_FG="\033[38;2;80;110;72m"
ALERT_BAR_FG="\033[38;2;220;175;100m"
RED_FG="\033[38;2;224;108;117m"
EMPTY_FG="\033[38;2;35;38;45m"

# Pick solid fill color based on percentage thresholds
if (( pct >= 70 )); then
  FILL_BG="$RED_BG"; FILL_FG="$RED_FG"; FILL_TEXT="$BRIGHT_FG"
elif (( pct >= 40 )); then
  FILL_BG="$ALERT_BG"; FILL_FG="$ALERT_BAR_FG"; FILL_TEXT="$DARK_FG"
else
  FILL_BG="$GREEN_BG"; FILL_FG="$GREEN_FG"; FILL_TEXT="$BRIGHT_FG"
fi

# Powerline semicircle glyphs
PL_RIGHT=$(printf '\xee\x82\xb4')  # U+E0B4 right semicircle (closing cap)
PL_LEFT=$(printf '\xee\x82\xb6')   # U+E0B6 left semicircle (opening cap)

# Bar area: fixed width, max 80
bar_area=$(( bar_width - 2 ))
(( bar_area > MAX_BAR )) && bar_area=$MAX_BAR
(( bar_area < 20 )) && bar_area=20

# When partially filled, one cell is consumed by the inner transition cap
has_inner_cap=0
if (( pct > 0 && pct < 100 )); then
  has_inner_cap=1
fi
body_area=$(( bar_area - has_inner_cap ))

filled=$(( body_area * pct / 100 ))
(( filled > body_area )) && filled=$body_area

# Padded label centered in the full bar_area (visual width)
ctx_label_padded="  ${ctx_label}  "
label_len=${#ctx_label_padded}
label_start=$(( (bar_area - label_len) / 2 ))
(( label_start < 0 )) && label_start=0
label_end=$(( label_start + label_len ))

# Outer cap colors
if (( filled > 0 || (pct > 0 && has_inner_cap == 0) )); then
  left_cap_fg="$FILL_FG"
else
  left_cap_fg="$EMPTY_FG"
fi

if (( pct >= 100 )); then
  right_cap_fg="$FILL_FG"
else
  right_cap_fg="$EMPTY_FG"
fi

# Build bar body with solid fill color
bar=""
vis=0  # visual position (0..bar_area-1)
body_i=0  # body cell index (0..body_area-1)
while (( vis < bar_area )); do
  # Insert inner transition cap at the fill boundary
  if (( has_inner_cap && body_i == filled )); then
    if (( vis >= label_start && vis < label_end )); then
      char_idx=$(( vis - label_start ))
      c="${ctx_label_padded:$char_idx:1}"
      bar+="${EMPTY_BG}${LIGHT_FG}${c}"
    else
      bar+="${EMPTY_BG}${FILL_FG}${PL_RIGHT}"
    fi
    has_inner_cap=0
    (( vis++ ))
    continue
  fi

  if (( vis >= label_start && vis < label_end )); then
    char_idx=$(( vis - label_start ))
    c="${ctx_label_padded:$char_idx:1}"
    if (( body_i < filled )); then
      bar+="${FILL_BG}${FILL_TEXT}${c}"
    else
      bar+="${EMPTY_BG}${LIGHT_FG}${c}"
    fi
  else
    if (( body_i < filled )); then
      bar+="${FILL_BG} "
    else
      bar+="${EMPTY_BG} "
    fi
  fi
  (( body_i++ ))
  (( vis++ ))
done

# Assemble row 2: progress bar + optional warning
printf '\n%b%b%b%b%b' \
  "${RESET}${left_cap_fg}${PL_LEFT}" \
  "${bar}" \
  "${RESET}${right_cap_fg}${PL_RIGHT}" \
  "${suffix_colored}" \
  "${RESET}"

# Row 3: gusto + SSO | time + cost (justified)
printf '\n'
_justified_row "$ROW_WIDTH" "$row3_left" "$row3_right"
