---
name: claude-usage
description: Show Claude plan usage left, i.e. the current session (5h) and weekly limits, reset times and what is consuming them, by reading /usage from a throwaway Claude Code in tmux. Use when the user asks about usage, limits, credits or quota (e.g. "how much usage is left?", "weekly limit", "quanto de usage ainda temos").
---

# Claude usage via tmux

`/usage` is an interactive slash command the agent cannot run on itself, so the
script starts a throwaway `claude` in a detached tmux session, sends `/usage`,
prints the screen and kills the session.

```bash
<skill dir>/scripts/claude-usage.sh [dir]
```

`dir` must be a trusted folder (default: the current directory, which is trusted
if you are running in it). Exit codes: `3` the folder isn't trusted (pick another
trusted dir rather than answering the trust prompt), `4` claude did not start,
`5` the `/usage` screen wasn't recognized (show the screen dump to the user).

Reply briefly: session % used and reset, weekly % (all models, and per model if
shown) and reset, then one line on the biggest contributor if any. Reset times
are printed in the timezone `/usage` shows; convert to the user's if known.
