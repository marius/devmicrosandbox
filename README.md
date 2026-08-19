# opencode microsandbox

Infrastructure for an AI agent "microsandbox" — a VM-based dev environment.

## Requirements

External dependencies:

- docker
- microsandbox
- restic
- git
- ruby

`dev create`/`exec`/`opencode` read the OpenRouter key from `~/.local/share/opencode/auth.json` and export it as `OPENROUTER_API_KEY` for the sandbox.
Inside the VM there is only a placeholder `OPENROUTER_API_KEY` variable, which gets replaced by the real key during requests to `openrouter.ai`.


## Commands

`dev` is the single entrypoint. Run it as `./dev <command>`.

| Command | Description |
| --- | --- |
| `./dev build` | `docker build` the image, then pipe `docker save \| microsandbox load` into the sandbox runtime |
| `./dev create` | Create the sandbox (6G RAM / 6 CPUs, mounts the repo at `/workspace`, injects `OPENROUTER_API_KEY` as a secret) |
| `./dev remove` | Tear down the sandbox |
| `./dev exec` | Open a shell inside the sandbox (defaults to `fish`); forwards remaining args |
| `./dev opencode [args...]` | Run `opencode` inside the sandbox, args passed through |
| `./dev backup` | Snapshot now (git mirror + restic) |
| `./dev gc` | Garbage-collect old backups by retention policy (time-tiered); runs automatically at the end of `exec`/`opencode` sessions that produced a backup |
| `./dev check-git` | Verify the repo history against the latest git snapshot |

## Backups

- **Where**: Backups live outside the workspace in `${workspace}_backups/` (a sibling directory containing `git/` bare mirror and `restic/`). The `_backups` directory is not accessible by the VM.
- **When**: `exec` and `opencode` kick off a git + restic backup first, then spawn a background thread that re-backups every 300s (if there are changes in the workspace) until the session exits.
- **What**: `backup` snapshots the workspace via a git mirror (refs under `refs/snapshots/<timestamp>/`) and a restic backup (tagged `opencode-sandbox`).

## GC retention policy

Time-tiered, defaults overridable via env:

- `GC_KEEP_LAST=300` — keep the newest N snapshots (the newest git snapshot is always retained regardless)
- `GC_KEEP_DAILY=14`
- `GC_KEEP_WEEKLY=8`
- `GC_KEEP_MONTHLY=6`

Git GC prunes expired `refs/snapshots/<ts>/*` refs then runs `git gc --prune=now`; restic runs `forget --keep-* --prune`. Point-in-time recovery is limited to the retention window.

## Rebuilding the image

Changes to `Dockerfile` and `packages.txt` only take effect after:

```
./dev build && ./dev remove && ./dev create
```

- `packages.txt` lists apt packages; lines starting with `#` are ignored.
- The Docker base is `node:26` with a global `npm install -g opencode-ai`.
