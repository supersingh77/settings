#!/bin/bash
# =============================================================================
# bootstrap.sh — Day-Zero Fresh Fedora Silverblue Setup
#
# Run this FIRST on a brand-new Silverblue install.
#
# What it does:
#   1. Generates an SSH key for GitHub (or reuses existing)
#   2. Guides you to add it to GitHub, then tests the connection
#   3. Clones supersingh77/settings to ~/Desktop
#   4. Installs Phase 1 Flatpak apps (no reboot required)
#   5. Prints next steps (Phase 2 → reboot → Phase 3)
#
# Usage (fresh install, no repo yet):
#   curl -fsSL https://raw.githubusercontent.com/supersingh77/settings/main/device/fedora-laptop/scripts/bootstrap.sh | bash
#
# Or if you already cloned the repo:
#   bash ~/Desktop/settings/device/fedora-laptop/scripts/bootstrap.sh
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
step()    { echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n${BOLD}  $*${RESET}\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }

REPO_DEST="$HOME/Desktop/settings/device/fedora-laptop"
GITHUB_USER="supersingh77"
REPO_NAME="settings"
SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_CONFIG="$HOME/.ssh/config"

echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║       Fedora Silverblue — Bootstrap Setup                     ║${RESET}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
info "This script will get your system from zero to ready."
echo ""

# ── Sanity checks ─────────────────────────────────────────────────────────────
step "Step 0 — Pre-flight checks"

if [ "$(id -u)" -eq 0 ]; then
    error "Do NOT run as root. Run as your normal user."
fi

if ! command -v flatpak &>/dev/null; then
    error "flatpak not found. Is this Fedora Silverblue?"
fi

if ! command -v curl &>/dev/null; then
    error "curl not found. Install it with: rpm-ostree install curl"
fi

# Check internet connectivity
if ! curl -fsSL --max-time 5 https://github.com > /dev/null 2>&1; then
    error "No internet connection. Connect to WiFi/Ethernet and try again."
fi

success "Pre-flight checks passed."

# ── SSH Key Setup ─────────────────────────────────────────────────────────────
step "Step 1 — SSH Key Setup"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$SSH_KEY" ]; then
    warn "SSH key already exists at ${SSH_KEY}."
    info "Skipping key generation — using existing key."
else
    info "Generating Ed25519 SSH key for GitHub..."
    read -rp "  Enter your GitHub email address: " GIT_EMAIL
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N "" \
        || error "SSH key generation failed."
    success "SSH key generated at ${SSH_KEY}."
fi

# Show the public key
echo ""
echo -e "${BOLD}Your public SSH key:${RESET}"
echo ""
echo -e "${CYAN}$(cat "${SSH_KEY}.pub")${RESET}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}ACTION REQUIRED:${RESET}"
echo ""
echo "  1. Open: https://github.com/settings/ssh/new"
echo "  2. Title: $(hostname) or something you'll recognise"
echo "  3. Key type: Authentication Key"
echo "  4. Paste the key above and click 'Add SSH key'"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
read -rp "  Press Enter once you've added the key to GitHub... " _

# ── SSH Config for default GitHub account ────────────────────────────────────
step "Step 2 — SSH Config (default GitHub account)"

if grep -q "Host github.com$" "$SSH_CONFIG" 2>/dev/null; then
    warn "SSH config for github.com already exists, skipping."
else
    mkdir -p "$(dirname "$SSH_CONFIG")"
    cat >> "$SSH_CONFIG" << EOF

# ${GITHUB_USER} GitHub account (default)
Host github.com
    HostName github.com
    User git
    IdentityFile ${SSH_KEY}
    IdentitiesOnly yes
EOF
    chmod 600 "$SSH_CONFIG"
    success "SSH config for github.com (${GITHUB_USER}) added."
fi

# ── Test SSH Connection ────────────────────────────────────────────────────────
step "Step 3 — Test GitHub SSH Connection"

