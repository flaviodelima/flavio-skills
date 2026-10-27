---
name: remote-agent
description: Start another Claude Code agent inside a detached tmux session with Remote Control, so the user can drive it from the Claude app or another device. Use when the user asks to create, open or spawn a remote agent or session (e.g. "start a remote session in <repo>", "crie um agente remoto"). Also use to fork the current conversation into a new remote session ("fork this conversation", "faça um fork").
---

# Remote agent in tmux

Run `scripts/remote-agent.sh` from this skill's directory. It creates the tmux
session, launches `claude --remote-control <name>`, waits for startup and prints
the session link.

```bash
<skill dir>/scripts/remote-agent.sh <dir|repo-name> [session-name]
```

- `<dir|repo-name>`: a path, or a repo name under `$CODE_DIR` (default `~/code`).
  If the user names a repo that isn't cloned yet, clone it there first.
  If no directory is given, use the repo being discussed; ask only if there is none.
- `[session-name]`: defaults to the directory name. Used both as the tmux session
  and the Remote Control name.

## Fork the current conversation

```bash
<skill dir>/scripts/remote-agent.sh --fork <dir> [session-name]
```

Starts the new agent with `claude --resume <id> --fork-session`: a copy of the
conversation with a new session id; the source session keeps going untouched.
The id defaults to `$CLAUDE_CODE_SESSION_ID` (this session); pass `--fork <uuid>`
to fork another. `<dir>` must be the source session's working directory (sessions
are stored per project dir); for this session, use the current directory. Pick a
name that differs from the directory name, e.g. `<repo>-fork`, since the original
often owns it.

## Exit codes

- `0`: running. Reply with the `url:` line and `tmux attach -t <name>`.
- `2`: a session with that name already exists. Offer another name, or report the
  existing one (`tmux capture-pane -pt <name>` shows its link).
- `3`: Claude is waiting on the folder trust prompt. Do not answer it yourself
  unless the user explicitly tells you to for this session; that is their
  decision. Tell them to run `tmux attach -t <name>`, or to ask you to send
  `Down Enter`. Then re-check the pane with `tmux capture-pane -pt <name>` and
  report the link.
- `4`/`5`: startup failed or timed out. Show the pane contents.

The new agent starts in the user's default permission mode. Mention the mode shown
in the pane footer (e.g. "accept edits on").

Other handy commands: `tmux ls` (list), `tmux kill-session -t <name>` (stop;
confirm with the user first, it ends that agent's work).
