# flavio-skills

[Claude Code](https://claude.com/claude-code) skills I use on a headless dev box
that I drive from my phone.

| Skill | What it does |
| --- | --- |
| [`remote-agent`](skills/remote-agent/SKILL.md) | Starts another Claude Code agent in a detached tmux session with Remote Control, and returns its link. Can also fork the current conversation into a new session. |
| [`claude-usage`](skills/claude-usage/SKILL.md) | Reports plan usage (5h session and weekly limits, reset times) by reading `/usage` from a throwaway Claude Code in tmux. |

## Requirements

- Claude Code, logged in with a claude.ai plan (Remote Control and `/usage` need it).
- `tmux` and `bash`. Tested on Linux with Claude Code 2.1.309; nothing is
  Linux-specific, but macOS is untested.

## Install

```bash
git clone https://github.com/flaviodelima/flavio-skills.git
cd flavio-skills
./install.sh              # or: ./install.sh --bin ~/bin, ./install.sh --no-bin
```

This symlinks each skill into `~/.claude/skills/` (or `$CLAUDE_CONFIG_DIR/skills/`)
and each script into `~/.local/bin/` as `remote-agent` and `claude-usage`. It never
overwrites an existing file; `git pull` updates the installed skills in place.

## Usage

Ask Claude in plain words ("start a remote session in my-repo", "fork this
conversation", "how much usage is left?"), or run the scripts yourself:

```bash
remote-agent my-repo                 # repo under $CODE_DIR (default ~/code), or a path
remote-agent --fork . my-repo-fork   # copy of the current conversation
claude-usage                         # from a trusted folder
```

A new folder triggers Claude Code's trust prompt. The script stops and reports it
(exit 3) instead of answering, and the skill tells Claude to leave that decision
to you.

## Caveats

Both skills read Claude Code's terminal UI, which is not a stable interface. The
screen texts they match were checked against 2.1.309. If a later version changes
them, the scripts fail with a non-zero exit and a screen dump, not a wrong answer.

`--fork` relies on Claude Code's session storage layout
(`~/.claude/projects/<path with non-alphanumerics as ->/<id>.jsonl`).

If you only need the 5h and 7-day numbers inside an interactive session, the
status line's JSON input carries a `rate_limits` object; `claude-usage` exists for
reading them on demand, including per-model weekly limits.

## License

MIT
