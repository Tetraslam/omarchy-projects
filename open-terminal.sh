#!/bin/bash
# open-terminal.sh MODE DIR
#
# Opens DIR in a new tab of your most recently used Ghostty window (mode
# agent: runs opencode, editor: runs $EDITOR, shell: just cd), or in a new
# terminal window when no Ghostty window is open. Ghostty on Linux has no
# command for opening a tab in an existing window, so the tab is opened with
# its own shortcut (Ctrl+Shift+T) and the command is typed into it; that also
# puts it in your shell history, where zoxide learns from it.

set -euo pipefail

mode=$1
dir=$2

case "$mode" in
  agent) run="opencode" ;;
  editor) run="\${EDITOR:-hx} ." ;;
  *) run="" ;;
esac

window=$(hyprctl clients -j | jq -r '[.[] | select(.class == "com.mitchellh.ghostty")] | sort_by(.focusHistoryID) | .[0].address // empty')

if [[ -z $window ]]; then
  if [[ -n $run ]]; then
    exec uwsm-app -- xdg-terminal-exec --dir="$dir" bash -c "$run; exec bash"
  fi
  exec uwsm-app -- xdg-terminal-exec --dir="$dir"
fi

hyprctl dispatch "hl.dsp.focus({ window = \"address:$window\" })" >/dev/null
sleep 0.08
wtype -M ctrl -M shift t -m shift -m ctrl
# Let Ghostty create the tab before typing into it; the shell itself may
# still be starting, but its terminal buffers what's typed until it reads.
sleep 0.3
line="cd $(printf '%q' "$dir")"
[[ -n $run ]] && line+=" && $run"
wtype -- "$line"
wtype -k Return
