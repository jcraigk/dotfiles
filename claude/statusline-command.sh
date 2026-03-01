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
output_style=$(echo "$input" | jq -r '.output_style.name // empty')

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

# ── Colors ────────────────────────────────────────────────────────
BLUE="\033[38;2;95;179;255m"
MAGENTA="\033[38;2;198;120;221m"
CYAN="\033[38;2;86;182;194m"
GREEN="\033[38;2;152;195;121m"
YELLOW="\033[38;2;229;192;123m"
RED="\033[38;2;224;108;117m"
DARK_GREEN="\033[38;2;90;130;78m"
DIM="\033[38;2;92;99;112m"
SLATE="\033[38;2;126;156;160m"
STEEL="\033[38;2;110;140;160m"
MAUVE="\033[38;2;145;130;155m"
TAUPE="\033[38;2;148;140;125m"
ORANGE="\033[38;2;209;154;102m"
GUSTO_CORAL="\033[1;38;2;245;93;72m"
RESET="\033[0m"

SEP="${DIM} │ ${RESET}"

# ── Detect effective git repo (current dir or one level deep) ────
git_dir=""
if [[ -n "$cwd" ]]; then
  cd "$cwd" 2>/dev/null
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_dir="$cwd"
  else
    # Look one level deep for a git repo (wrapper folder pattern)
    for sub in "$cwd"/*/; do
      if [[ -d "$sub/.git" ]]; then
        git_dir="${sub%/}"
        break
      fi
    done
  fi
fi

# ── Folder + branch segment ──────────────────────────────────────
folder_segment=""
if [[ -n "$cwd" ]]; then
  if [[ -n "$git_dir" ]]; then
    cd "$git_dir" 2>/dev/null
    root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ "$git_dir" == "$cwd" ]]; then
      # We're directly in the repo
      rel="${cwd#$root}"
      if [[ -z "$rel" ]]; then
        folder_name=$(basename "$root")
      else
        folder_name="$(basename "$root")$rel"
      fi
    else
      # Wrapper folder — show the repo name from one level deep
      folder_name=$(basename "$git_dir")
    fi
    branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
      if (( ${#branch} > 24 )); then
        branch="${branch:0:22}…"
      fi
      folder_segment="${BLUE}󰉋 ${folder_name} ${MAGENTA}󰘬 ${branch}${RESET}"
    else
      folder_segment="${BLUE}󰉋 ${folder_name}${RESET}"
    fi
  elif [[ "$cwd" == "$HOME" ]]; then
    folder_segment="${BLUE}󰉋 ~${RESET}"
  elif [[ "$cwd" == "$HOME"/* ]]; then
    folder_segment="${BLUE}󰉋 ~${cwd#$HOME}${RESET}"
  else
    folder_segment="${BLUE}󰉋 ${cwd}${RESET}"
  fi
fi

# ── Model segment (with version) ────────────────────────────────
model_segment=""
if [[ -n "$model" ]]; then
  model_icon=$(printf '\xee\xba\x9c')  # U+EE9C brain
  model_segment="${CYAN}${model_icon} ${model}${RESET}"
fi

# ── Mode segment (output style) ───────────────────────────────────
mode_segment=""
mode_icon=$(printf '\xf3\xb0\xad\xb9')  # U+F0B79
if [[ -z "$output_style" || "$output_style" == "default" ]]; then
  mode_segment="${TAUPE}${mode_icon} Default${RESET}"
else
  mode_segment="${TAUPE}${mode_icon} ${output_style}${RESET}"
fi

# ── Cost segment ────────────────────────────────────────────────
cost_segment=""
if [[ -n "$cost" ]]; then
  cost_icon=$(printf '\xef\x85\x95')  # U+F155 dollar
  formatted_cost=$(printf '%.2f' "$cost")
  cost_segment="${DARK_GREEN}${cost_icon}${formatted_cost}${RESET}"
fi

# ── MCP servers segment ─────────────────────────────────────────
mcp_segment=""
if (( mcp_enabled > 0 )); then
  mcp_icon=$(printf '\xf3\xb1\x81\xa4')  # U+F1064
  mcp_segment="${MAUVE}${mcp_icon} ${mcp_enabled} MCP${RESET}"
fi

# ── Uncommitted files segment ────────────────────────────────────
dirty_segment=""
if [[ -n "$git_dir" ]]; then
  cd "$git_dir" 2>/dev/null
  dirty_count=$(git -c core.useBuiltinFSMonitor=false status --porcelain --ignore-submodules=dirty 2>/dev/null | wc -l | tr -d ' ')
  if (( dirty_count > 0 )); then
    dirty_icon=$(printf '\xf3\xb1\x87\xa7')  # U+F11E7
    dirty_segment="${ORANGE}${dirty_icon} ${dirty_count} unsaved${RESET}"
  fi
fi

# ── AWS SSO expiry segment ──────────────────────────────────────
sso_segment=""
sso_cache_dir="$HOME/.aws/sso/cache"
if [[ -d "$sso_cache_dir" ]]; then
  # Find the SSO token with a startUrl (the real session, not role creds)
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
    sso_icon=$(printf '\xf3\xb0\xa5\x94')  # U+F0954
    # Parse expiry and compute remaining time
    expiry_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$sso_expiry" "+%s" 2>/dev/null || date -d "$sso_expiry" "+%s" 2>/dev/null)
    now_epoch=$(date "+%s")

    if [[ -n "$expiry_epoch" ]]; then
      remaining=$(( expiry_epoch - now_epoch ))

      if (( remaining <= 0 )); then
        sso_segment="${RED}${sso_icon} SSO expired${RESET}"
      elif (( remaining < 900 )); then
        # Less than 15 minutes — red warning
        mins=$(( remaining / 60 ))
        sso_segment="${RED}${sso_icon} SSO ${mins}m${RESET}"
      elif (( remaining < 3600 )); then
        # Less than 1 hour — yellow
        mins=$(( remaining / 60 ))
        sso_segment="${YELLOW}${sso_icon} SSO ${mins}m${RESET}"
      else
        # 1+ hours remaining — show only hours
        hours=$(( remaining / 3600 ))
        sso_segment="${STEEL}${sso_icon} SSO ${hours}h${RESET}"
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

if [[ -n "$total_used" && "$total_used" -gt 0 ]] 2>/dev/null; then
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

  if (( pct >= 80 )); then
    ctx_color="$RED"
  elif (( pct >= 50 )); then
    ctx_color="$YELLOW"
  else
    ctx_color="$GREEN"
  fi

  # nf-md-circle_slice_1 through _8 (U+F0A9E–U+F0AA5)
  # All share bytes \xf3\xb0\xaa, last byte increments from \x9e
  if (( pct >= 88 )); then
    ctx_icon=$(printf '\xf3\xb0\xaa\xa5')   # slice_8
  elif (( pct >= 75 )); then
    ctx_icon=$(printf '\xf3\xb0\xaa\xa4')   # slice_7
  elif (( pct >= 63 )); then
    ctx_icon=$(printf '\xf3\xb0\xaa\xa3')   # slice_6
  elif (( pct >= 50 )); then
    ctx_icon=$(printf '\xf3\xb0\xaa\xa2')   # slice_5
  elif (( pct >= 38 )); then
    ctx_icon=$(printf '\xf3\xb0\xaa\xa1')   # slice_4
  elif (( pct >= 25 )); then
    ctx_icon=$(printf '\xf3\xb0\xaa\xa0')   # slice_3
  elif (( pct >= 13 )); then
    ctx_icon=$(printf '\xf3\xb0\xaa\x9f')   # slice_2
  else
    ctx_icon=$(printf '\xf3\xb0\xaa\x9e')   # slice_1
  fi

  ctx_segment="${ctx_color}${ctx_icon} ${used_fmt}/${size_fmt} (${pct}%)${RESET}"
fi

# ── Logo segment ──────────────────────────────────────────────────
logo_icon=$(printf '\xf3\xb1\x80\x86')  # U+F1006
logo_segment="${GUSTO_CORAL}${logo_icon} gusto${RESET}"

# ── Combine segments ─────────────────────────────────────────────
parts=()
parts+=("$logo_segment")
[[ -n "$folder_segment" ]] && parts+=("$folder_segment")
[[ -n "$model_segment" ]] && parts+=("$model_segment")
[[ -n "$ctx_segment" ]] && parts+=("$ctx_segment")
[[ -n "$cost_segment" ]] && parts+=("$cost_segment")
[[ -n "$mcp_segment" ]] && parts+=("$mcp_segment")
[[ -n "$sso_segment" ]] && parts+=("$sso_segment")
[[ -n "$mode_segment" ]] && parts+=("$mode_segment")
[[ -n "$dirty_segment" ]] && parts+=("$dirty_segment")

# Join with separator (leading reset so first segment color isn't swallowed)
result="\033[0m"
for i in "${!parts[@]}"; do
  if (( i > 0 )); then
    result+="${SEP}"
  fi
  result+="${parts[$i]}"
done

printf '%b' "$result"
