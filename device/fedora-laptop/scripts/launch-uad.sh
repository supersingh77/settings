#!/bin/bash
# UAD-NG Launcher Script
# Launches Universal Android Debloater Next Generation via Toolbox
# Requires: fedora-toolbox with android-tools installed

set -euo pipefail

FEDORA_VERSION=$(rpm -E %fedora)
CONTAINER="fedora-toolbox-${FEDORA_VERSION}"
UAD_BIN="$HOME/.local/bin/uad-ng"

# ── Check container ──────────────────────────────────────────────────────────
if ! toolbox list | grep -q "$CONTAINER"; then
    echo "❌ Container '$CONTAINER' not found."
    echo "   Create it with: toolbox create $CONTAINER"
    exit 1
fi

if [ ! -f "$UAD_BIN" ]; then
    echo "❌ UAD-NG binary not found at $UAD_BIN"
    echo ""
    echo "Run the update script to install it:"
    echo "  update-uad"
    exit 1
fi

if [ ! -x "$UAD_BIN" ]; then
    echo "🔧 Making UAD-NG executable..."
    chmod +x "$UAD_BIN"
fi

# ── ADB udev rules check ─────────────────────────────────────────────────────
# Without proper udev rules, ADB can't open USB devices as a regular user.
UDEV_RULES="/etc/udev/rules.d/51-android.rules"
if [ ! -f "$UDEV_RULES" ]; then
    echo "⚠️  ADB udev rules are missing ($UDEV_RULES)."
    echo ""
    echo "   Without them, ADB may fail to open the device as a regular user."
    echo "   Install android-udev-rules inside the container with:"
    echo "     toolbox run -c $CONTAINER sudo dnf install -y android-udev-rules"
    echo "   Then reload rules:"
    echo "     sudo udevadm control --reload-rules && sudo udevadm trigger"
    echo ""
fi

# ── ADB server: kill host adb if running (avoid conflict with container adb) ─
if command -v adb &>/dev/null; then
    adb kill-server 2>/dev/null || true
fi

# ── Check for connected Android devices ──────────────────────────────────────
echo "🔍 Checking for connected Android devices..."
DEVICES=$(toolbox run -c "$CONTAINER" adb devices 2>/dev/null |
    grep -v "List of devices" |
    grep -Ec "	(device|unauthorized|offline)$" || true)

UNAUTHORIZED=$(toolbox run -c "$CONTAINER" adb devices 2>/dev/null |
    grep -v "List of devices" |
    grep -c "unauthorized" || true)

if [ "$DEVICES" -eq 0 ]; then
    echo ""
    echo "⚠️  No Android device detected via ADB."
    echo ""
    echo "   Make sure:"
    echo "     1. USB Debugging is enabled  (Settings → Developer Options → USB Debugging)"
    echo "     2. Phone is connected via USB cable"
    echo "     3. You selected 'File Transfer' or 'MTP' mode on the phone"
    echo "     4. You tapped 'Allow' on the phone's authorization prompt"
    echo ""
    read -rp "   Continue anyway? [y/N] " REPLY
    echo
    [[ "$REPLY" =~ ^[Yy]$ ]] || exit 1
elif [ "$UNAUTHORIZED" -gt 0 ]; then
    echo ""
    echo "⚠️  Device found but marked 'unauthorized'."
    echo "   Check your phone — there should be an 'Allow USB Debugging' prompt."
    echo "   Tap 'Allow' then re-run this script."
    echo ""
    read -rp "   Continue anyway? [y/N] " REPLY
    echo
    [[ "$REPLY" =~ ^[Yy]$ ]] || exit 1
else
    echo "✅ Found $DEVICES Android device(s)"
fi

# ── Launch UAD-NG ─────────────────────────────────────────────────────────────
echo "🚀 Launching UAD-NG..."
exec toolbox run -c "$CONTAINER" "$UAD_BIN"
