#!/usr/bin/env bash
# Link this repo's skills into Claude Code and their scripts into a bin dir.
# Usage: ./install.sh [--bin DIR | --no-bin]   (default bin dir: ~/.local/bin)
# Symlinks, not copies: a `git pull` here updates the installed skills.
set -euo pipefail

root=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
skills_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
bin_dir="$HOME/.local/bin"

case "${1:-}" in
  --bin) bin_dir=${2:?--bin needs a directory} ;;
  --no-bin) bin_dir="" ;;
  "") ;;
  *) sed -n '2,4p' "$0" >&2; exit 1 ;;
esac

for dep in claude tmux; do
  command -v "$dep" >/dev/null || echo "warning: $dep not found in PATH; the skills need it" >&2
done

# link <source> <target>: create, keep if already ours, never overwrite anything else.
link() {
  if [ -L "$2" ] && [ "$(readlink -f "$2")" = "$(readlink -f "$1")" ]; then
    echo "ok:      $2"
  elif [ -e "$2" ] || [ -L "$2" ]; then
    echo "skipped: $2 already exists (move it away to use this repo's version)"
  else
    ln -s "$1" "$2"; echo "linked:  $2"
  fi
}

mkdir -p "$skills_dir"
for skill in "$root"/skills/*/; do
  skill=${skill%/}
  link "$skill" "$skills_dir/$(basename "$skill")"
  if [ -n "$bin_dir" ]; then
    mkdir -p "$bin_dir"
    for script in "$skill"/scripts/*.sh; do
      link "$script" "$bin_dir/$(basename "$script" .sh)"
    done
  fi
done

if [ -n "$bin_dir" ] && [[ ":$PATH:" != *":$bin_dir:"* ]]; then
  echo "note: $bin_dir is not in PATH; the skills still work, the shortcuts won't" >&2
fi
