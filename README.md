# claude-rules

A reusable **CLAUDE.md** setup for [Claude Code](https://claude.com/claude-code): a
single, portable file of behavioral rules (the "Karpathy Rules") plus an optional
per-machine overlay, composed via Claude Code's native `@import` mechanism.

## What's in here

| File | Purpose |
|------|---------|
| `rules.md` | The behavioral core — communication style, coding discipline, verification rules, SOP. Edit once, applies everywhere you deploy it. Contains no machine-specific or personal information. |
| `machines/example.md` | Template for an optional per-machine overlay (SSH routing, local paths, machine-specific gotchas). Copy it to `machines/<hostname>.md` and fill in your own — real `machines/*.md` files are gitignored, so personal details never get committed here. |
| `deploy.sh` | Generates `~/.claude/CLAUDE.md` (Claude Code's global user memory) from `rules.md`, plus your local `machines/<hostname>.md` if one exists. |
| `sync.sh` | Convenience wrapper: `git pull --rebase` + `deploy.sh`. Wire up as a daily cron job to keep multiple machines in sync. |

## Setup

```bash
git clone https://github.com/oneafrikan/claude-rules.git ~/claude-rules
cp ~/claude-rules/machines/example.md ~/claude-rules/machines/$(hostname -s).md   # optional
~/claude-rules/deploy.sh
```

`deploy.sh` is idempotent and backs up any pre-existing hand-written
`~/.claude/CLAUDE.md` before overwriting.

**Layering your own files on top** (e.g. a private repo that holds an addendum and
per-machine overlays)? Call this same `deploy.sh` with flags rather than keeping a
copy of it:

```bash
~/claude-rules/deploy.sh \
  --machines-dir /path/to/my/machines \
  --import /path/to/my/addendum.md \
  --require-machine
```

| Flag | Effect |
|------|--------|
| `--machines-dir <dir>` | Look for `<hostname>.md` in `<dir>` (default: `machines/` here). |
| `--import <file>` | Repeatable. Adds an `@import` after `rules.md` and before the machine overlay, in the order given. Missing file = error. |
| `--require-machine` | Missing machine overlay = error (default: skip it). |

Unknown flags print usage and exit 1. A leading `$HOME` in import paths is written as `~`.

## How it loads

Claude Code reads `~/.claude/CLAUDE.md` for every session and resolves `@path`
imports (recursively, `~` supported), so `rules.md` — and your machine overlay,
if you added one — get merged in at load time.

## Design notes

- `rules.md` is meant to be identical across every machine and safe to fork/share
  publicly — nothing machine-specific belongs in it.
- Machine-specific facts (SSH key routing, local paths, per-box conventions) belong
  in `machines/<hostname>.md`, which is gitignored by default here.
- If you want that overlay itself version-controlled and synced across your own
  machines, keep it in a separate private repo/directory and point a local copy of
  `deploy.sh` there instead of relying on the gitignored file in this repo.

## License

MIT — see [LICENSE](LICENSE).
