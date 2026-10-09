#!/bin/bash
set -euo pipefail
# =============================================================================
# update-antigravity.sh — Update Antigravity 2.0 Hub
#
# Downloads the latest Antigravity 2.0 Hub tarball from Google's CDN and
# extracts it to ~/.local/lib/antigravity-hub/.
#
# Version tracking: ~/.local/lib/antigravity-hub/version
# Idempotent: running consecutively only downloads if a new version exists.
#
# Usage:
#   bash scripts/update-antigravity.sh
# =============================================================================

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

INSTALL_DIR="$HOME/.local/lib/antigravity-hub"
VERSION_FILE="$INSTALL_DIR/version"
DOWNLOAD_PAGE="https://antigravity.google/download"

# ── Check installed version ─────────────────────────────────────────────────
step "Checking installed version"

CURRENT_VERSION=""
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]')
fi

if [ -n "$CURRENT_VERSION" ] && [ -d "$INSTALL_DIR/Antigravity-x64" ]; then
    info "Installed version : v${CURRENT_VERSION}"
else
    info "Antigravity 2.0 not yet installed."
fi

# ── Fetch latest download URL from auto-updater API ────────────────────────
step "Fetching latest release info"

LATEST_URL=$(python3 -c "
import json, urllib.request, sys
api_url = 'https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/releases'
req = urllib.request.Request(api_url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    res = urllib.request.urlopen(req).read().decode('utf-8')
    releases = json.loads(res)
    if releases:
        latest = releases[0]
        ver = latest['version']
        exec_id = latest['execution_id']
        print(f'https://storage.googleapis.com/antigravity-public/antigravity-hub/{ver}-{exec_id}/linux-x64/Antigravity.tar.gz')
except Exception:
    sys.exit(1)
" 2>/dev/null || echo "")

if [ -z "$LATEST_URL" ]; then
    error "Could not find Antigravity 2.0 Linux x64 download URL. Check internet connection."
fi

# Extract version from URL (e.g. "2.3.1-5358163105546240" from ".../antigravity-hub/2.3.1-5358163105546240/...")
LATEST_VERSION=$(echo "$LATEST_URL" | sed 's|.*/antigravity-hub/||;s|/linux-x64/.*||')

info "Latest version  : v${LATEST_VERSION}"

# ── Compare and update ────────────────────────────────────────────────────────
if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ] && [ -d "$INSTALL_DIR/Antigravity-x64" ]; then
    success "Antigravity 2.0 is already up to date (v${LATEST_VERSION})."
    exit 0
fi

step "Downloading Antigravity 2.0 v${LATEST_VERSION}"

TARBALL_TMP="/tmp/antigravity-hub-${LATEST_VERSION}.tar.gz"

info "Downloading from: ${LATEST_URL}"
curl -fSL --retry 3 --retry-delay 2 -o "$TARBALL_TMP" "$LATEST_URL" \
    || error "Failed to download Antigravity 2.0 v${LATEST_VERSION}."

info "Download complete ($(du -h "$TARBALL_TMP" | cut -f1))."

# ── Extract ──────────────────────────────────────────────────────────────────
step "Extracting to ${INSTALL_DIR}"

mkdir -p "$INSTALL_DIR"

# Remove old Antigravity-x64 directory, keep version file
rm -rf "$INSTALL_DIR/Antigravity-x64"

tar -xzf "$TARBALL_TMP" -C "$INSTALL_DIR" \
    || error "Failed to extract tarball."

rm -f "$TARBALL_TMP"

# ── Verify the binary exists ─────────────────────────────────────────────────
if [ ! -f "$INSTALL_DIR/Antigravity-x64/antigravity" ]; then
    error "Extraction succeeded but antigravity binary not found at expected path."
fi

# ── Ensure launcher exists ───────────────────────────────────────────────────
if [ ! -f "$HOME/.local/bin/antigravity2" ]; then
    info "Creating launcher at ~/.local/bin/antigravity2"
    mkdir -p "$HOME/.local/bin"
    cat << 'EOF' > "$HOME/.local/bin/antigravity2"
#!/bin/bash
exec ~/.local/lib/antigravity-hub/Antigravity-x64/antigravity --no-sandbox "$@"
EOF
    chmod +x "$HOME/.local/bin/antigravity2"
fi

# ── Extract icon and ensure desktop entry ────────────────────────────────────
step "Updating desktop integration"

# Extract icon from the app.asar to get the freshest icon
python3 << 'PYEXTRACT' 2>/dev/null || warn "Icon extraction skipped (Pillow not installed or asar parse failed)."
import struct, json, os, sys

asar_path = os.path.expanduser("~/.local/lib/antigravity-hub/Antigravity-x64/resources/app.asar")
icon_dir = os.path.expanduser("~/.local/share/icons/hicolor")

with open(asar_path, "rb") as f:
    f.read(16)
    chunk = f.read(300000)

json_str = chunk.split(b"\x00")[0].decode("utf-8")
header = json.loads(json_str)

icon_info = header["files"]["icon.png"]
size = icon_info["size"]
offset = int(icon_info["offset"])

# Find data section start: after JSON header + padding to 4 bytes
header_end = 16 + len(json_str) + 1
data_start = (header_end + 3) & ~3
real_offset = data_start + offset

with open(asar_path, "rb") as f:
    f.seek(real_offset)
    icon_data = f.read(size)

# Verify it's a PNG
if icon_data[:8] != b"\x89PNG\r\n\x1a\n":
    print("WARNING: extracted icon is not a valid PNG", file=sys.stderr)
    sys.exit(1)

# Get dimensions from PNG header to size properly
width = struct.unpack(">I", icon_data[16:20])[0]
height = struct.unpack(">I", icon_data[20:24])[0]
print(f"Icon: {width}x{height}")

# Write to all standard sizes (requires Pillow)
try:
    from PIL import Image
    import io
except ImportError:
    print("Pillow not installed — run: pip3 install Pillow", file=sys.stderr)
    sys.exit(1)

img = Image.open(io.BytesIO(icon_data))
for size_px in [48, 64, 96, 128, 256, 512]:
    dir_path = os.path.join(icon_dir, f"{size_px}x{size_px}", "apps")
    os.makedirs(dir_path, exist_ok=True)
    resized = img.resize((size_px, size_px), Image.LANCZOS)
    resized.save(os.path.join(dir_path, "antigravity2.png"))

PYEXTRACT

# Ensure desktop entry exists
DESKTOP_ENTRY="$HOME/.local/share/applications/antigravity2.desktop"
if [ ! -f "$DESKTOP_ENTRY" ]; then
    mkdir -p "$HOME/.local/share/applications"
    cat << EOF > "$DESKTOP_ENTRY"
[Desktop Entry]
Name=Antigravity 2.0
Comment=Google Antigravity AI Agent Platform
Exec=${HOME}/.local/bin/antigravity2 %U
Icon=antigravity2
Type=Application
Categories=Development;IDE;X-AI;
StartupWMClass=Antigravity
Terminal=false
StartupNotify=true
EOF
fi

# Refresh caches
update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true

# ── Write version file ───────────────────────────────────────────────────────
echo "$LATEST_VERSION" > "$VERSION_FILE"

# ── Summary ──────────────────────────────────────────────────────────────────
step "Done"

echo ""
echo -e "${GREEN}Antigravity 2.0 v${LATEST_VERSION} installed.${RESET}"
echo ""
echo -e "${BOLD}To launch:${RESET}"
echo ""
echo -e "    ${CYAN}antigravity2${RESET}                   # via CLI"
echo -e "    ${CYAN}Search \"Antigravity 2.0\" in GNOME Activities${RESET}  # via app grid"
echo ""
