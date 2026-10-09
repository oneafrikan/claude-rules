# claude-rules

A reusable **CLAUDE.md** setup for [Claude Code](https://claude.com/claude-code): a
single, portable file of behavioral rules (the "Karpathy Rules") plus an optional
per-machine overlay, composed via Claude Code's native `@import` mechanism.

## What's in here

| File | Purpose |
|------|---------|
| `rules.md` | The behavioral core — communication style, coding discipline, verification rules, SOP. Edit once, applies everywhere you deploy it. Contains no machine-specific or personal information. |
| `machines/example.md` | Template for an optional per-machine overlay (SSH routing, local paths, machine-specific gotchas). Copy it to `machines/<hostname>.md` and fill in your own — real `machines/*.md` files are gitignored, so personal details never get committed here. |
| `deploy.sh` | Generates `~/.claude/CLAUDE.md` (Claude Code's global user memory) from `rules.md`, plus your local `machines/<hostname>.md` if one exists. Accepts flags for layering private files on top (`--machines-dir`, `--import`, `--require-machine`; see [Setup](#setup)). |
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

**Keeping a machine in sync:** run `sync.sh` from cron (example: daily at 08:00).

```
0 8 * * * ~/claude-rules/sync.sh >> /dev/null 2>&1
```

## How it loads

Claude Code reads `~/.claude/CLAUDE.md` for every session and resolves `@path`
imports (recursively, `~` supported), so `rules.md` — and your machine overlay,
if you added one — get merged in at load time.

## The rules

One line per section of [`rules.md`](rules.md).

**Communication**

- [Communication Style — Non-Negotiable](rules.md#communication-style--non-negotiable) — terse, answer first; banned openers, filler and jargon; bullets over paragraphs; number anything the user might reply to.

**Core coding discipline (the Karpathy Rules)**

1. [Think Before Coding](rules.md#1-think-before-coding) — state assumptions, surface tradeoffs, ask when unclear.
2. [Simplicity First](rules.md#2-simplicity-first) — minimum code that solves the problem; nothing speculative.
3. [Surgical Changes](rules.md#3-surgical-changes) — touch only what you must; clean up only your own mess.
4. [Goal-Driven Execution](rules.md#4-goal-driven-execution) — define success criteria and loop until verified.

**Ops safety**

5. [Verify Before Declaring Done](rules.md#5-verify-before-declaring-done) — for infra/ops, observe the result; re-runs must be safe.
6. [Live Systems Are Not Test Environments](rules.md#6-live-systems-are-not-test-environments) — route outbound output to a safe target first; mind when config is read.
7. [Never Assert System State From Memory](rules.md#7-never-assert-system-state-from-memory) — check the file, config or permission before claiming.
8. [Pause After Discovery, Not Just Before Action](rules.md#8-pause-after-discovery-not-just-before-action) — a new problem found mid-task is reported, not fixed unprompted.
9. [Test Runs Are Production Actions](rules.md#9-test-runs-are-production-actions) — restarts, cron edits and deploys need state, expected outcome and confirmation.
10. [Three-Tool Check-In Rule](rules.md#10-three-tool-check-in-rule) — after every 3 consecutive tool calls, summarise and wait for a go-ahead.
11. [Read the Docs Before Touching the System](rules.md#11-read-the-docs-before-touching-the-system) — consult local/vendor docs before trial and error.

**Collaboration**

12. [Confirm Scope Before Drafting Structured Artefacts](rules.md#12-confirm-scope-before-drafting-structured-artefacts) — one short scope question before plans, specs or READMEs over ~50 lines.
13. [Discussion Is Not Decision](rules.md#13-discussion-is-not-decision) — exploring options is not permission to act.
14. [Don't Narrate Decision Ownership](rules.md#14-dont-narrate-decision-ownership) — ask the question directly; drop "this is your call" framing.
15. [Delegate Specialist Work to Specialist Agents](rules.md#15-delegate-specialist-work-to-specialist-agents) — default to a specialist agent for technical work; the main session orchestrates. **Deliberately assumes [the-grid](https://github.com/oneafrikan/the-grid) agents (`grid-*`, `core-*`) are installed** — see [Forking / adapting](#forking--adapting).
16. [Surface Branch/Worktree Status at Session Start and End](rules.md#16-surface-branchworktree-status-at-session-start-and-end) — report in-flight branches, worktrees and PRs at start; state merged/unmerged at end.

**Housekeeping**

- [Standard Operating Procedure](rules.md#standard-operating-procedure) — commenting, TODO.md, README/CLAUDE.md, commit-and-push habits.

## Design notes

- `rules.md` is meant to be identical across every machine and safe to fork/share
  publicly — nothing machine-specific belongs in it.
- Machine-specific facts (SSH key routing, local paths, per-box conventions) belong
  in `machines/<hostname>.md`, which is gitignored by default here.
- If you want that overlay itself version-controlled and synced across your own
  machines, keep overlays/addenda in a separate private repo and call this
  `deploy.sh` with `--machines-dir` / `--import` / `--require-machine` (see
  [Setup](#setup)) — no copy of the script.

## Forking / adapting

Fork the repo and edit `rules.md` to taste. Two things in it are specific to its author:

- The SOP section names "Gareth" — change it to you.
- Rule 15 assumes [the-grid](https://github.com/oneafrikan/the-grid) agents (`grid-*`, `core-*`) are installed — swap in your own agents or drop the rule.

## License

MIT — see [LICENSE](LICENSE).
