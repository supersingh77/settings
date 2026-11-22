#!/bin/bash
# =============================================================================
# update-system.sh — Full system update script for Fedora Silverblue
#
# Updates:
#   1. Flatpak applications
#   2. OpenWork (~/.local/bin/openwork)
#   3. UAD-NG (~/.local/bin/uad-ng)
#   4. Antigravity 2.0 Hub (~/.local/lib/antigravity-hub/)
#   5. fedora-toolbox container packages
#   6. System + layered packages via rpm-ostree upgrade
#
# Slow maintenance tasks (btrfs scrub, flatpak cleanup, journal vacuum,
# rpm-ostree cleanup) live in cleanup-system.sh — run those occasionally.
#
# Each section continues on failure — a failed update won't stop the rest.
#
# Usage:
#   bash scripts/update-system.sh
#   update                 # via alias (after sourcing .bashrc)
# =============================================================================

# Don't exit on error — each section handles its own failures
# set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/_lib.sh"

# ── 1. Flatpak ────────────────────────────────────────────────────────────────
step "Updating Flatpak applications"

run_or_warn "Flatpak update had issues" flatpak update -y
success "Flatpak step complete."

# ── 2. OpenWork ────────────────────────────────────────────────────────────────
step "Checking for OpenWork updates"

if [ -f "$SCRIPT_DIR/update-openwork.sh" ]; then
    run_or_warn "OpenWork update had issues" bash "$SCRIPT_DIR/update-openwork.sh"
else
    warn "update-openwork.sh script not found."
fi

# ── 3. UAD-NG ─────────────────────────────────────────────────────────────────
step "Checking for UAD-NG updates"

if [ -f "$SCRIPT_DIR/update-uad.sh" ]; then
    run_or_warn "UAD-NG update had issues" bash "$SCRIPT_DIR/update-uad.sh"
else
    warn "update-uad.sh script not found."
fi

# ── 4. Antigravity 2.0 Hub ────────────────────────────────────────────────────
step "Checking for Antigravity 2.0 updates"

if [ -f "$SCRIPT_DIR/update-antigravity.sh" ]; then
    run_or_warn "Antigravity update had issues" bash "$SCRIPT_DIR/update-antigravity.sh"
else
    warn "update-antigravity.sh script not found."
fi

# ── 5. fedora-toolbox container ────────────────────────────────────────────
step "Updating fedora-toolbox container"

FEDORA_VERSION=$(rpm -E %fedora)
CONTAINER="fedora-toolbox-${FEDORA_VERSION}"

if toolbox list --containers 2>/dev/null | grep -q "$CONTAINER"; then
    info "Updating ${CONTAINER} packages…"
    run_or_warn "${CONTAINER} update had issues" \
        toolbox run --container "$CONTAINER" sudo dnf upgrade -y --refresh
else
    info "${CONTAINER} not found — skipping."
fi

success "Container update complete."

# ── 6. System + layered packages ──────────────────────────────────────────────
step "Updating system and layered packages (rpm-ostree upgrade)"

OSTREE_LOG=$(mktemp)
rpm-ostree upgrade | tee "$OSTREE_LOG"
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    warn "rpm-ostree upgrade had issues"
fi

if grep -q "No upgrade available" "$OSTREE_LOG"; then
    OSTREE_UPDATED=false
else
    OSTREE_UPDATED=true
fi
rm -f "$OSTREE_LOG"

success "rpm-ostree step complete."

# ── 7. Summary ────────────────────────────────────────────────────────────────
step "Update complete"

if [ "$OSTREE_UPDATED" = true ]; then
    echo ""
    echo -e "${BOLD}rpm-ostree changes staged — reboot to apply:${RESET}"
    echo ""
    echo -e "    ${CYAN}sudo systemctl reboot${RESET}"
    echo ""
    echo -e "${YELLOW}Tip:${RESET}  Run ${CYAN}rpm-ostree status${RESET} to review what will change."
else
    echo ""
    echo -e "${GREEN}System is fully up to date! No reboot required.${RESET}"
fi

echo -e "${YELLOW}Note:${RESET} OpenWork + UAD-NG + Flatpak changes take effect immediately."
echo -e "${YELLOW}Tip:${RESET}  Run ${CYAN}cleanup${RESET} occasionally for slow maintenance (btrfs scrub, journal vacuum, etc.)."
echo ""
