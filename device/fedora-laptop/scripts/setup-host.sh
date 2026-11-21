#!/bin/bash

set -euo pipefail

CHECK_ONLY=false
if [ "${1:-}" = "--check" ]; then
    CHECK_ONLY=true
elif [ "$#" -gt 0 ]; then
    printf 'Usage: %s [--check]\n' "$0" >&2
    exit 2
fi

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/_lib.sh"

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

step "Adding Ghostty COPR repository (alternateved/ghostty)"

GHOSTTY_REPO_URL="https://copr.fedorainfracloud.org/coprs/alternateved/ghostty/repo/fedora-${FEDORA_VERSION}/alternateved-ghostty-fedora-${FEDORA_VERSION}.repo"
GHOSTTY_REPO_DEST="/etc/yum.repos.d/_copr:alternateved:ghostty.repo"

if [ -f "$GHOSTTY_REPO_DEST" ]; then
    warn "Ghostty COPR repo already exists at ${GHOSTTY_REPO_DEST}, skipping."
elif [ "$CHECK_ONLY" = true ]; then
    info "Would add Ghostty COPR repo for Fedora ${FEDORA_VERSION}."
else
    info "Downloading repo file from: ${GHOSTTY_REPO_URL}"
    sudo wget -q "$GHOSTTY_REPO_URL" -O "$GHOSTTY_REPO_DEST" ||
        error "Failed to download Ghostty COPR repo file."
    success "Ghostty COPR repo added."
fi

step "Removing Firefox from base image"

if rpm-ostree status --json 2>/dev/null | python3 -c \
    "import sys,json; d=json.load(sys.stdin); b=[x for x in d['deployments'] if x.get('booted')][0]; removals=b.get('requested-base-removals',[]); exit(0 if any('firefox' in r for r in removals) else 1)" 2>/dev/null; then
    warn "Firefox override-remove is already staged, skipping."
elif ! rpm -q firefox &>/dev/null; then
    warn "Firefox is not currently installed, skipping override-remove."
elif [ "$CHECK_ONLY" = true ]; then
    info "Would stage Firefox base override removal."
else
    info "Staging Firefox removal..."
    rpm-ostree override remove firefox firefox-langpacks 2>/dev/null ||
        rpm-ostree override remove firefox 2>/dev/null ||
        warn "Could not remove firefox-langpacks separately — trying firefox only."
    success "Firefox removal staged."
fi

step "Layering distrobox, ghostty, and uhubctl"

PACKAGES_TO_INSTALL=()

for pkg in distrobox ghostty uhubctl; do
    if rpm -q "$pkg" &>/dev/null; then
        warn "${pkg} is already installed, skipping."
    else
        PACKAGES_TO_INSTALL+=("$pkg")
    fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -eq 0 ]; then
    warn "All packages are already installed, skipping rpm-ostree install."
elif [ "$CHECK_ONLY" = true ]; then
    info "Would stage host packages: ${PACKAGES_TO_INSTALL[*]}"
else
    info "Staging installation of: ${PACKAGES_TO_INSTALL[*]}"
    rpm-ostree install "${PACKAGES_TO_INSTALL[@]}" ||
        error "rpm-ostree install failed. Check the output above for details."
    success "Packages staged: ${PACKAGES_TO_INSTALL[*]}"
fi

if [ "$CHECK_ONLY" = true ]; then
    info "Check-only complete; no changes made."
    exit 0
fi

step "Host setup complete"

echo ""
echo -e "${BOLD}Current deployment status:${RESET}"
rpm-ostree status
info "Review rpm-ostree status; reboot only if a new deployment is pending."
info "After any required reboot, run make -C '$REPO_ROOT' setup-user."
