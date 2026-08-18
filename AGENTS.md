# AGENTS.md

Infrastructure for an OpenCode "microsandbox" (VM-based dev environment). The only real code is `dev` — a self-contained Ruby script that manages the sandbox. There is no app code or test suite here.

## Commands

`dev` is the single entrypoint; run it as `./dev <command>` (it is executable Ruby, no build step):

- `./dev build` — `docker build` the image, then pipe `docker save | microsandbox load` into the sandbox runtime
- `./dev create` — create the sandbox (6G RAM / 6 CPUs, mounts the repo at `/workspace`, injects `OPENROUTER_API_KEY` as a secret)
- `./dev remove` — tear down the sandbox
- `./dev exec` — open a shell inside the sandbox (defaults to `fish`); forwards remaining args
- `./dev opencode [args...]` — run `opencode` inside the sandbox, args passed through
- `./dev backup` — snapshot now (git bare mirror + restic files)
- `./dev check-git` — verify the repo history against the latest git snapshot (rewrites/dangling branches)

## Gotchas

- **`exec`/`opencode` auto-backup**: both kick off a git+restic backup first, then spawn a background thread that re-backups every 300s until the session exits. A long session will generate many snapshots — don't mistake this for a bug.
- **Backups live outside the repo**: `${workspace}_backups/` as a sibling directory (contains `git/` bare mirror and `restic/`). The `_backups` dir is not part of this git repo.
- **External deps required**: `docker`, `microsandbox`, `restic`, `git` and Ruby are prerequisites. `dev create`/`exec`/`opencode` read the OpenRouter key from `~/.local/share/opencode/auth.json` and export it as `OPENROUTER_API_KEY` for the sandbox.
- **Rebuild after editing the image**: `Dockerfile` + `packages.txt` changes only take effect after `./dev build && ./dev remove && ./dev create`.
- **`packages.txt`** lists apt packages; lines starting with `#` are ignored. The Docker base is `node:26` with a global `npm install -g opencode-ai`.

## What's tracked here

Only `Dockerfile`, `dev`, `packages.txt` are committed. Actual project/sandbox work happens inside the sandbox and is snapshotted to `_backups`, not committed to this repo — commit only intended changes here.
