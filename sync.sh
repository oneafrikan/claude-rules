#!/usr/bin/env bash
#
# sync.sh — pull latest rules and regenerate ~/.claude/CLAUDE.md.
#
# Designed to run as a daily cron job on any machine using this repo.
#
# Logs to: sync.log (last 100 lines kept)
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$REPO_DIR/sync.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

log() { echo "[$TIMESTAMP] $*" | tee -a "$LOG"; }

log "--- claude sync start ---"

log "pulling..."
git -C "$REPO_DIR" pull --rebase >> "$LOG" 2>&1 && log "pull ok" || { log "pull failed"; exit 1; }

log "deploying..."
"$REPO_DIR/deploy.sh" >> "$LOG" 2>&1 && log "deploy ok" || { log "deploy failed"; exit 1; }

# Keep log tidy — last 100 lines only
tail -n 100 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"

log "--- claude sync done ---"
