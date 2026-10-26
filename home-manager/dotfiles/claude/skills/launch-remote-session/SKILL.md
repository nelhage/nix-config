---
name: launch-remote-session
description: Launch (or resume) a Claude Code session in a given repository/directory on this Linux machine, with Remote Control enabled so it can be driven from the Claude app or claude.ai/code. Use when asked to start, spin up, open, or resume a claude session "in <repo>", "for <project>", or "that I can use from my phone/the app". Also covers listing and stopping sessions launched this way.
---

`launch.sh` (next to this file) starts `claude --remote-control` in a
transient systemd user unit and prints the session's claude.ai/code URL.
Always use the script instead of running `claude` yourself:

```
bash ~/.claude/skills/launch-remote-session/launch.sh [options] [DIR]
```

| Option | Meaning |
| - | - |
| `--name NAME` | Session title in the app / claude.ai/code. Without it the title is auto-generated (`<host>:<dir>-…`) and then follows the first prompt. |
| `--resume ID` | Resume an existing conversation instead of starting a new one (see below). DIR may be omitted; it defaults to where the conversation ran. |
| `--continue` | Resume the most recent conversation in DIR. |
| `--permission-mode MODE` | Starting permission mode: `default`, `acceptEdits`, `auto`, `plan`, … Only pass this if the user asked for one. |
| `--list` | Print the 20 most recent conversations in DIR (`UUID  mtime  first prompt`) and exit. |
| `--timeout SECS` | How long to wait for Remote Control to connect (default 60). |

On success it prints the unit name, directory, local session UUID and the
`https://claude.ai/code/session_…` URL. **Give the user the URL**. The session
also appears in the app's session list.

## Choosing the directory

The user will usually name a repository, not a path. Resolve it to a local
checkout (most live under `~/code/`; this nix config is `/etc/nixos`). If you
can't find it or it's ambiguous, ask. Don't clone anything unless asked.

## New vs. resume

Start a **new** session by default. Resume only when the user asks to resume,
continue, or reopen an existing session:

- "the last session in X" → `--continue X`
- a claude.ai/code URL or `session_…` ID → `--resume <url-or-id>`. This only
  works for sessions whose transcript records that URL, which includes any
  session started by this script.
- a local session UUID → `--resume <uuid>`
- a description ("the one where I was fixing the build") → run `--list DIR`,
  pick the matching UUID, and confirm with the user if more than one fits.

If the conversation is already running under this script, the script reports
"Already running" and prints the existing URL instead of launching a second
copy.

## Managing sessions

Units are named `claude-rc-<dirname>-<first 8 chars of the session UUID>`.

- List: `systemctl --user list-units 'claude-rc-*'`
- Stop: `systemctl --user stop <unit>`. The conversation is preserved and
  can be brought back with `--resume`.

A session keeps running after it is archived or closed in the app, so the
unit stays up until someone stops it. Stop units only when asked.

## Failure modes

- **Timed out waiting for Remote Control**: almost always means the
  directory has never been trusted, and claude is stuck on the trust prompt
  that nobody can see. Ask the user to run `claude` in that directory from a
  real terminal once and accept the prompt. Don't edit `~/.claude.json`
  to trust it for them.
- **claude exited before Remote Control connected**: the script prints the
  unit's journal. Common causes are a logged-out account (`/login`) or
  Remote Control being disabled.

## Why it works this way

- **`systemd-run --user`** puts claude in its own cgroup under the user
  manager, so it outlives (and can't be killed with) the session that
  launched it.
- **Environment**: the unit runs claude via `zsh -i -c`, the same approach
  as the `nelhage.claude-remote` home-manager module. claude then gets the
  environment a fresh terminal would have. Copying the launcher's
  environment would be wrong: when the launcher is itself a Claude session,
  it carries `CLAUDECODE`, `CLAUDE_CODE_SESSION_ID`, messaging-socket
  variables and so on, and those would confuse the child.
- **Interactive `claude --remote-control` instead of `claude remote-control`
  (server mode)**: server mode refuses to start in a folder another server
  already serves, which is the case for several always-on
  `claude-remote-*` services. It can also only reattach to sessions from the
  last ~4 hours. The interactive mode has neither limitation and can
  `--resume` any conversation. It needs a tty, which `script` provides. The
  tty output is discarded.
- **Finding the URL**: interactive claude writes a `bridge_status` record
  containing the URL into its transcript
  (`~/.claude/projects/<cwd with non-alphanumerics → '-'>/<uuid>.jsonl`). The
  script pre-assigns new sessions' UUIDs with `--session-id` so it knows
  which file to watch.

This needs a systemd user manager (Linux). It won't work on the Mac.
