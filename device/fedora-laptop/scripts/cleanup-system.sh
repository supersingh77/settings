#!/bin/bash
# =============================================================================
# cleanup-system.sh — Slow maintenance tasks for Fedora Silverblue
#
# These tasks are safe but can take several minutes, so they're kept separate
# from the fast daily `update` command. Run occasionally (e.g. weekly/monthly).
#
# Cleans:
#   1. Btrfs scrub (detect silent data corruption)
#   2. Unused Flatpak runtimes/extensions
#   3. rpm-ostree cleanup (remove old deployments, frees Btrfs snapshot space)
#   4. Journal vacuum (keep last 2 weeks / 64 MB)
#   5. DNS cache flush
#   6. Empty GNOME Trash
#
# Each section continues on failure — a failed task won't stop the rest.
# Where possible, sections report space freed (before → after).
#
# Usage:
#   bash scripts/cleanup-system.sh
#   cleanup                # via alias (after sourcing .bashrc)
# =============================================================================

# Don't exit on error — each section handles its own failures
# set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/_lib.sh"

echo -e "${YELLOW}ℹ️  This is a slow maintenance task — it may take several minutes.${RESET}"

# ── Helper: human-readable size ───────────────────────────────────────────────
# Usage: human <bytes>
human() {
    local bytes="$1"
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(awk "BEGIN{printf \"%.1f\", $bytes/1073741824}") GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(awk "BEGIN{printf \"%.1f\", $bytes/1048576}") MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(awk "BEGIN{printf \"%.1f\", $bytes/1024}") KB"
    else
        echo "${bytes} B"
    fi
}

# ── 1. Btrfs scrub ────────────────────────────────────────────────────────────
step "Running Btrfs scrub (detect silent data corruption)"

# On Silverblue, / is an OSTree mount — the btrfs filesystem lives at /var
# (with /var/home as a subvolume). Scrub /var to cover the whole filesystem.
# Requires sudo; skip gracefully if unavailable.
run_or_warn "Btrfs scrub had issues" sudo btrfs scrub start -B /var
success "Btrfs scrub step complete."

# ── 2. Unused Flatpak runtimes ────────────────────────────────────────────────
step "Removing unused Flatpak runtimes"

# Remove orphaned runtimes/extensions no longer referenced by any app.
# Capture the output so we can report what was freed.
FLATPAK_OUT=$(flatpak uninstall --unused -y 2>&1)
FLATPAK_RC=$?
if [ $FLATPAK_RC -ne 0 ]; then
    warn "Flatpak unused cleanup had issues — continuing anyway."
else
    # flatpak prints "X packages, Y data" on removal — surface it if present
    echo "$FLATPAK_OUT" | grep -iE "packages|data|deleted|removed" | head -3 || true
    success "Flatpak cleanup complete."
fi

# ── 3. rpm-ostree cleanup ─────────────────────────────────────────────────────
step "Cleaning up old rpm-ostree deployments"

# Remove pending/rollback deployments to free Btrfs snapshot space.
# Keeps the current deployment and its rollback.
# Report freed space: rpm-ostree cleanup prints "Freed: X MB" when it removes.
OSTREE_OUT=$(rpm-ostree cleanup -m 2>&1)
OSTREE_RC=$?
if [ $OSTREE_RC -ne 0 ]; then
    warn "rpm-ostree cleanup had issues — continuing anyway."
else
    echo "$OSTREE_OUT" | grep -iE "freed|removed|deployment" | head -3 || true
    success "rpm-ostree cleanup complete."
fi

# ── 4. Journal vacuum ─────────────────────────────────────────────────────────
step "Vacuuming systemd journal"

# On Btrfs + OSTree, UPower -nan errors can accumulate thousands of log lines.
# Keep only the last 2 weeks OR 64 MB, whichever is smaller.
# Measure before/after to report space freed.
JOURNAL_DIR="/var/log/journal"
if [ -d "$JOURNAL_DIR" ]; then
    BEFORE=$(du -sb "$JOURNAL_DIR" 2>/dev/null | awk '{print $1}')
    BEFORE=${BEFORE:-0}
else
    BEFORE=0
fi

run_or_warn "Journal vacuum had issues" \
    journalctl --vacuum-time=2weeks --vacuum-size=64M

AFTER=$(du -sb "$JOURNAL_DIR" 2>/dev/null | awk '{print $1}')
AFTER=${AFTER:-0}
FREED=$((BEFORE - AFTER))
if [ "$FREED" -gt 0 ]; then
    success "Journal: $(human "$BEFORE") → $(human "$AFTER") (freed $(human "$FREED"))"
else
    success "Journal already within limits ($(human "$AFTER"))."
fi

# ── 5. DNS cache flush ────────────────────────────────────────────────────────
step "Flushing DNS cache"

# systemd-resolved keeps a per-interface DNS cache; flush it.
if command -v resolvectl &>/dev/null; then
    run_or_warn "DNS cache flush had issues" resolvectl flush-caches
    success "DNS cache flushed."
else
    warn "resolvectl not found — skipping DNS cache flush."
fi

# ── 6. Empty GNOME Trash ──────────────────────────────────────────────────────
step "Emptying GNOME Trash"

TRASH_DIR="$HOME/.local/share/Trash"
if [ -d "$TRASH_DIR" ] && [ -n "$(ls -A "$TRASH_DIR/files" 2>/dev/null)" ]; then
    BEFORE=$(du -sb "$TRASH_DIR" 2>/dev/null | awk '{print $1}')
    BEFORE=${BEFORE:-0}

    if command -v gio &>/dev/null; then
        run_or_warn "Trash empty had issues" gio trash --empty
    else
        # Fallback: remove trash contents directly
        rm -rf "$TRASH_DIR/files/"* "$TRASH_DIR/info/"* 2>/dev/null
    fi

    AFTER=$(du -sb "$TRASH_DIR" 2>/dev/null | awk '{print $1}')
    AFTER=${AFTER:-0}
    FREED=$((BEFORE - AFTER))
    if [ "$FREED" -gt 0 ]; then
        success "Trash emptied: freed $(human "$FREED")."
    else
        success "Trash emptied."
    fi
else
    info "Trash is already empty — skipping."
fi

# ── 7. Summary ────────────────────────────────────────────────────────────────
step "Cleanup complete"

echo ""
echo -e "${GREEN}All maintenance tasks finished.${RESET}"
echo -e "${YELLOW}Tip:${RESET}  Run ${CYAN}sudo btrfs scrub status /var${RESET} to review the last scrub."
echo ""