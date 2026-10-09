#!/bin/bash
set -euo pipefail
# =============================================================================
# update-uad.sh — Standalone UAD-NG update script
#
# Checks for updates and installs the latest UAD-NG binary
# to ~/.local/bin/uad-ng.
#
# Version tracking: ~/.local/bin/uad-ng.version
#
# Usage:
#   bash scripts/update-uad.sh
# =============================================================================

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/_lib.sh"

UAD_BIN="$HOME/.local/bin/uad-ng"
VERSION_FILE="$HOME/.local/bin/uad-ng.version"

# ── Check installed version ─────────────────────────────────────────────────
step "Checking installed UAD-NG version"

CURRENT_VERSION=""
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]')
fi

if [ -n "$CURRENT_VERSION" ] && [ -f "$UAD_BIN" ]; then
    info "Installed version : v${CURRENT_VERSION}"
else
    info "UAD-NG not yet tracked or binary missing."
fi

# ── Fetch latest release from GitHub ────────────────────────────────────────
step "Fetching latest UAD-NG release from GitHub"

RELEASE_JSON=$(curl -fsSL \
    --retry 3 --retry-delay 2 \
    "https://api.github.com/repos/Universal-Debloater-Alliance/universal-android-debloater-next-generation/releases/latest" 2>/dev/null)

if [ -z "$RELEASE_JSON" ]; then
    error "Could not reach GitHub API. Check internet connection."
fi

LATEST_VERSION=$(echo "$RELEASE_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tag_name', '').lstrip('v'))
except: pass
" 2>/dev/null || echo "")

LATEST_URL=$(echo "$RELEASE_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for a in data.get('assets', []):
        if a['name'] == 'uad-ng-linux':
            print(a['browser_download_url'])
            break
except: pass
" 2>/dev/null || echo "")

if [ -z "$LATEST_VERSION" ]; then
    error "Could not parse latest UAD-NG version from GitHub API."
fi

if [ -z "$LATEST_URL" ]; then
    error "Could not find UAD-NG Linux asset in GitHub release v${LATEST_VERSION}."
fi

info "Latest version  : v${LATEST_VERSION}"

# ── Compare and update ────────────────────────────────────────────────────────
if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ] && [ -f "$UAD_BIN" ]; then
    step "Update check"
    success "UAD-NG is already up to date (v${LATEST_VERSION})."
    
    # Re-verify desktop entry and icon anyway
    VERIFY_REQUIRED=false
    if [ ! -f "$HOME/.local/share/applications/uad-ng.desktop" ] || [ ! -f "$HOME/.local/share/icons/hicolor/128x128/apps/uad-ng.png" ]; then
        VERIFY_REQUIRED=true
    fi
    
    if [ "$VERIFY_REQUIRED" = false ]; then
        exit 0
    fi
fi

step "Installing UAD-NG v${LATEST_VERSION}"

mkdir -p "$HOME/.local/bin"
UAD_TMP="$HOME/.local/bin/uad-ng.tmp"

if download_file "$LATEST_URL" "$UAD_TMP"; then
    mv "$UAD_TMP" "$UAD_BIN"
    chmod +x "$UAD_BIN"
    
    info "Installing desktop entry and icon..."
    mkdir -p "$HOME/.local/share/icons/hicolor/128x128/apps"
    mkdir -p "$HOME/.local/share/applications"
    
    # Download icon if missing
    if [ ! -f "$HOME/.local/share/icons/hicolor/128x128/apps/uad-ng.png" ]; then
        curl -fsSL "https://raw.githubusercontent.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/main/resources/assets/logo-light.png" \
            -o "$HOME/.local/share/icons/hicolor/128x128/apps/uad-ng.png" 2>/dev/null || warn "Could not download UAD-NG icon."
    fi
    
    # Copy desktop entry from scripts (replace placeholders with actual paths)
    if [ -f "$SCRIPT_DIR/uad-ng.desktop" ]; then
        sed -e "s|__HOME__|${HOME}|g" \
            -e "s|__FEDORA_VERSION__|$(rpm -E %fedora)|g" \
            "$SCRIPT_DIR/uad-ng.desktop" \
            > "$HOME/.local/share/applications/uad-ng.desktop"
    fi
    
    update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
    
    echo "$LATEST_VERSION" > "$VERSION_FILE"
    success "UAD-NG v${LATEST_VERSION} installed successfully."
else
    rm -f "$UAD_TMP"
    error "Failed to download UAD-NG v${LATEST_VERSION}."
fi

step "Done"
echo -e "${GREEN}UAD-NG v${LATEST_VERSION} ready.${RESET}"
echo ""
echo -e "${BOLD}To launch UAD-NG:${RESET}"
echo "    Via app launcher or CLI alias: uad"
echo ""
