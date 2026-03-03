#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# ── Layout mode & width from state file ──────────────────────────
_SL_STATE_FILE="$HOME/.claude/statusline-state.json"
if [[ -f "$_SL_STATE_FILE" ]]; then
  _SL_STATE=$(cat "$_SL_STATE_FILE")
  _SL_MODE=$(echo "$_SL_STATE" | grep -o '"mode"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"/\1/')
  _SL_WIDTH=$(echo "$_SL_STATE" | grep -o '"width"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"/\1/')
  _SL_DEBUG=$(echo "$_SL_STATE" | grep -o '"debug"[[:space:]]*:[[:space:]]*[a-z]*' | head -1 | sed 's/.*:[[:space:]]*//')
  _SL_LOGOS=$(echo "$_SL_STATE" | grep -o '"logos"[[:space:]]*:[[:space:]]*[a-z]*' | head -1 | sed 's/.*:[[:space:]]*//')
  _SL_STYLE=$(echo "$_SL_STATE" | grep -o '"style"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"/\1/')
  _SL_FLAIR=$(echo "$_SL_STATE" | grep -o '"flair"[[:space:]]*:[[:space:]]*[a-z]*' | head -1 | sed 's/.*:[[:space:]]*//')
  _SL_COLOR_MODE=$(echo "$_SL_STATE" | grep -o '"color"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"/\1/')
fi
_SL_MODE="${_SL_MODE:-full}"
_SL_WIDTH="${_SL_WIDTH:-auto}"
_SL_DEBUG="${_SL_DEBUG:-false}"
_SL_LOGOS="${_SL_LOGOS:-true}"
_SL_STYLE="${_SL_STYLE:-concise}"
_SL_FLAIR="${_SL_FLAIR:-true}"
_SL_COLOR_MODE="${_SL_COLOR_MODE:-default}"
# Migrate: if mode was "debug" from old state, treat as full + debug on
if [[ "$_SL_MODE" == "debug" ]]; then
  _SL_MODE="full"
  _SL_DEBUG="true"
fi

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
session_id=$(echo "$input" | jq -r '.session_id // empty')
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
GUSTO_CORAL="\033[1;38;2;200;65;55m"
# AWS
MUSTARD="\033[38;2;170;150;90m"
# Utility
DIM="\033[38;2;85;90;100m"
RESET="\033[0m"

# ── Color mode overrides ────────────────────────────────────────
# Palette swaps based on _SL_COLOR_MODE. The default palette above
# is left untouched; mono/dim simply reassign the same variable names.
if [[ "$_SL_COLOR_MODE" == "mono" ]]; then
  # Monochrome: shades of gray only
  BLUE="\033[38;2;190;190;190m"
  MAGENTA="\033[38;2;170;170;170m"
  CYAN="\033[38;2;180;180;180m"
  MAUVE="\033[38;2;140;140;140m"
  DARK_GREEN="\033[38;2;150;150;150m"
  ALERT="\033[38;2;200;200;200m"
  RED="\033[38;2;210;210;210m"
  GREEN="\033[38;2;170;170;170m"
  GUSTO_CORAL="\033[1;38;2;200;200;200m"
  MUSTARD="\033[38;2;160;160;160m"
  DIM="\033[38;2;90;90;90m"
elif [[ "$_SL_COLOR_MODE" == "muted" ]]; then
  # Muted: same hues, ~40% saturation
  BLUE="\033[38;2;140;170;210m"
  MAGENTA="\033[38;2;170;145;185m"
  CYAN="\033[38;2;130;165;170m"
  MAUVE="\033[38;2;140;135;150m"
  DARK_GREEN="\033[38;2;125;145;115m"
  ALERT="\033[38;2;185;165;125m"
  RED="\033[38;2;185;140;140m"
  GREEN="\033[38;2;150;170;135m"
  GUSTO_CORAL="\033[1;38;2;170;105;100m"
  MUSTARD="\033[38;2;155;145;115m"
  DIM="\033[38;2;95;95;105m"
fi

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
  mcp_icon=$(printf '\xf3\xb1\x81\xa4')  # U+F1064 (surrogate pair \uDB84\uDC64)
  mcp_segment="${MAUVE}${mcp_icon} ${mcp_enabled} MCP${RESET}"
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
ctx_label="${used_fmt}/${size_fmt} ${pct}%"

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

