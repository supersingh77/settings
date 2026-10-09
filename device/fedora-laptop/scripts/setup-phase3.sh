#!/bin/bash
# =============================================================================
# Fedora Silverblue — Phase 3 Setup Script
# Toolbox container setup and OpenWork installation
# Run this AFTER rebooting from Phase 2.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/_lib.sh"

# ----------------------------------------------------------------------------
# 0. Sanity checks
# ----------------------------------------------------------------------------
step "Pre-flight checks"

if [ "$(id -u)" -eq 0 ]; then
    error "Do NOT run this script as root. Run as your normal user."
fi

if ! command -v toolbox &>/dev/null; then
    error "toolbox not found. Did you reboot after Phase 2?"
fi

FEDORA_VERSION=$(rpm -E %fedora)
CONTAINER="fedora-toolbox-${FEDORA_VERSION}"

success "Pre-flight checks passed."

# ----------------------------------------------------------------------------
# 1. Create the general-purpose fedora-toolbox container
# ----------------------------------------------------------------------------
step "Creating '${CONTAINER}' toolbox container"

if toolbox list --containers 2>/dev/null | grep -q "$CONTAINER"; then
    warn "Container '${CONTAINER}' already exists, skipping creation."
else
    info "Creating ${CONTAINER}..."
    toolbox create --assumeyes --container "$CONTAINER" --image "registry.fedoraproject.org/fedora-toolbox:${FEDORA_VERSION}" \
        || error "Failed to create ${CONTAINER} container."
    success "${CONTAINER} container created."
fi

# ----------------------------------------------------------------------------
# 2. Install packages inside the toolbox container
# ----------------------------------------------------------------------------
step "Installing packages in ${CONTAINER}"

info "Installing: 7zip, 7zip-standalone, ffmpeg-free, android-tools, gh..."

# Enable RPM Fusion free + nonfree repos inside the container for ffmpeg-free
toolbox run --container "$CONTAINER" sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm" \
    2>/dev/null || warn "RPM Fusion repos may already be present inside the container."

toolbox run --container "$CONTAINER" sudo dnf install -y \
    7zip \
    7zip-standalone \
    ffmpeg-free \
    android-tools \
    gh \
    || error "Failed to install packages in ${CONTAINER}."

success "Packages installed in ${CONTAINER}."

# ----------------------------------------------------------------------------
# 3. Install OpenWork as an AppImage
# ----------------------------------------------------------------------------
# OpenWork is distributed as an AppImage for Linux.
# It runs directly on the host — no container or RPM required.
# ----------------------------------------------------------------------------
step "Installing OpenWork"

# We use the dedicated update script to fetch and extract the AppImage
bash "$SCRIPT_DIR/update-openwork.sh" || error "Failed to install OpenWork."

# ----------------------------------------------------------------------------
# 4. Set up shell aliases
# ----------------------------------------------------------------------------
step "Setting up shell aliases"

# Install symlinks into ~/.local/bin so commands work from anywhere
bash "$SCRIPT_DIR/install-links.sh"

BASHRC="$HOME/.bashrc"
ALIAS_MARKER="# settings repo aliases"

if grep -q "$ALIAS_MARKER" "$BASHRC" 2>/dev/null; then
    warn "Aliases already present in ${BASHRC}, skipping."
else
    cat >> "$BASHRC" << 'ALIASES'

# settings repo aliases (commands live in ~/.local/bin via install-links.sh)
alias docs='cd ~/Desktop/settings/device/fedora-laptop'
alias update='update-system'
alias update-openwork='update-openwork'
alias update-uad='update-uad'
alias update-antigravity='update-antigravity'
alias cleanup='cleanup-system'
alias uad='launch-uad'
ALIASES
    success "Aliases added to ${BASHRC}."
fi

# Also add to .bash_profile if it sources .bashrc (common on Fedora)
BASH_PROFILE="$HOME/.bash_profile"
if [ -f "$BASH_PROFILE" ] && ! grep -q "\.bashrc" "$BASH_PROFILE" 2>/dev/null; then
    echo -e '\n[ -f ~/.bashrc ] && source ~/.bashrc' >> "$BASH_PROFILE"
    info "Added .bashrc source to .bash_profile."
fi

# ----------------------------------------------------------------------------
# 5. Summary
# ----------------------------------------------------------------------------
step "Phase 3 complete!"

echo ""
echo -e "${BOLD}What was set up:${RESET}"
echo "  📦  ${CONTAINER}       — 7zip, ffmpeg-free, android-tools, gh"
echo "  🤖  OpenWork installed        — Executable at ~/.local/bin/openwork"
echo "  🔗  Shell aliases             — update, update-openwork, update-uad (reload shell)"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}To activate the aliases in your current shell:${RESET}"
echo ""
echo -e "    ${CYAN}source ~/.bashrc${RESET}"
echo ""
echo -e "    ${CYAN}openwork${RESET}                   # launch OpenWork IDE"
echo -e "    ${CYAN}update-openwork${RESET}            # update OpenWork IDE"
echo -e "    ${CYAN}update-uad${RESET}                 # update UAD-NG binary"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "🎉 ${GREEN}${BOLD}Your Fedora Silverblue system setup is complete!${RESET}"
echo ""
