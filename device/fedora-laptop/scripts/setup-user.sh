#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/_lib.sh"

step "Pre-flight checks"

if [ "$(id -u)" -eq 0 ]; then
    error "Do NOT run this script as root. Run as your normal user."
fi

if ! command -v toolbox &>/dev/null; then
    error "toolbox not found. Run make setup-host, reboot, then retry."
fi

FEDORA_VERSION=$(rpm -E %fedora)
CONTAINER="fedora-toolbox-${FEDORA_VERSION}"

success "Pre-flight checks passed."

step "Creating '${CONTAINER}' toolbox container"

if toolbox list --containers 2>/dev/null | grep -q "$CONTAINER"; then
    warn "Container '${CONTAINER}' already exists, skipping creation."
else
    info "Creating ${CONTAINER}..."
    toolbox create --assumeyes --container "$CONTAINER" --image "registry.fedoraproject.org/fedora-toolbox:${FEDORA_VERSION}" ||
        error "Failed to create ${CONTAINER} container."
    success "${CONTAINER} container created."
fi

step "Installing packages in ${CONTAINER}"

info "Installing: 7zip, 7zip-standalone, ffmpeg-free, android-tools, gh..."

toolbox run --container "$CONTAINER" sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm" \
    2>/dev/null || warn "RPM Fusion repos may already be present inside the container."

toolbox run --container "$CONTAINER" sudo dnf install -y \
    7zip \
    7zip-standalone \
    ffmpeg-free \
    android-tools \
    gh ||
    error "Failed to install packages in ${CONTAINER}."

success "Packages installed in ${CONTAINER}."

step "Installing OpenWork"

bash "$SCRIPT_DIR/update-openwork.sh" || error "Failed to install OpenWork."

step "Setting up shell commands"

bash "$SCRIPT_DIR/install-links.sh"

BASHRC="$HOME/.bashrc"
ALIAS_MARKER="device/fedora-laptop/shellrc"

if grep -Fq "$ALIAS_MARKER" "$BASHRC" 2>/dev/null; then
    warn "Existing settings aliases found in ${BASHRC}; no changes made."
else
    printf '\n%s\n' 'if [ -f "$HOME/Desktop/settings/device/fedora-laptop/shellrc" ]; then . "$HOME/Desktop/settings/device/fedora-laptop/shellrc"; fi' >> "$BASHRC"
    success "Repo shell commands enabled in ${BASHRC}."
fi

BASH_PROFILE="$HOME/.bash_profile"
if [ -f "$BASH_PROFILE" ] && ! grep -q "\.bashrc" "$BASH_PROFILE" 2>/dev/null; then
    echo -e '\n[ -f ~/.bashrc ] && source ~/.bashrc' >>"$BASH_PROFILE"
    info "Added .bashrc source to .bash_profile."
fi

step "User setup complete"

echo ""
echo -e "${BOLD}What was set up:${RESET}"
echo "  📦  ${CONTAINER}       — 7zip, ffmpeg-free, android-tools, gh"
echo "  🤖  OpenWork installed        — Executable at ~/.local/bin/openwork"
echo "  🔗  Shell commands enabled    — reload ~/.bashrc"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}Activate the repo shell commands:${RESET}"
echo ""
echo -e "    ${CYAN}source ~/.bashrc${RESET}"
echo ""
echo -e "    ${CYAN}openwork${RESET}"
echo -e "    ${CYAN}update-openwork${RESET}"
echo -e "    ${CYAN}update-uad${RESET}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "🎉 ${GREEN}${BOLD}Your Fedora Silverblue system setup is complete!${RESET}"
echo ""