# ── Total row width = bar max + 2 caps ────────────────────────────
# Limits: min 50, default 80, max 150 (enforced here regardless of state)
if [[ "$_SL_WIDTH" != "auto" && "$_SL_WIDTH" =~ ^[0-9]+$ ]]; then
  MAX_BAR=$_SL_WIDTH
  (( MAX_BAR < 50 )) && MAX_BAR=50
  (( MAX_BAR > 150 )) && MAX_BAR=150
else
  MAX_BAR=80
fi
ROW_WIDTH=$(( MAX_BAR + 2 ))

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
style_suffix=""  # colored suffix appended after model_text in the segment
if [[ -n "$output_style" && "$output_style" != "default" ]]; then
  if [[ "$_SL_STYLE" == "verbose" ]]; then
    model_text+=" (${output_style})"
  elif [[ "$_SL_STYLE" == "concise" ]]; then
    # Nerd Font icons for known style initials, fallback to uppercase letter
    _style_lower="$(tr '[:upper:]' '[:lower:]' <<< "${output_style:0:1}")"
    case "$_style_lower" in
      e) style_suffix=" $(printf '\xf3\xb0\xac\x8c')" ;;  # U+F0B0C for Explanatory
      l) style_suffix=" $(printf '\xf3\xb0\xac\x93')" ;;  # U+F0B13 for Learning
      *) style_suffix=" $(tr '[:lower:]' '[:upper:]' <<< "$_style_lower")" ;;
    esac
  fi
fi

# Calculate chrome: folder_icon(2) + [bullet(3) + branch_icon(2) if branch] + bullet(3) + model_icon(2)
chrome=7  # folder_icon(2) + bullet(3) + model_icon(2)
[[ -n "$branch" ]] && chrome=12  # add bullet(3) + branch_icon(2)

# Available text budget after chrome
text_budget=$(( left_budget - chrome ))
(( text_budget < 10 )) && text_budget=10

