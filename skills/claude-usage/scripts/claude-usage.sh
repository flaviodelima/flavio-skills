#!/usr/bin/env bash
# Print Claude Code plan usage (/usage) by driving a throwaway claude in tmux.
# Usage: claude-usage.sh [dir]   (dir must be a trusted folder; default: current dir)
set -euo pipefail

dir=${1:-$PWD}
name="cc-usage-$$"

for dep in tmux claude; do
  command -v "$dep" >/dev/null || { echo "error: $dep not found in PATH" >&2; exit 1; }
done

trap 'tmux kill-session -t "=$name" 2>/dev/null || true' EXIT
tmux new-session -d -s "$name" -x 120 -y 60 -c "$dir" claude

pane() { tmux capture-pane -pt "=$name:" -J; }

# /usage is a TUI screen, not an API. The patterns below were checked against
# Claude Code 2.1.309; if they stop matching, fail loudly instead of guessing.
ready=""
for _ in $(seq 1 30); do
  sleep 1
  s=$(pane)
  if grep -q 'trust this folder' <<<"$s"; then
    echo "error: $dir is not trusted; pass a trusted dir" >&2; exit 3
  fi
  if grep -q '^❯' <<<"$s"; then ready=1; break; fi
done
[ -n "$ready" ] || { echo "error: claude did not start" >&2; pane >&2; exit 4; }

tmux send-keys -t "=$name:" "/usage"
sleep 1
tmux send-keys -t "=$name:" Enter

prev="" found=""
for _ in $(seq 1 20); do
  sleep 1
  s=$(pane)
  if grep -qE '[0-9]+% ?used' <<<"$s"; then
    found=1
    [ "$s" = "$prev" ] && break
  fi
  prev=$s
done

# Skip the header and the throwaway session's own (empty) stats.
out=$(pane | sed -e 's/[[:space:]]*$//' | sed -n '/^ *Current session/,/^ *Esc to cancel/p' | sed '$d' | cat -s)
if [ -z "$found" ] || [ -z "$out" ]; then
  echo "error: /usage output not recognized (Claude Code version changed?). Screen:" >&2
  pane >&2
  exit 5
fi
echo "$out"