info "Testing SSH connection to GitHub..."
for attempt in 1 2 3; do
    OUTPUT=$(ssh -T -o StrictHostKeyChecking=accept-new "git@github.com" 2>&1 || true)
    if echo "$OUTPUT" | grep -q "successfully authenticated"; then
        success "GitHub SSH authentication works!"
        break
    else
        if [ "$attempt" -lt 3 ]; then
            warn "Attempt ${attempt}/3 failed. Retrying in 3 seconds..."
            warn "Output: ${OUTPUT}"
            sleep 3
        else
            echo ""
            warn "SSH test did not confirm authentication."
            warn "Output: ${OUTPUT}"
            echo ""
            echo "  Common causes:"
            echo "    • Key not yet added to GitHub (check https://github.com/settings/keys)"
            echo "    • Firewall blocking port 22 (try a different network)"
            echo ""
            read -rp "  Continue anyway? [y/N] " REPLY
            [[ "$REPLY" =~ ^[Yy]$ ]] || exit 1
        fi
    fi
done

# ── Clone the Repo ─────────────────────────────────────────────────────────────
step "Step 4 — Clone settings"

mkdir -p "$HOME/Desktop"

REPO_ROOT="$HOME/Desktop/settings"

if [ -d "$REPO_ROOT/.git" ]; then
    warn "Repo already exists at ${REPO_ROOT}."
    info "Pulling latest changes..."
    git -C "$REPO_ROOT" pull --rebase \
        && success "Repo updated." \
        || warn "git pull failed — continuing with existing files."
else
    info "Cloning ${GITHUB_USER}/${REPO_NAME}..."
    git clone "git@github.com:${GITHUB_USER}/${REPO_NAME}.git" "$REPO_ROOT" \
        || error "Clone failed. Check your SSH key and repo access."
    success "Repo cloned to ${REPO_ROOT}."
fi

# Set up git identity if not already configured
GIT_NAME=$(git config --global user.name 2>/dev/null || true)
GIT_EMAIL_CFG=$(git config --global user.email 2>/dev/null || true)

if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL_CFG" ]; then
    echo ""
    info "Setting up git identity..."
    [ -z "$GIT_NAME" ] && read -rp "  Git display name (e.g. 'Singh'): " GIT_NAME
    [ -z "$GIT_EMAIL_CFG" ] && read -rp "  Git email: " GIT_EMAIL_CFG
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL_CFG"
    git config --global init.defaultBranch master
    success "Git identity configured."
fi

# ── Symlink runtime scripts into ~/.local/bin ─────────────────────────────────
step "Step 5 — Install runtime script symlinks"

# Ensure ~/.local/bin is on PATH (add to bashrc if missing)
if ! grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" << 'PATHBLOCK'

# Add ~/.local/bin to PATH
export PATH="$HOME/.local/bin:$PATH"
PATHBLOCK
    success "Added ~/.local/bin to PATH in ~/.bashrc."
fi

if [ -f "$REPO_DEST/scripts/install-links.sh" ]; then
    bash "$REPO_DEST/scripts/install-links.sh"
else
    warn "install-links.sh not found at ${REPO_DEST}/scripts/install-links.sh"
fi

# ── Phase 1: Flatpak Apps ─────────────────────────────────────────────────────
step "Step 6 — Phase 1: Install Flatpak Apps (no reboot needed)"

info "Adding Flathub remote if not present..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo --user 2>/dev/null \
    || flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null \
    || warn "Could not add Flathub remote (may already exist system-wide)."

info "Installing Flatpak apps..."
flatpak install flathub \
    com.google.Chrome \
    io.github.celluloid_player.Celluloid \
    io.missioncenter.MissionCenter \
    io.webtorrent.WebTorrent \
    org.flameshot.Flameshot \
    org.qbittorrent.qBittorrent \
    org.videolan.VLC \
    org.gnome.Characters \
    org.gnome.baobab \
    -y \
    || warn "Some Flatpaks may have failed — check output above."

success "Phase 1 Flatpak apps installed."

# Rebuild icon cache so all new app icons show correctly in GNOME
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor/ 2>/dev/null || true

# ── UAD-NG Setup ──────────────────────────────────────────────────────────────
step "Step 7 — UAD-NG (Android Debloater)"

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/icons/hicolor/128x128/apps"
mkdir -p "$HOME/.local/share/applications"

UAD_BIN="$HOME/.local/bin/uad-ng"
UAD_VERSION="v1.2.0"
UAD_URL="https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/releases/download/${UAD_VERSION}/uad-ng-linux"
UAD_ICON_URL="https://raw.githubusercontent.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/main/resources/assets/logo-light.png"