# Allocate: path/branch get priority, model gets the remainder
style_suffix_len=${#style_suffix}
model_text_len=$(( ${#model_text} + style_suffix_len ))
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

# Truncate model text if needed (drop style/suffix first, then truncate name)
if (( model_text_len > model_budget )); then
  # Step 1: drop the style parens or abbreviated suffix
  model_text="$model"
  style_suffix=""
  style_suffix_len=0
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
  model_segment="${CYAN}${model_icon} ${model_text}${style_suffix}${RESET}"
fi

# Build row 1 left
row1_left="\033[0m"
[[ -n "$folder_segment" ]] && row1_left+="$folder_segment"
if [[ -n "$model_segment" ]]; then
  [[ -n "$folder_segment" ]] && row1_left+="${BULLET}"
  row1_left+="$model_segment"
fi

# Row 1: folder/branch/model + dirty (full, compact & debug — not minimal)
if [[ "$_SL_MODE" != "minimal" ]]; then
  _justified_row "$ROW_WIDTH" "$row1_left" "$row1_right"
fi

# ── Build time + cost segments for row 3 ─────────────────────────
time_segment=""
cost_icon=$(printf '\xef\x85\x95')       # U+F155 dollar
time_icon=$(printf '\xf3\xb0\x80\x82')   # U+F0002

TIME_COLOR="$MAUVE"  # muted — inherits from palette
if [[ -n "$total_api_ms" && "$total_api_ms" -gt 999 ]] 2>/dev/null; then
  api_fmt=$(_fmt_duration "$total_api_ms")
  time_segment="${TIME_COLOR}${api_fmt}${RESET}"
fi

COST_COLOR="${DARK_GREEN}"
formatted_cost=$(printf '%.2f' "${cost:-0}")
cost_segment=""
if [[ "$formatted_cost" != "0.00" ]]; then
  cost_segment="${COST_COLOR}${cost_icon}${formatted_cost}${RESET}"
fi

# ── Row 3 (built here, printed last): left: gusto · bedrock · mcp | right: time · cost
row3_left="\033[0m"
row3_left_has_content=false
if [[ "$_SL_LOGOS" == "true" ]]; then
  [[ -n "$logo_segment" ]] && { row3_left+="$logo_segment"; row3_left_has_content=true; }
  if [[ -n "$sso_segment" ]]; then
    [[ "$row3_left_has_content" == "true" ]] && row3_left+="${BULLET}"
    row3_left+="$sso_segment"
    row3_left_has_content=true
  fi
fi
if [[ -n "$mcp_segment" ]]; then
  [[ "$row3_left_has_content" == "true" ]] && row3_left+="${BULLET}"
  row3_left+="${mcp_segment}"
fi

row3_right="\033[0m"
if [[ -n "$time_segment" ]]; then
  row3_right+="${time_segment}"
  [[ -n "$cost_segment" ]] && row3_right+="${BULLET}"
fi
[[ -n "$cost_segment" ]] && row3_right+="$cost_segment"

# ── Row 2: progress bar with Powerline caps ─────────────────────
bar_width=$ROW_WIDTH

# Bar fill colors — 10-tier gradient: green → amber → red
# Each tier: BG (fill background), FG (powerline cap foreground), TEXT (label text)
#   0–10%  soft green
#   11–20% green
#   21–30% deeper green
#   31–40% green-gold transition
#   41–50% warm gold
#   51–60% amber
#   61–70% deep amber
#   71–80% amber-red transition
#   81–90% soft red
#   91–100% red
TIER_BG=(
  "\033[48;2;65;100;62m"    # 0–10   soft green
  "\033[48;2;80;110;72m"    # 11–20  green
  "\033[48;2;95;115;68m"    # 21–30  deeper green
  "\033[48;2;130;130;65m"   # 31–40  green-gold
  "\033[48;2;170;150;70m"   # 41–50  warm gold
  "\033[48;2;195;160;75m"   # 51–60  amber
  "\033[48;2;210;155;80m"   # 61–70  deep amber
  "\033[48;2;215;135;90m"   # 71–80  amber-red
  "\033[48;2;220;115;100m"  # 81–90  soft red
  "\033[48;2;224;108;117m"  # 91–100 red
)
TIER_FG=(
  "\033[38;2;65;100;62m"
  "\033[38;2;80;110;72m"
  "\033[38;2;95;115;68m"
  "\033[38;2;130;130;65m"
  "\033[38;2;170;150;70m"
  "\033[38;2;195;160;75m"
  "\033[38;2;210;155;80m"
  "\033[38;2;215;135;90m"
  "\033[38;2;220;115;100m"
  "\033[38;2;224;108;117m"
)
# Label + lead icon: halfway between full contrast and wind subtlety
TIER_TEXT=(
  "\033[38;2;120;140;126m"  # 0–10
  "\033[38;2;128;145;131m"  # 11–20
  "\033[38;2;135;148;129m"  # 21–30
  "\033[38;2;153;155;128m"  # 31–40
  "\033[38;2;93;80;38m"     # 41–50
  "\033[38;2;105;85;40m"    # 51–60
  "\033[38;2;113;83;43m"    # 61–70
  "\033[38;2;113;74;55m"    # 71–80
  "\033[38;2;115;64;60m"    # 81–90
  "\033[38;2;117;61;69m"    # 91–100
)
# Wind icons: darker than fill BG (~40 units)
TIER_WIND=(
  "\033[38;2;30;62;27m"     # 0–10
  "\033[38;2;42;72;34m"     # 11–20
  "\033[38;2;57;77;30m"     # 21–30
  "\033[38;2;92;92;28m"     # 31–40
  "\033[38;2;132;112;32m"   # 41–50
  "\033[38;2;157;122;37m"   # 51–60
  "\033[38;2;172;117;42m"   # 61–70
  "\033[38;2;177;97;52m"    # 71–80
  "\033[38;2;182;77;62m"    # 81–90
  "\033[38;2;186;70;79m"    # 91–100
)
# Lead icon: darker than wind (~70 units below fill BG)
TIER_LEAD=(
  "\033[38;2;10;38;7m"      # 0–10
  "\033[38;2;18;48;10m"     # 11–20
  "\033[38;2;33;53;6m"      # 21–30
  "\033[38;2;68;68;4m"      # 31–40
  "\033[38;2;108;88;8m"     # 41–50
  "\033[38;2;133;98;13m"    # 51–60
  "\033[38;2;148;93;18m"    # 61–70
  "\033[38;2;153;73;28m"    # 71–80
  "\033[38;2;158;53;38m"    # 81–90
  "\033[38;2;162;46;55m"    # 91–100
)
EMPTY_BG="\033[48;2;35;38;45m"
EMPTY_FG="\033[38;2;35;38;45m"
LIGHT_FG="\033[38;2;85;90;100m"    # dim text on empty bg

# ── Color mode overrides for progress bar gradient ───────────────
if [[ "$_SL_COLOR_MODE" == "mono" ]]; then
  # Monochrome gradient: 10 gray tiers from dark to bright
  TIER_BG=(
    "\033[48;2;60;60;60m"     # 0–10
    "\033[48;2;72;72;72m"     # 11–20
    "\033[48;2;84;84;84m"     # 21–30
    "\033[48;2;96;96;96m"     # 31–40
    "\033[48;2;108;108;108m"  # 41–50
    "\033[48;2;120;120;120m"  # 51–60
    "\033[48;2;135;135;135m"  # 61–70
    "\033[48;2;150;150;150m"  # 71–80
    "\033[48;2;170;170;170m"  # 81–90
    "\033[48;2;190;190;190m"  # 91–100
  )
  TIER_FG=(
    "\033[38;2;60;60;60m"
    "\033[38;2;72;72;72m"
    "\033[38;2;84;84;84m"
    "\033[38;2;96;96;96m"
    "\033[38;2;108;108;108m"
    "\033[38;2;120;120;120m"
    "\033[38;2;135;135;135m"
    "\033[38;2;150;150;150m"
    "\033[38;2;170;170;170m"
    "\033[38;2;190;190;190m"
  )
  TIER_TEXT=(
    "\033[38;2;110;110;110m"
    "\033[38;2;118;118;118m"
    "\033[38;2;126;126;126m"
    "\033[38;2;134;134;134m"
    "\033[38;2;65;65;65m"
    "\033[38;2;72;72;72m"
    "\033[38;2;80;80;80m"
    "\033[38;2;88;88;88m"
    "\033[38;2;100;100;100m"
    "\033[38;2;110;110;110m"
  )
  TIER_WIND=(
    "\033[38;2;30;30;30m"
    "\033[38;2;38;38;38m"
    "\033[38;2;48;48;48m"
    "\033[38;2;58;58;58m"
    "\033[38;2;70;70;70m"
    "\033[38;2;82;82;82m"
    "\033[38;2;97;97;97m"
    "\033[38;2;112;112;112m"
    "\033[38;2;132;132;132m"
    "\033[38;2;152;152;152m"
  )
  TIER_LEAD=(
    "\033[38;2;18;18;18m"
    "\033[38;2;25;25;25m"
    "\033[38;2;35;35;35m"
    "\033[38;2;45;45;45m"
    "\033[38;2;57;57;57m"
    "\033[38;2;69;69;69m"
    "\033[38;2;84;84;84m"
    "\033[38;2;99;99;99m"
    "\033[38;2;119;119;119m"
    "\033[38;2;139;139;139m"
  )
  EMPTY_BG="\033[48;2;38;38;38m"
  EMPTY_FG="\033[38;2;38;38;38m"
  LIGHT_FG="\033[38;2;90;90;90m"
elif [[ "$_SL_COLOR_MODE" == "muted" ]]; then
  # Muted gradient: same hue progression, reduced saturation (~40%)
  TIER_BG=(
    "\033[48;2;70;85;68m"     # 0–10   muted green
    "\033[48;2;80;92;76m"     # 11–20
    "\033[48;2;90;96;75m"     # 21–30
    "\033[48;2;115;112;72m"   # 31–40
    "\033[48;2;145;132;80m"   # 41–50
    "\033[48;2;160;140;85m"   # 51–60
    "\033[48;2;170;138;88m"   # 61–70
    "\033[48;2;175;128;95m"   # 71–80
    "\033[48;2;180;120;105m"  # 81–90
    "\033[48;2;185;120;120m"  # 91–100
  )
  TIER_FG=(
    "\033[38;2;70;85;68m"
    "\033[38;2;80;92;76m"
    "\033[38;2;90;96;75m"
    "\033[38;2;115;112;72m"
    "\033[38;2;145;132;80m"
    "\033[38;2;160;140;85m"
    "\033[38;2;170;138;88m"
    "\033[38;2;175;128;95m"
    "\033[38;2;180;120;105m"
    "\033[38;2;185;120;120m"
  )
  TIER_TEXT=(
    "\033[38;2;120;130;122m"
    "\033[38;2;126;133;127m"
    "\033[38;2;130;135;125m"
    "\033[38;2;140;140;120m"
    "\033[38;2;90;82;45m"
    "\033[38;2;100;88;48m"
    "\033[38;2;108;86;50m"
    "\033[38;2;108;80;60m"
    "\033[38;2;110;72;65m"
    "\033[38;2;112;68;72m"
  )
  TIER_WIND=(
    "\033[38;2;38;52;36m"
    "\033[38;2;46;58;42m"
    "\033[38;2;55;62;38m"
    "\033[38;2;78;78;35m"
    "\033[38;2;110;98;42m"
    "\033[38;2;125;106;47m"
    "\033[38;2;135;104;50m"
    "\033[38;2;140;94;57m"
    "\033[38;2;145;86;67m"
    "\033[38;2;150;82;82m"
  )
  TIER_LEAD=(
    "\033[38;2;22;36;20m"
    "\033[38;2;28;42;24m"
    "\033[38;2;37;46;20m"
    "\033[38;2;60;60;17m"
    "\033[38;2;92;80;24m"
    "\033[38;2;107;88;29m"
    "\033[38;2;117;86;32m"
    "\033[38;2;122;76;39m"
    "\033[38;2;127;68;49m"
    "\033[38;2;132;64;64m"
  )
  EMPTY_BG="\033[48;2;38;40;45m"
  EMPTY_FG="\033[38;2;38;40;45m"
  LIGHT_FG="\033[38;2;88;92;102m"
fi

# Powerline semicircle glyphs
PL_RIGHT=$(printf '\xee\x82\xb4')  # U+E0B4 right semicircle (closing cap)
PL_LEFT=$(printf '\xee\x82\xb6')   # U+E0B6 left semicircle (opening cap)

# ── Random lead icon (selected once per session) ─────────────────
LEAD_ICONS=(
  $(printf '\xef\x83\x83')          # U+F0C3  flask
  $(printf '\xef\x87\xa2')          # U+F1E2  bomb
  $(printf '\xf3\xb0\xb4\x88')     # U+F0D08
  $(printf '\xee\xbe\x80')          # U+EF80
  $(printf '\xee\xbd\xb6')          # U+EF76
  $(printf '\xef\x80\x93')          # U+F013  gear
  $(printf '\xef\x8b\x9c')          # U+F2DC  snowflake
  $(printf '\xee\x8f\xa0')          # U+E3E0
  $(printf '\xef\x86\xbb')          # U+F1BB  tree
  $(printf '\xf3\xb0\xb9\xbb')     # U+F0E7B
  $(printf '\xef\x81\x83')          # U+F043  tint
  $(printf '\xee\xb9\x86')          # U+EE46
  $(printf '\xee\xb8\x95')          # U+EE15
  $(printf '\xf3\xb0\x9a\xa9')     # U+F06A9
  $(printf '\xf3\xb0\x8c\xaa')     # U+F032A
  $(printf '\xee\xbc\x9d')          # U+EF1D
  $(printf '\xef\x86\x88')          # U+F188  bug
  $(printf '\xef\x80\x84')          # U+F004  heart
  $(printf '\xf3\xb0\xa9\x83')     # U+F0A43
  $(printf '\xf3\xb0\x9e\x87')     # U+F0787
  $(printf '\xf3\xb0\xae\xad')     # U+F0BAD
  $(printf '\xf3\xb0\x8a\xa0')     # U+F02A0
  $(printf '\xf3\xb0\x87\x8a')     # U+F01CA
  $(printf '\xf3\xb0\x87\x8b')     # U+F01CB
  $(printf '\xf3\xb0\x87\x8c')     # U+F01CC
  $(printf '\xf3\xb0\x87\x8d')     # U+F01CD
  $(printf '\xf3\xb0\x87\x8e')     # U+F01CE
  $(printf '\xf3\xb0\x87\x8f')     # U+F01CF
  $(printf '\xee\xba\x98')          # U+EE98
  $(printf '\xf3\xb0\xad\xb9')     # U+F0B79
  $(printf '\xee\x8a\x9b')          # U+E29B
  $(printf '\xee\xbd\x99')          # U+EF59
  $(printf '\xf3\xb1\xa8\xa7')     # U+F1A27
  $(printf '\xee\xb5\xa1')          # U+ED61
  $(printf '\xef\x80\x85')          # U+F005
  $(printf '\xf3\xb0\xbb\x83')     # U+F0EC3
  $(printf '\xf3\xb0\x8b\xb8')     # U+F02F8
  $(printf '\xf3\xb0\x9f\x9e')     # U+F07DE
  $(printf '\xee\xbe\xa7')          # U+EFA7
  $(printf '\xf3\xb0\x87\xa5')     # U+F01E5
  $(printf '\xee\xb7\x9c')          # U+EDDC
  $(printf '\xee\xb9\x81')          # U+EE41
  $(printf '\xef\x83\xa7')          # U+F0E7  bolt
  $(printf '\xee\xbc\x90')          # U+EF10
  $(printf '\xef\x89\xa7')          # U+F267
  $(printf '\xef\x84\xb5')          # U+F135  rocket
  $(printf '\xee\x8a\x81')          # U+E281
  $(printf '\xf3\xb0\x99\xb4')     # U+F0674
  $(printf '\xee\xbc\xae')          # U+EF2E
  $(printf '\xf3\xb0\x92\xb7')     # U+F04B7
  $(printf '\xf3\xb0\x9f\xa2')     # U+F07E2
  $(printf '\xee\xba\x9c')          # U+EE9C
  $(printf '\xf3\xb0\xaf\xb8')     # U+F0BF8
)
# Use session_id hash as stable seed so icon stays consistent per session
if [[ -n "$session_id" ]]; then
  _icon_hash=$(cksum <<< "$session_id" | cut -d' ' -f1)
else
  _icon_hash=$PPID
fi
BAR_LEAD_ICON="${LEAD_ICONS[$((_icon_hash % ${#LEAD_ICONS[@]}))]}"

# ── _render_bar: render a progress bar given pct and label ──────
# Usage: _render_bar <pct> <label> [suffix_colored] [texture]
# Textures: "wind" (default), or named texture from BAR_TEXTURES
_render_bar() {
  local _pct=$1
  local _label="$2"
  local _suffix="${3:-}"
  local _texture="${4:-wind}"

  # Pick fill color from 10-tier gradient based on percentage
  local _tier_idx=$(( _pct / 10 ))
  (( _tier_idx > 9 )) && _tier_idx=9
  (( _tier_idx < 0 )) && _tier_idx=0
  local _FILL_BG="${TIER_BG[$_tier_idx]}"
  local _FILL_FG="${TIER_FG[$_tier_idx]}"
  local _FILL_TEXT="${TIER_TEXT[$_tier_idx]}"
  local _FILL_ICON_FG="$EMPTY_FG"  # lead icon: same dark grey as unfilled bar
  local _WIND_FG="${TIER_WIND[$_tier_idx]}"  # wind icons: darker than fill
  local _LEAD_FG="${TIER_LEAD[$_tier_idx]}"  # lead icon: slightly darker than wind

  # Bar area: fixed width, max 80
  local _bar_area=$(( bar_width - 2 ))
  (( _bar_area > MAX_BAR )) && _bar_area=$MAX_BAR
  (( _bar_area < 20 )) && _bar_area=20

  # When partially filled, one cell is consumed by the inner transition cap
  local _has_inner_cap=0
  if (( _pct > 0 && _pct < 100 )); then
    _has_inner_cap=1
  fi
  local _body_area=$(( _bar_area - _has_inner_cap ))

  local _filled=$(( _body_area * _pct / 100 ))
  (( _filled > _body_area )) && _filled=$_body_area

  # Padded label centered in the full bar_area (visual width)
  local _label_padded=" ${_label} "
  local _label_len=${#_label_padded}
  local _label_start=$(( (_bar_area - _label_len) / 2 ))
  (( _label_start < 0 )) && _label_start=0
  local _label_end=$(( _label_start + _label_len ))

  # Outer cap colors
  local _left_cap_fg _right_cap_fg
  if (( _filled > 0 || (_pct > 0 && _has_inner_cap == 0) )); then
    _left_cap_fg="$_FILL_FG"
  else
    _left_cap_fg="$EMPTY_FG"
  fi

  if (( _pct >= 100 )); then
    _right_cap_fg="$_FILL_FG"
  else
    _right_cap_fg="$EMPTY_FG"
  fi

  # Build bar body with solid fill color
  local _bar=""
  local _vis=0  # visual position (0..bar_area-1)
  local _body_i=0  # body cell index (0..body_area-1)
  local _fill_icon_a _fill_icon_b _fill_icon_c _fill_cycle=2
  local _lead_icon="$BAR_LEAD_ICON"
  # Select texture icons
  case "$_texture" in
    wind)
      _fill_icon_a=$(printf '\xee\xbc\x96')  # U+EF16
      _fill_icon_b=$(printf '\xee\x8d\x8b')  # U+E34B
      ;;
    thick_dots)
      _fill_icon_a=$(printf '\xef\x91\x84')  # U+F444
      _fill_icon_b=$(printf '\xc2\xb7')      # U+00B7 middle dot
      ;;
    sin_wave)
      _fill_icon_a=$(printf '\xf3\xb1\x91\xb9')  # U+F1479
      _fill_icon_b=$(printf '\xf3\xb1\x91\xb9')  # U+F1479
      ;;
    jagged_wave)
      _fill_icon_a=$(printf '\xee\xbe\x9d')  # U+EF9D
      _fill_icon_b=$(printf '\xee\xbe\x9d')  # U+EF9D
      ;;
    beads)
      _fill_icon_a=$(printf '\xef\x85\xb2')  # U+F172
      _fill_icon_b=$(printf '\xef\x92\x8b')  # U+F48B
      ;;
    arrows)
      _fill_icon_a=$(printf '\xee\xad\xb0')  # U+EB70
      _fill_icon_b=$(printf '\xef\x91\x8a')  # U+F44A
      ;;
    sparkle)
      _fill_icon_a=$(printf '\xf3\xb1\x8d\xbf')  # U+F137F
      _fill_icon_b=$(printf '\xc2\xb7')            # U+00B7 middle dot (bullet)
      ;;
    dot_chain)
      _fill_icon_a=$(printf '\xef\x85\x81')  # U+F141 ellipsis (nf-fa-ellipsis_h)
      _fill_icon_b=$(printf '\xef\x85\x81')  # U+F141 ellipsis (repeated)
      ;;
    donuts)
      _fill_icon_a=$(printf '\xee\x89\xb3')  # U+E273
      _fill_icon_b=$(printf '\xc2\xb7')      # U+00B7 middle dot (bullet)
      ;;
    soundwaves)
      _fill_icon_a=$(printf '\xf3\xb1\x91\xbd')  # U+F147D
      _fill_icon_b=$(printf '\xf3\xb1\x91\xbd')  # U+F147D (repeated)
      ;;
    pulse)
      _fill_icon_a=$(printf '\xee\x88\xb4')  # U+E234
      _fill_icon_b=$(printf '\xee\x88\xb4')  # U+E234 (repeated)
      ;;
    infinity_loop)
      _fill_icon_a=$(printf '\xef\x93\xa6')  # U+F4E6
      _fill_icon_b=$(printf '\xc2\xb7')    # U+00B7 middle dot (bullet)
      ;;
    *)
      _fill_icon_a=$(printf '\xee\xbc\x96')  # U+EF16 (fallback to wind)
      _fill_icon_b=$(printf '\xee\x8d\x8b')  # U+E34B
      ;;
  esac
  local _lead_done=0
  while (( _vis < _bar_area )); do
    # Insert inner transition cap at the fill boundary
    if (( _has_inner_cap && _body_i == _filled )); then
      if (( _vis >= _label_start && _vis < _label_end )); then
        local _ci=$(( _vis - _label_start ))
        local _ch="${_label_padded:$_ci:1}"
        _bar+="${EMPTY_BG}${LIGHT_FG}${_ch}"
      else
        _bar+="${EMPTY_BG}${_FILL_FG}${PL_RIGHT}"
      fi
      _has_inner_cap=0
      (( _vis++ ))
      continue
    fi

    if (( _vis >= _label_start && _vis < _label_end )); then
      local _ci=$(( _vis - _label_start ))
      local _ch="${_label_padded:$_ci:1}"
      if (( _body_i < _filled )); then
        _bar+="${_FILL_BG}${_FILL_TEXT}${_ch}"
      else
        _bar+="${EMPTY_BG}${LIGHT_FG}${_ch}"
      fi
    else
      if (( _body_i < _filled )); then
        if [[ "$_SL_FLAIR" != "true" ]]; then
          # Plain solid fill — no lead icon or texture
          _bar+="${_FILL_BG} "
        elif (( _lead_done == 0 )); then
          _bar+="${_FILL_BG}${_LEAD_FG}${_lead_icon}"
          _lead_done=1
        elif (( _lead_done == 1 )); then
          # One space after lead icon before texture starts
          _bar+="${_FILL_BG} "
          _lead_done=2
        else
          # At label boundary, use the small icon to avoid oversized glyphs next to whitespace
          local _at_label_edge=0
          (( _vis == _label_start - 1 || _vis == _label_end )) && _at_label_edge=1
          local _ci_mod=$(( _body_i % _fill_cycle ))
          if (( _at_label_edge )); then
            _bar+="${_FILL_BG}${_WIND_FG}${_fill_icon_b}"
          elif (( _ci_mod == 0 )); then
            _bar+="${_FILL_BG}${_WIND_FG}${_fill_icon_a}"
          elif (( _ci_mod == 1 )); then
            _bar+="${_FILL_BG}${_WIND_FG}${_fill_icon_b}"
          else
            _bar+="${_FILL_BG}${_WIND_FG}${_fill_icon_c}"
          fi
        fi
      else
        _bar+="${EMPTY_BG} "
      fi
    fi
    (( _body_i++ ))
    (( _vis++ ))
  done

  # Assemble and print the bar
  printf '\n%b%b%b%b%b' \
    "${RESET}${_left_cap_fg}${PL_LEFT}" \
    "${_bar}" \
    "${RESET}${_right_cap_fg}${PL_RIGHT}" \
    "${_suffix}" \
    "${RESET}"
}

