#!/bin/bash
set -euo pipefail
# =============================================================================
# update-openwork.sh — Quick OpenWork update (standalone)
#
# Checks for updates and installs the latest OpenWork desktop AppImage
# to ~/.local/bin/openwork.AppImage.
#
# Version tracking: ~/.local/bin/openwork.version
# Idempotent: running consecutively only downloads if a new version exists.
#
# Usage:
#   bash scripts/update-openwork.sh
#   update-openwork        # via alias (after sourcing .bashrc)
# =============================================================================

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

source "$SCRIPT_DIR/../lib/_lib.sh"

INSTALL_DIR="$HOME/.local/lib/openwork"
VERSION_FILE="$HOME/.local/bin/openwork.version"

# ── Check installed version ─────────────────────────────────────────────────
step "Checking installed version"

CURRENT_VERSION=""
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]')
fi

if [ -n "$CURRENT_VERSION" ] && [ -d "$INSTALL_DIR" ]; then
    info "Installed version : v${CURRENT_VERSION}"
else
    info "OpenWork not yet installed."
fi

# ── Fetch latest release from GitHub ────────────────────────────────────────
step "Fetching latest release from GitHub"

RELEASE_JSON=$(curl -fsSL \
    --retry 3 --retry-delay 2 \
    "https://api.github.com/repos/different-ai/openwork/releases/latest" 2>/dev/null)

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
        n = a['name']
        if n.startswith('openwork-linux-x86_64') and n.endswith('.AppImage'):
            print(a['browser_download_url'])
            break
except: pass
" 2>/dev/null || echo "")

if [ -z "$LATEST_VERSION" ]; then
    error "Could not parse latest OpenWork version from GitHub API."
fi

if [ -z "$LATEST_URL" ]; then
    error "Could not find Linux x86_64 AppImage asset in GitHub release v${LATEST_VERSION}."
fi

info "Latest version  : v${LATEST_VERSION}"

# ── Helper: Recreate wrapper and desktop integration ─────────────────────────
create_wrapper() {
    info "Setting up wrapper script..."
    mkdir -p "$HOME/.local/bin"
    cat <<'EOF' >"$HOME/.local/bin/openwork"
#!/bin/bash
export APPDIR=~/.local/lib/openwork
export PATH="${APPDIR}:${APPDIR}/usr/sbin:${PATH}"
export LD_LIBRARY_PATH="${APPDIR}/usr/lib:${LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="${APPDIR}/usr/share/:${XDG_DATA_DIRS}:/usr/share/gnome/:/usr/local/share/:/usr/share/"
exec ~/.local/lib/openwork/openwork --no-sandbox "$@"
EOF
    chmod +x "$HOME/.local/bin/openwork"

    info "Installing desktop entry and icon..."
    mkdir -p "$HOME/.local/share/icons/hicolor/512x512/apps/"
    cp "$INSTALL_DIR/.DirIcon" "$HOME/.local/share/icons/hicolor/512x512/apps/openwork.png" 2>/dev/null || true

    cat <<EOF >"$HOME/.local/share/applications/openwork.desktop"
[Desktop Entry]
Name=OpenWork
Comment=AI IDE
Exec=${HOME}/.local/bin/openwork %U
Icon=openwork
Terminal=false
Type=Application
Categories=Development;IDE;
MimeType=x-scheme-handler/openwork;
EOF
    update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
}

# ── Compare and update ────────────────────────────────────────────────────────
WRAPPER_OK=true
if [ ! -f "$HOME/.local/bin/openwork" ] || grep -q "@openworkdesktop" "$HOME/.local/bin/openwork" 2>/dev/null; then
    WRAPPER_OK=false
fi

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ] && [ -d "$INSTALL_DIR" ]; then
    step "Update check"
    if [ "$WRAPPER_OK" = false ]; then
        warn "OpenWork files exist but wrapper/desktop entry is broken or missing. Regenerating..."
        create_wrapper
        success "OpenWork wrapper regenerated successfully."
    else
        success "OpenWork is already up to date (v${LATEST_VERSION})."
    fi
    exit 0
fi

step "Installing OpenWork v${LATEST_VERSION}"

mkdir -p "$INSTALL_DIR"

APPIMAGE_TMP="$INSTALL_DIR/openwork.AppImage.tmp"

if download_file "$LATEST_URL" "$APPIMAGE_TMP"; then
    info "Extracting AppImage (bypasses FUSE requirement)..."
    chmod +x "$APPIMAGE_TMP"
    cd /tmp
    rm -rf squashfs-root
    "$APPIMAGE_TMP" --appimage-extract >/dev/null 2>&1

    if [ -d "squashfs-root" ]; then
        rm -rf "$INSTALL_DIR"
        mkdir -p "$HOME/.local/lib"
        mv squashfs-root "$INSTALL_DIR"
        rm -f "$APPIMAGE_TMP"

        create_wrapper

        echo "$LATEST_VERSION" >"$VERSION_FILE"
        success "OpenWork v${LATEST_VERSION} installed (extracted to ${INSTALL_DIR})."
    else
        rm -f "$APPIMAGE_TMP"
        error "Failed to extract OpenWork v${LATEST_VERSION}."
    fi
else
    rm -f "$APPIMAGE_TMP"
    error "Failed to download OpenWork v${LATEST_VERSION}."
fi

# ── Summary ───────────────────────────────────────────────────────────────────
step "Done"

echo ""
echo -e "${GREEN}OpenWork v${LATEST_VERSION} ready.${RESET}"
echo ""
echo -e "${BOLD}To run OpenWork:${RESET}"
echo ""
echo -e "    ${CYAN}openwork${RESET}                   # via CLI or App Launcher"
echo ""
