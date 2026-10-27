#!/usr/bin/env bash
# Start a Claude Code session with Remote Control inside a detached tmux session.
# Usage: remote-agent.sh [--fork [session-id]] <dir|repo-name> [session-name]
#   <repo-name> is looked up under $CODE_DIR (default ~/code).
#   --fork: start as a copy of an existing conversation (claude --resume <id>
#           --fork-session). The id defaults to $CLAUDE_CODE_SESSION_ID, i.e. the
#           session running this script. The source session is left untouched.
set -euo pipefail

CODE_DIR=${CODE_DIR:-$HOME/code}
CLAUDE_DIR=${CLAUDE_CONFIG_DIR:-$HOME/.claude}

usage="usage: $(basename "$0") [--fork [session-id]] <dir|repo-name> [session-name]"
fork=""
if [ "${1:-}" = "--fork" ]; then
  shift
  if [[ "${1:-}" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
    fork=$1; shift
  else
    fork=${CLAUDE_CODE_SESSION_ID:-}
  fi
  [ -n "$fork" ] || { echo "error: --fork needs a session id (no \$CLAUDE_CODE_SESSION_ID)" >&2; exit 1; }
fi

if [ $# -lt 1 ]; then
  echo "$usage" >&2
  exit 1
fi

for dep in tmux claude; do
  command -v "$dep" >/dev/null || { echo "error: $dep not found in PATH" >&2; exit 1; }
done

target=$1
if [ -d "$target" ]; then
  dir=$(cd "$target" && pwd)
elif [ -d "$CODE_DIR/$target" ]; then
  dir="$CODE_DIR/$target"
else
  echo "error: directory not found: $target (nor $CODE_DIR/$target)" >&2
  exit 1
fi

# tmux treats '.' and ':' as target separators.
name=${2:-$(basename "$dir")}
name=${name//[.:]/-}

if tmux has-session -t "=$name" 2>/dev/null; then
  echo "error: tmux session '$name' already exists (tmux attach -t $name)" >&2
  exit 2
fi

cmd="claude --remote-control $(printf %q "$name")"
if [ -n "$fork" ]; then
  # Sessions are stored per project dir, named after the path with every
  # non-alphanumeric char turned into '-'. This mirrors Claude Code's internal
  # layout, so a fork must start in the source session's directory.
  proj="$CLAUDE_DIR/projects/$(sed 's/[^A-Za-z0-9]/-/g' <<<"$dir")"
  if [ ! -f "$proj/$fork.jsonl" ]; then
    echo "error: session $fork not found in $proj (fork from the source session's directory)" >&2
    exit 1
  fi
  cmd="$cmd --resume $fork --fork-session"
fi

tmux new-session -d -s "$name" -c "$dir" "$cmd"

# Screen texts below were checked against Claude Code 2.1.309; if a later version
# changes them, this times out (exit 5) instead of guessing.
for _ in $(seq 1 30); do
  sleep 1
  if ! tmux has-session -t "=$name" 2>/dev/null; then
    echo "error: session '$name' exited during startup" >&2
    exit 4
  fi
  screen=$(tmux capture-pane -pt "=$name:" -J)
  url=$(grep -o 'https://claude\.ai/code/session_[A-Za-z0-9]*' <<<"$screen" | head -1 || true)
  if [ -n "$url" ]; then
    echo "session: $name"
    echo "dir:     $dir"
    [ -n "$fork" ] && echo "fork of: $fork"
    echo "url:     $url"
    exit 0
  fi
  if grep -q 'trust this folder' <<<"$screen"; then
    echo "session: $name"
    echo "dir:     $dir"
    echo "pending: folder trust prompt. The user must confirm it:"
    echo "         tmux attach -t $name   (or: tmux send-keys -t $name Down Enter)"
    exit 3
  fi
done

echo "error: no Remote Control URL after 30s; inspect with: tmux attach -t $name" >&2
exit 5
