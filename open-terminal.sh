#!/bin/bash
# open-terminal.sh MODE TARGET
#
# Opens TARGET in a new tab of your most recently used Ghostty window, or in a
# new terminal window when no Ghostty window is open. TARGET is a directory
# (mode agent: runs opencode, editor: runs $EDITOR, shell: just cd) or, for
# mode ssh, a host. Ghostty on Linux has no
# command for opening a tab in an existing window, so the tab is opened with
# its own shortcut (Ctrl+Shift+T), and the command waits in a private file for
# the new tab's shell to run (shell-hook.bash). It lands in your history, and
# the cd teaches zoxide.

set -euo pipefail

mode=$1
dir=$2

case "$mode" in
  ssh) run="ssh $(printf '%q' "$dir")" ;;
  agent) run="opencode" ;;
  editor) run="\${EDITOR:-hx} ." ;;
  *) run="" ;;
esac

window=$(hyprctl clients -j | jq -r '[.[] | select(.class == "com.mitchellh.ghostty")] | sort_by(.focusHistoryID) | .[0].address // empty')

if [[ -z $window ]]; then
  if [[ $mode == ssh ]]; then
    exec uwsm-app -- xdg-terminal-exec bash -c "$run; exec bash"
  fi
  if [[ -n $run ]]; then
    exec uwsm-app -- xdg-terminal-exec --dir="$dir" bash -c "$run; exec bash"
  fi
  exec uwsm-app -- xdg-terminal-exec --dir="$dir"
fi

if [[ $mode == ssh ]]; then
  line=$run
else
  line="cd $(printf '%q' "$dir")"
  [[ -n $run ]] && line+=" && $run"
fi

# The new tab's shell runs this through shell-hook.bash.
pending="${XDG_RUNTIME_DIR:-/tmp}/omarchy-projects-pending"
printf '%s\n' "$line" > "$pending"

hyprctl dispatch "hl.dsp.focus({ window = \"address:$window\" })" >/dev/null
sleep 0.05
wtype -M ctrl -M shift t -m shift -m ctrl