if [ -f "$UAD_BIN" ] && [ -x "$UAD_BIN" ]; then
    warn "UAD-NG binary already exists at ${UAD_BIN}, skipping download."
    if [ ! -f "$HOME/.local/bin/uad-ng.version" ]; then
        echo "${UAD_VERSION#v}" > "$HOME/.local/bin/uad-ng.version"
    fi
else
    info "Downloading UAD-NG ${UAD_VERSION} (~29 MB, may take a moment)..."
    if curl -L --retry 3 "$UAD_URL" -o "$UAD_BIN" 2>/dev/null; then
        chmod +x "$UAD_BIN"
        echo "${UAD_VERSION#v}" > "$HOME/.local/bin/uad-ng.version"
        success "UAD-NG downloaded and made executable."
    else
        warn "UAD-NG download failed. You can retry later with:"
        warn "  curl -L '${UAD_URL}' -o ${UAD_BIN} && chmod +x ${UAD_BIN}"
    fi
fi

# Icon
if [ ! -f "$HOME/.local/share/icons/hicolor/128x128/apps/uad-ng.png" ]; then
    curl -fsSL "$UAD_ICON_URL" \
        -o "$HOME/.local/share/icons/hicolor/128x128/apps/uad-ng.png" 2>/dev/null \
        || warn "Could not download UAD-NG icon."
fi

# Desktop entry
if [ ! -f "$HOME/.local/share/applications/uad-ng.desktop" ] && \
   [ -f "$REPO_DEST/scripts/uad-ng.desktop" ]; then
    sed -e "s|__HOME__|${HOME}|g" \
        -e "s|__FEDORA_VERSION__|$(rpm -E %fedora)|g" \
        "$REPO_DEST/scripts/uad-ng.desktop" \
        > "$HOME/.local/share/applications/uad-ng.desktop"
    update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    success "UAD-NG desktop entry installed."
fi

gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true

# ── Git Aliases & Shell Setup ─────────────────────────────────────────────────
step "Step 8 — Shell Aliases"

BASHRC="$HOME/.bashrc"
ALIAS_MARKER="# settings aliases"

if grep -q "$ALIAS_MARKER" "$BASHRC" 2>/dev/null; then
    warn "Aliases already in ${BASHRC}, skipping."
else
    cat >> "$BASHRC" << 'ALIASES'

# settings aliases
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

# ── Done — Print Next Steps ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║   ✅  Bootstrap Complete!                                     ║${RESET}"
echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${BOLD}What was done:${RESET}"
echo "  🔑  SSH key generated and GitHub alias configured"
echo "  📁  Repo cloned to ~/Desktop/settings"
echo "  🔗  Runtime scripts symlinked into ~/.local/bin (on PATH)"
echo "  📦  Phase 1 Flatpak apps installed (Chrome, VLC, etc.)"
echo "  📱  UAD-NG downloaded and desktop entry installed"
echo "  🔗  Shell aliases added: update, cleanup, uad, docs"
echo ""
echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}Next Steps:${RESET}"
echo ""
echo -e "  ${BOLD}Phase 2${RESET} — Layer RPM packages (distrobox, ghostty, antigravity)"
echo -e "  ${BOLD}Requires a reboot.${RESET}"
echo ""
echo -e "    ${CYAN}bash ~/Desktop/settings/device/fedora-laptop/scripts/setup-phase2.sh${RESET}"
echo ""
echo -e "  ${BOLD}Phase 3${RESET} — Containers + OpenWork (run after Phase 2 reboot)"
echo ""
echo -e "    ${CYAN}bash ~/Desktop/settings/device/fedora-laptop/scripts/setup-phase3.sh${RESET}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${BOLD}Open the docs:${RESET}"
echo ""
echo -e "    ${CYAN}docs${RESET}   — cd into ~/Desktop/settings/device/fedora-laptop"
echo ""
echo -e "  Once Phase 3 is done, use your AI agents:"
echo ""
echo -e "    ${CYAN}openwork${RESET}   — OpenWork AppImage (runs directly on host)"
echo ""
echo -e "  To activate aliases in this shell now:"
echo ""
echo -e "    ${CYAN}source ~/.bashrc${RESET}"
echo ""
