# Source from ~/.bashrc. A shell started by the project launcher picks up the
# command it left behind (cd into the project, then opencode, ssh, ...), runs
# it, and records it in history, so it reads exactly as if you had typed it.
__omarchy_projects_pending() {
  local file="${XDG_RUNTIME_DIR:-/tmp}/omarchy-projects-pending"
  [[ -f $file ]] || return 0
  local line age
  line=$(<"$file")
  age=$(( $(date +%s) - $(stat -c %Y "$file") ))
  rm -f "$file"
  # Only a request made a moment ago, never a stale one from an old launch.
  (( age <= 10 )) || return 0
  history -s "$line"
  eval "$line"
}
[[ $- == *i* ]] && __omarchy_projects_pending
