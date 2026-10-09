#!/bin/bash
# =============================================================================
# Fedora Silverblue — Phase 2 Setup Script
# rpm-ostree: repos, removals, and package installs
# Run this in a terminal with sudo privileges, then reboot when prompted.
# =============================================================================

set -euo pipefail

BOLD="\e[1m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RED="\e[31m"
RESET="\e[0m"

info()    { echo -e "${CYAN}ℹ️  $*${RESET}"; }
success() { echo -e "${GREEN}✅ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${RESET}"; }
error()   { echo -e "${RED}❌ $*${RESET}"; exit 1; }
step()    { echo -e "\n${BOLD}━━━ $* ━━━${RESET}"; }

# ----------------------------------------------------------------------------
# 0. Sanity checks
# ----------------------------------------------------------------------------
step "Pre-flight checks"

if [ "$(id -u)" -eq 0 ]; then
    error "Do NOT run this script as root. Run as your normal user (sudo will be invoked where needed)."
fi

if ! command -v rpm-ostree &>/dev/null; then
    error "rpm-ostree not found. This script is only for Fedora Silverblue / Atomic systems."
fi

FEDORA_VERSION=$(rpm -E %fedora)
info "Detected Fedora version: ${FEDORA_VERSION}"
success "Pre-flight checks passed."

# ----------------------------------------------------------------------------
# 1. Add the Ghostty COPR repository
# ----------------------------------------------------------------------------
step "Adding Ghostty COPR repository (alternateved/ghostty)"

GHOSTTY_REPO_URL="https://copr.fedorainfracloud.org/coprs/alternateved/ghostty/repo/fedora-${FEDORA_VERSION}/alternateved-ghostty-fedora-${FEDORA_VERSION}.repo"
GHOSTTY_REPO_DEST="/etc/yum.repos.d/_copr:alternateved:ghostty.repo"

if [ -f "$GHOSTTY_REPO_DEST" ]; then
    warn "Ghostty COPR repo already exists at ${GHOSTTY_REPO_DEST}, skipping."
else
    info "Downloading repo file from: ${GHOSTTY_REPO_URL}"
    sudo wget -q "$GHOSTTY_REPO_URL" -O "$GHOSTTY_REPO_DEST" \
        || error "Failed to download Ghostty COPR repo file."
    success "Ghostty COPR repo added."
fi


# ----------------------------------------------------------------------------
# 2. Remove Firefox (base image package override)
# ----------------------------------------------------------------------------
step "Removing Firefox from base image"

# Check if Firefox override is already in place
if rpm-ostree status --json 2>/dev/null | python3 -c \
    "import sys,json; d=json.load(sys.stdin); b=[x for x in d['deployments'] if x.get('booted')][0]; removals=b.get('requested-base-removals',[]); exit(0 if any('firefox' in r for r in removals) else 1)" 2>/dev/null; then
    warn "Firefox override-remove is already staged, skipping."
elif ! rpm -q firefox &>/dev/null; then
    warn "Firefox is not currently installed, skipping override-remove."
else
    info "Staging Firefox removal..."
    rpm-ostree override remove firefox firefox-langpacks 2>/dev/null \
        || rpm-ostree override remove firefox 2>/dev/null \
        || warn "Could not remove firefox-langpacks separately — trying firefox only."
    success "Firefox removal staged."
fi

# ----------------------------------------------------------------------------
# 3. Layer distrobox, ghostty, and uhubctl via rpm-ostree
# ----------------------------------------------------------------------------
step "Layering distrobox, ghostty, and uhubctl"

PACKAGES_TO_INSTALL=()

# Check each package to avoid re-staging already-layered ones
for pkg in distrobox ghostty uhubctl; do
    if rpm -q "$pkg" &>/dev/null; then
        warn "${pkg} is already installed, skipping."
    else
        PACKAGES_TO_INSTALL+=("$pkg")
    fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -eq 0 ]; then
    warn "All packages are already installed, skipping rpm-ostree install."
else
    info "Staging installation of: ${PACKAGES_TO_INSTALL[*]}"
    rpm-ostree install "${PACKAGES_TO_INSTALL[@]}" \
        || error "rpm-ostree install failed. Check the output above for details."
    success "Packages staged: ${PACKAGES_TO_INSTALL[*]}"
fi

# ----------------------------------------------------------------------------
# 4. Summary and reboot prompt
# ----------------------------------------------------------------------------
step "All changes staged successfully"

echo ""
echo -e "${BOLD}The following changes are queued and will apply after reboot:${RESET}"
echo "  🗑️  Firefox removed (base override)"
echo "  📦  distrobox installed"
echo "  👻  ghostty installed"
echo "  🔌  uhubctl installed"
echo ""
echo -e "${YELLOW}ℹ️  OpenWork AppImage + toolbox container will be set up in Phase 3 (after reboot).${RESET}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}Run the following to apply all changes:${RESET}"
echo ""
echo -e "    ${CYAN}sudo systemctl reboot${RESET}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${BOLD}After reboot, run Phase 3:${RESET}"
echo -e "    ${CYAN}bash ~/Desktop/settings/device/fedora-laptop/scripts/setup-phase3.sh${RESET}"
echo ""

read -rp "Reboot now? [y/N] " REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    info "Rebooting..."
    sudo systemctl reboot
else
    warn "Reboot skipped. Remember to reboot before running Phase 3!"
fi
