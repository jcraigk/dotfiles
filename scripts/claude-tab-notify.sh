#!/bin/bash
# Sends a bell to the terminal so Ghostty shows an attention indicator on the tab.
# Used as a Claude Code hook for Stop/Notification/PermissionRequest events.

# Skip subagent events — they send "SubagentStop" instead of "Stop".
if read -t 1 INPUT 2>/dev/null; then
  if echo "$INPUT" | grep -q '"SubagentStop"'; then
    exit 0
  fi
fi

# Hooks run without a controlling TTY, so /dev/tty won't work.
# Walk up the process tree to find the TTY of the parent Claude process.
pid=$$
while [ "$pid" -gt 1 ]; do
  tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
  if [ -n "$tty" ] && [ "$tty" != "??" ]; then
    printf '\a' > "/dev/$tty"
    exit 0
  fi
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
done
