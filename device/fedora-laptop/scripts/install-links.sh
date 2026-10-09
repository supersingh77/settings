#!/bin/bash
# =============================================================================
# install-links.sh — Symlink runtime scripts into ~/.local/bin
#
# The runtime scripts (update-system, cleanup-system, etc.) self-locate via
# SCRIPT_DIR, so they work from anywhere. This script creates symlinks in
# ~/.local/bin (which is on PATH) so you can call them as plain commands
# without hardcoding the repo path in aliases.
#
# If the repo ever moves, just re-run this script to re-point the symlinks.
#
# Usage:
#   bash scripts/install-links.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

# Scripts to link: <command name> <relative path to script>
LINKS=(
    "update-system:update-system.sh"
    "cleanup-system:cleanup-system.sh"
    "update-openwork:update-openwork.sh"
    "update-uad:update-uad.sh"
    "update-antigravity:update-antigravity.sh"
    "launch-uad:launch-uad.sh"
)

mkdir -p "$BIN_DIR"

for entry in "${LINKS[@]}"; do
    cmd="${entry%%:*}"
    script="${entry#*:}"
    src="$SCRIPT_DIR/$script"
    dest="$BIN_DIR/$cmd"

    if [ ! -f "$src" ]; then
        echo "⚠️  Skipping $cmd — source not found: $src"
        continue
    fi

    # Remove existing file/symlink at destination (but not a real file we'd clobber)
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        rm -f "$dest"
    fi

    ln -s "$src" "$dest"
    echo "✅ Linked $cmd -> $src"
done

echo ""
echo "Done. Commands are now on PATH:"
echo "  update-system, cleanup-system, update-openwork, update-uad,"
echo "  update-antigravity, launch-uad"
echo ""
echo "Short aliases (update, cleanup, uad) are defined in ~/.bashrc."
