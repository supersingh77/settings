#!/bin/bash
# =============================================================================
# capture-phone.sh — Capture phone device + app state via adb
#
# Re-captures the phone's hardware details and app lists into device/phone/.
# Run this monthly (or whenever you enable USB debugging) to keep the
# tracking current.
#
# Prerequisites:
#   - Phone connected via USB with USB debugging enabled
#   - adb available (on this machine it lives inside fedora-toolbox-44)
#
# Usage:
#   bash device/phone/scripts/capture-phone.sh
# =============================================================================

set -euo pipefail

# Self-locate so this works from anywhere (repo may move)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHONE_DIR="$(dirname "$SCRIPT_DIR")"
APPS_DIR="$PHONE_DIR/apps"

# adb wrapper — prefer host adb, fall back to toolbox
if command -v adb &>/dev/null; then
    ADB="adb"
elif command -v toolbox &>/dev/null && toolbox list 2>/dev/null | grep -q fedora-toolbox-44; then
    ADB="toolbox run -c fedora-toolbox-44 adb"
else
    echo "❌ adb not found (checked host and fedora-toolbox-44)." >&2
    exit 1
fi

info()  { echo -e "\e[36mℹ️  $*\e[0m"; }
success(){ echo -e "\e[32m✅ $*\e[0m"; }
error() { echo -e "\e[31m❌ $*\e[0m"; exit 1; }

# ── Check device ──────────────────────────────────────────────────────────────
info "Checking for connected device..."
$ADB devices | grep -q "device$" || error "No device connected. Enable USB debugging and connect the phone."

# ── Capture hardware details ──────────────────────────────────────────────────
info "Capturing hardware details..."
{
    echo "# Phone — Hardware"
    echo ""
    echo "> Captured via adb on $(date +%Y-%m-%d)."
    echo ""
    echo "## Device"
    echo ""
    echo "| Field | Value |"
    echo "|-------|-------|"
    echo "| Brand | $($ADB shell getprop ro.product.brand) |"
    echo "| Model | $($ADB shell getprop ro.product.model) |"
    echo "| Model number | $($ADB shell getprop ro.product.device) |"
    echo "| Codename | $($ADB shell getprop ro.product.name) |"
    echo "| Serial | $($ADB shell getprop ro.serialno) |"
    echo ""
    echo "## Software"
    echo ""
    echo "| Field | Value |"
    echo "|-------|-------|"
    echo "| Android version | $($ADB shell getprop ro.build.version.release) |"
    echo "| API level (SDK) | $($ADB shell getprop ro.build.version.sdk) |"
    echo "| MIUI version | $($ADB shell getprop ro.miui.ui.version.name) |"
    echo "| Build | $($ADB shell getprop ro.build.display.id) |"
    echo "| Security patch | $($ADB shell getprop ro.build.version.security_patch) |"
    echo ""
    echo "## Hardware"
    echo ""
    echo "| Field | Value |"
    echo "|-------|-------|"
    echo "| CPU | $($ADB shell getprop ro.product.cpu.abi) |"
    echo "| RAM | $($ADB shell cat /proc/meminfo | grep MemTotal | awk '{print $2 " kB"}') |"
    echo "| Screen | $($ADB shell wm size | awk '{print $3}') |"
    echo "| Density | $($ADB shell wm density | awk '{print $3}') |"
    echo "| Battery | $($ADB shell dumpsys battery | grep technology | awk '{print $2}') |"
} > "$PHONE_DIR/hardware.md"
success "Hardware saved to hardware.md"

# ── Capture app lists ─────────────────────────────────────────────────────────
info "Capturing app lists..."
$ADB shell pm list packages 2>/dev/null | sed 's/^package://' | sort > "$APPS_DIR/all-packages.txt"
$ADB shell pm list packages -3 2>/dev/null | sed 's/^package://' | sort > "$APPS_DIR/user-installed.txt"

# Debloated = packages uninstalled for user 0 (present in -u but not in normal list)
$ADB shell pm list packages -u 2>/dev/null | sed 's/^package://' | sort > /tmp/phone-all-with-uninstalled.txt
comm -13 "$APPS_DIR/all-packages.txt" /tmp/phone-all-with-uninstalled.txt > "$APPS_DIR/debloated.txt"
rm -f /tmp/phone-all-with-uninstalled.txt

success "App lists saved:"
echo "  all-packages.txt   ($(wc -l < "$APPS_DIR/all-packages.txt") packages)"
echo "  user-installed.txt ($(wc -l < "$APPS_DIR/user-installed.txt") user apps)"
echo "  debloated.txt      ($(wc -l < "$APPS_DIR/debloated.txt") debloated)"

echo ""
info "Note: uad-selection.txt is NOT auto-captured — re-export it from UAD-NG"
info "      (File → Export selection) and copy it into device/phone/apps/."
echo ""
success "Done. Review the changes, then commit:"
echo "  git add device/phone && git commit -m 'phone: refresh capture' && git push"
