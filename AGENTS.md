# AGENTS.md

Infrastructure for an OpenCode "microsandbox" (VM-based dev environment). The only real code is `dev` — a self-contained Ruby script that manages the sandbox. There is no app code or test suite here.

## Commands

`dev` is the single entrypoint; run it as `./dev <command>` (it is executable Ruby, no build step):

- `./dev build` — `docker build` the image, then pipe `docker save | microsandbox load` into the sandbox runtime
- `./dev create` — create this directory's sandbox (6G RAM / 6 CPUs, mounts the current directory at `/workspace`, injects `OPENROUTER_API_KEY` as a secret, read-only-mounts dotfiles from `~/.config/devmicrosandbox/dotfiles.txt`). Explicit call optional: `exec`/`opencode` auto-create it on first use.
- `./dev remove` — tear down this directory's sandbox
- `./dev exec` — open a shell inside the sandbox (defaults to `fish`); forwards remaining args
- `./dev opencode [args...]` — run `opencode` inside the sandbox, args passed through
- `./dev backup` — snapshot now (git bare mirror + restic files)
- `./dev gc` — garbage-collect old backups by retention policy (time-tiered: keep last + daily + weekly + monthly); runs automatically at the end of `exec`/`opencode` sessions that produced a backup
- `./dev check-git` — verify the repo history against the latest git snapshot (rewrites/dangling branches)

## Gotchas

- **One sandbox per project directory**: the sandbox name is derived from the cwd (`devmsb-<basename>-<path-hash>`), mounting that directory at `/workspace`. Mounts are fixed at create time, so run `exec`/`opencode` from the project dir you want inside the VM.
- **`exec`/`opencode` auto-backup**: both kick off a git+restic backup first, then spawn a background thread that re-backups every 300s until the session exits. A long session will generate many snapshots — don't mistake this for a bug.
- **GC retention**: time-tiered, defaults `GC_KEEP_LAST=300 GC_KEEP_DAILY=14 GC_KEEP_WEEKLY=8 GC_KEEP_MONTHLY=6` (env-overridable). Git GC prunes expired `refs/snapshots/<ts>/*` refs then runs `git gc --prune=now`; restic runs `forget --keep-* --prune`. Point-in-time recovery is limited to the retention window. The newest git snapshot is always retained regardless of `GC_KEEP_LAST`.
- **Backups live outside the repo**: `${workspace}_backups/` as a sibling directory (contains `git/` bare mirror and `restic/`). The `_backups` dir is not part of this git repo.
- **Dotfiles**: `dev create` read-only-mounts host dotfiles into the sandbox per `~/.config/devmicrosandbox/dotfiles.txt`, one `host_path:guest_path` per line (`host_path` relative to `$HOME`, e.g. `.gitconfig:/root/.gitconfig`). Blank lines and `#` comments ignored; dirs become `--mount-dir`, files `--mount-file`. Missing dotfiles list means no mounts; missing host dotfile or malformed line aborts `create`.
- **External deps required**: `docker`, `microsandbox`, `restic`, `git` and Ruby are prerequisites. `dev create`/`exec`/`opencode` read the OpenRouter key from `~/.local/share/opencode/auth.json` and export it as `OPENROUTER_API_KEY` for the sandbox.
- **Rebuild after editing the image**: `Dockerfile`, `setup.sh` + `packages.txt` changes only take effect after `./dev build && ./dev remove && ./dev create`.
- **`packages.txt`** lists apt packages; lines starting with `#` are ignored. The Docker base is `node:26`.
- **`setup.sh`** contains the image provisioning steps (apt install from `packages.txt`, global npm agents, herdr + integrations, okf CLI); the `Dockerfile` just copies it in and runs it with `bash`.

## Project Memory (OKF)

`knowledge/` holds OKF v0.2 project memory. **Opt-in**: write to it only when the user explicitly asks (e.g. "document this in OKF", "remember this"); never record knowledge automatically after tasks, features, or decisions. Reads are allowed when relevant — search-first, no bulk scans. When memory work is requested, load the `okf-agent-memory` skill for the full conventions and commands.
