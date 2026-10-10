# claude-rules

A reusable **CLAUDE.md** setup for [Claude Code](https://claude.com/claude-code): a
single, portable file of behavioral rules (the "Karpathy Rules") plus an optional
per-machine overlay, composed via Claude Code's native `@import` mechanism.

## What's in here

| File | Purpose |
|------|---------|
| `rules.md` | The behavioral core — communication style, coding discipline, verification rules, SOP. Edit once, applies everywhere you deploy it. Contains no machine-specific or personal information. |
| `machines/example.md` | Template for an optional per-machine overlay (SSH routing, local paths, machine-specific gotchas). Copy it to `machines/<hostname>.md` and fill in your own — real `machines/*.md` files are gitignored, so personal details never get committed here. |
| `deploy.sh` | Generates `~/.claude/CLAUDE.md` (Claude Code's global user memory) from `rules.md`, plus your local `machines/<hostname>.md` if one exists. Accepts flags for layering private files on top (`--machines-dir`, `--import`, `--require-machine`, `--harnesses`; see [Setup](#setup)). |
| `sync.sh` | Convenience wrapper: `git pull --rebase` + `deploy.sh` (no flags, so it does not pass `--harnesses`; logs to `sync.log`, gitignored, last 100 lines kept). Wire up as a daily cron job to keep multiple machines in sync. |

## Setup

```bash
git clone https://github.com/oneafrikan/claude-rules.git ~/claude-rules
cp ~/claude-rules/machines/example.md ~/claude-rules/machines/$(hostname -s).md   # optional
~/claude-rules/deploy.sh
```

`deploy.sh` is idempotent and backs up any pre-existing hand-written
`~/.claude/CLAUDE.md` before overwriting.
It is plain bash (compatible with macOS's bash 3.2) and is used on both macOS and Linux.

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
| `--harnesses` | Also write a flat copy to the global instructions file of other coding harnesses (see [Other harnesses](#other-harnesses---harnesses)). Default off. |

Unknown flags print usage and exit 1. A leading `$HOME` in import paths is written as `~`.

### Other harnesses (`--harnesses`)

Only Claude Code resolves `@path` imports in a global file. Other harnesses would see
the literal `@~/...` lines (OpenCode even falls back to `~/.claude/CLAUDE.md` when it
has no file of its own), or silently skip the import. With `--harnesses`, after writing
`~/.claude/CLAUDE.md` as usual, `deploy.sh` also writes a **flat** copy — `rules.md`,
then each `--import` file, then the machine overlay, concatenated with a
`<!-- source: ... -->` marker before each, under a three-line generated-by header — to
every target below.

A target is written only if its harness binary is on `PATH` or in one of the standard
install dirs listed in `HARNESS_BIN_DIRS` in `deploy.sh` (Homebrew, `/usr/local/bin`,
`~/.local/bin`, `~/.opencode/bin`, `~/.npm-global/bin`, mise shims), except OpenCode, which
is always written (so it never falls back to the `@`-import `CLAUDE.md`). The dir probe
exists because cron runs with `PATH=/usr/bin:/bin`: without it a scheduled run skips
harnesses that a manual run finds. It only checks for the binary; `PATH` is not changed.

| Harness (binary) | Flat file written |
|---|---|
| Codex (`codex`) | `~/.codex/AGENTS.md` (`$CODEX_HOME` honoured) |
| Antigravity CLI (`agy`) | `~/.gemini/AGENTS.md` (one of its two global files; only one is written so rules load once) |
| OpenCode (`opencode`, always) | `~/.config/opencode/AGENTS.md` |
| Copilot CLI (`copilot`) | `~/.copilot/copilot-instructions.md` (`$COPILOT_HOME` honoured) |
| Goose (`goose`) | `~/.config/goose/AGENTS.md` |

The table lives in one place, commented with each harness's doc source, in
`deploy.sh` (`harness_targets`).

**Size limit (Antigravity CLI):** `agy` truncates any single rule file over 24,000 bytes
(on line boundaries) and shares a ~20,000-token budget across always-on and global rules.
The flat file is `rules.md` (~17.7 KB) plus every `--import` file plus the machine overlay,
so **its size varies per machine**: the overlay differs, so the cap can be hit on one machine
and not on another (observed: ~22.4 KB on one, ~24.7 KB on another, with the same `rules.md`
and addendum). Growth in `rules.md` or in `--import` files hits every machine; the overlay
comes last, so it is what gets cut. Check each machine with `wc -c ~/.gemini/AGENTS.md`.
`deploy.sh --harnesses` warns on stderr (`!! WARNING: flat rules file is N bytes, over the
24000-byte cap for Antigravity CLI (agy) ...`) whenever the `agy` row is written and the flat
file exceeds `AGY_RULE_CAP_BYTES` (one constant in `deploy.sh`). It warns on every run, even
when the file is unchanged, and still writes the file: warn, don't fail. Wrappers that log
`deploy.sh` output with `2>&1` (like a sync script) capture the warning. Sources:
<https://www.antigravity.google/docs/rules/> and the rules text embedded in the `agy` 1.3.2
binary.

- Files are mode `0600` (the content can include a private layer), written via a temp
  file + `mv`, and a pre-existing hand-written file is backed up as `<file>.bak.<timestamp>`.
- Re-running with unchanged sources leaves every target byte-identical (no new backup).
- Flat copies only change when `deploy.sh --harnesses` runs, unlike Claude Code's
  `@imports`, which pick up edits to `rules.md` immediately.
- Rules are not split per harness: every flat copy gets all of `rules.md`, including
  rules that name Claude-specific tooling.

**Needs manual setup (no generated global file):**

- Cursor: User Rules are GUI-only (Settings > Customize > Rules).
- Copilot on github.com: personal instructions text box.
- Windsurf: global rules are capped at 6,000 characters, far below the composed size.
- Aider: no global instructions file (`read:` in `~/.aider.conf.yml` is the closest thing).
- Cline: reads `~/.agents/AGENTS.md` or `~/Documents/Cline/Rules`; not generated here.

**Not supported, by choice:**

- Gemini CLI: deprecated upstream; replaced by Antigravity CLI (above).
- Amp and Crush: not covered.

Removing a row from the table does not delete files it wrote earlier; delete those by hand.

**Keeping a machine in sync:** run `sync.sh` from cron (example: daily at 08:00) or, where
there is no cron, a systemd user timer. It runs
`deploy.sh` without flags, so flat copies for other harnesses are only refreshed by calling
`deploy.sh --harnesses` yourself (e.g. from your own wrapper script).

```
0 8 * * * ~/claude-rules/sync.sh >> /dev/null 2>&1
```

## How it loads

Claude Code reads `~/.claude/CLAUDE.md` for every session and resolves `@path`
imports (recursively, `~` supported), so `rules.md` — and your machine overlay,
if you added one — get merged in at load time. Other harnesses don't resolve imports;
see [Other harnesses](#other-harnesses---harnesses).

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
