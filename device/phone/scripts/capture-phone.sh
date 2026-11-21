#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHONE_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
    printf '%s\n' "Usage: $0 <work|personal> <adb-serial>" >&2
}

if [ "$#" -ne 2 ] || [[ "$1" != "work" && "$1" != "personal" ]]; then
    usage
    exit 2
fi

ROLE="$1"
SERIAL="$2"
DEVICE_DIR="$PHONE_DIR/$ROLE"
mkdir -p "$DEVICE_DIR"

if command -v adb >/dev/null 2>&1; then
    ADB=(adb)
elif command -v toolbox >/dev/null 2>&1; then
    ADB=(toolbox run -c "fedora-toolbox-$(rpm -E %fedora)" adb)
else
    printf '%s\n' "adb/toolbox not found" >&2
    exit 1
fi

if ! "${ADB[@]}" devices | awk -v serial="$SERIAL" '$1 == serial && $2 == "device" { found=1 } END { exit !found }'; then
    printf 'Device %s is not connected and authorized.\n' "$SERIAL" >&2
    exit 1
fi

getprop() {
    "${ADB[@]}" -s "$SERIAL" shell getprop "$1" | tr -d '\r'
}

DEVICE="$(getprop ro.product.device)"
MODEL="$(getprop ro.product.model)"
if [[ "$DEVICE" != "spes" || "$MODEL" != "2201117TI" ]]; then
    printf 'Unexpected device for Redmi Note 11 capture: model=%s device=%s\n' "$MODEL" "$DEVICE" >&2
    exit 1
fi

RAM_KB=$("${ADB[@]}" -s "$SERIAL" shell cat /proc/meminfo | awk '/^MemTotal:/ {print $2}')
RAM_GB=$(awk -v kb="$RAM_KB" 'BEGIN {printf "%.1f", kb / 1048576}')

{
    printf '# Redmi Note 11 — %s\n\n' "$ROLE"
    printf '| Property | Value |\n|---|---|\n'
    printf '| Model | %s |\n' "$MODEL"
    printf '| Device | %s (%s) |\n' "$DEVICE" "$(getprop ro.product.name)"
    printf '| RAM visible to Android | %s GiB |\n' "$RAM_GB"
    printf '| Android | %s (API %s) |\n' "$(getprop ro.build.version.release)" "$(getprop ro.build.version.sdk)"
    printf '| ROM/build | %s |\n' "$(getprop ro.build.display.id)"
    printf '| Build fingerprint | %s |\n' "$(getprop ro.build.fingerprint)"
    printf '| Security patch | %s |\n' "$(getprop ro.build.version.security_patch)"
    printf '| MIUI version | %s |\n' "$(getprop ro.miui.ui.version.name)"
    printf '| Bootloader | %s |\n' "$(getprop ro.boot.vbmeta.device_state)"
    printf '| Verified boot | %s |\n' "$(getprop ro.boot.verifiedbootstate)"
} > "$DEVICE_DIR/README.md"

"${ADB[@]}" -s "$SERIAL" shell pm list packages --user 0 | sed 's/^package://' | sort > "$DEVICE_DIR/installed-user-0.txt"
"${ADB[@]}" -s "$SERIAL" shell pm list packages -3 --user 0 | sed 's/^package://' | sort > "$DEVICE_DIR/third-party-user-0.txt"
"${ADB[@]}" -s "$SERIAL" shell pm list packages -u --user 0 | sed 's/^package://' | sort > "$DEVICE_DIR/all-user-0-including-uninstalled.txt"
comm -13 "$DEVICE_DIR/installed-user-0.txt" "$DEVICE_DIR/all-user-0-including-uninstalled.txt" > "$DEVICE_DIR/not-installed-user-0.txt"

printf 'Captured %s (%s, %s GiB RAM) to %s\n' "$ROLE" "$MODEL" "$RAM_GB" "$DEVICE_DIR"
