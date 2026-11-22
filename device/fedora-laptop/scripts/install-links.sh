#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"
BIN_DIR="$HOME/.local/bin"

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
        warn "Skipping $cmd — source not found: $src"
        continue
    fi

    if [ -L "$dest" ]; then
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        echo "Refusing to replace non-symlink: $dest" >&2
        exit 1
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