# Select texture per session (stable like the icon)
BAR_TEXTURES=(wind thick_dots sin_wave jagged_wave beads arrows dot_chain soundwaves pulse sparkle infinity_loop)
BAR_TEXTURE="${BAR_TEXTURES[$((_icon_hash % ${#BAR_TEXTURES[@]}))]}"

# In compact/minimal mode, fold cost into the bar label (no row 3 to show it)
# Format: "used/size pct% $cost" — simple spaces, no separators
_bar_label="$ctx_label"
if [[ "$_SL_MODE" == "compact" || "$_SL_MODE" == "minimal" ]]; then
  if [[ -n "$formatted_cost" && "$formatted_cost" != "0.00" ]]; then
    _bar_label="${ctx_label} \$${formatted_cost}"
  fi
fi

# Render the real progress bar
_render_bar "$pct" "$_bar_label" "$suffix_colored" "$BAR_TEXTURE"

# Row 3: gusto + SSO | time + cost (full mode only)
if [[ "$_SL_MODE" == "full" ]]; then
  printf '\n'
  _justified_row "$ROW_WIDTH" "$row3_left" "$row3_right"
fi

# ── DEBUG: 10 dummy progress bars (0%–90%, random icon + texture each) ──
if [[ "$_SL_DEBUG" == "true" ]]; then
  _TEST_TEXTURES=(wind thick_dots sin_wave jagged_wave beads arrows dot_chain soundwaves pulse sparkle infinity_loop)
  # Realistic used/total token pairs for labels
  _TEST_USED=(0 18 41 63 82 105 124 148 167 189)
  _TEST_TOTAL=(200 200 200 200 200 200 200 200 200 200)
  # Fake costs for compact mode debug bars
  _TEST_COST=(0.00 0.12 0.38 0.71 1.04 1.55 2.03 2.89 3.47 4.22)
  for _ti in $(seq 0 9); do
    _test_pct=$(( _ti * 10 ))
    _test_used="${_TEST_USED[$_ti]}k"
    _test_size="${_TEST_TOTAL[$_ti]}k"
    _test_label="${_test_used}/${_test_size} ${_test_pct}%"
    # In compact/minimal mode, append cost to match the real bar format
    if [[ ("$_SL_MODE" == "compact" || "$_SL_MODE" == "minimal") && "${_TEST_COST[$_ti]}" != "0.00" ]]; then
      _test_label="${_test_label} \$${_TEST_COST[$_ti]}"
    fi
    # Deterministic but varied: mix loop index with session hash for pseudo-random
    _test_seed=$(( (_icon_hash + _ti * 7919) % 65521 ))
    # Pick a random lead icon for this bar
    _test_icon_idx=$(( _test_seed % ${#LEAD_ICONS[@]} ))
    BAR_LEAD_ICON="${LEAD_ICONS[$_test_icon_idx]}"
    # Pick a random texture for this bar
    _test_tex_idx=$(( (_test_seed / ${#LEAD_ICONS[@]}) % ${#_TEST_TEXTURES[@]} ))
    _test_texture="${_TEST_TEXTURES[$_test_tex_idx]}"
    _render_bar "$_test_pct" "$_test_label" "" "$_test_texture"
  done
  # Restore session lead icon after debug bars
  BAR_LEAD_ICON="${LEAD_ICONS[$((_icon_hash % ${#LEAD_ICONS[@]}))]}"
fi
