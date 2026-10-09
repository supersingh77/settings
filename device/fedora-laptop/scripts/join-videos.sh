#!/bin/bash
# =============================================================================
# join-videos.sh — Lossless concat of video clips in a folder, ordered by name
#
# Bash twin of device/desktop/scripts/join-videos.ps1 (Windows). Uses ffmpeg
# from the fedora-toolbox container (or host ffmpeg if present).
#
# Usage:
#   bash scripts/join-videos.sh /path/to/folder [output.mp4]
#
# Notes:
#   - Joins ALL video files in the folder, ordered by filename (chronological
#     for phone/OBS timestamps like VID_20260905_160401.mp4).
#   - Lossless (stream copy) — requires all clips to share codec/resolution/fps/audio.
#   - If clips are incompatible, ffmpeg will error; fall back to the re-encode
#     command in notes/ffmpeg-video-workflow.md.
#   - This is a convenience template, not a magic black box. For one-off joins
#     with unique cuts, just run the ffmpeg commands directly.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

# ── ffmpeg resolution: host first, then toolbox ───────────────────────────────
if command -v ffmpeg &>/dev/null; then
    FFMPEG="ffmpeg"
elif command -v toolbox &>/dev/null && toolbox list 2>/dev/null | grep -q fedora-toolbox-44; then
    FFMPEG="toolbox run -c fedora-toolbox-44 ffmpeg"
else
    error "ffmpeg not found (checked host and fedora-toolbox-44)."
fi

# ── Args ──────────────────────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
    echo "Usage: bash $0 <folder> [output.mp4]" >&2
    exit 1
fi
FOLDER="$1"
OUTPUT="${2:-joined.mp4}"

if [ ! -d "$FOLDER" ]; then
    error "Folder not found: $FOLDER"
fi

# ── Find video files, ordered by name ─────────────────────────────────────────
mapfile -t CLIPS < <(find "$FOLDER" -maxdepth 1 -type f \
    \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.webm" -o -iname "*.ts" \) \
    | sort)

if [ "${#CLIPS[@]}" -lt 2 ]; then
    error "Need at least 2 video files in $FOLDER (found ${#CLIPS[@]})."
fi

info "Found ${#CLIPS[@]} clips (ordered by filename):"
for clip in "${CLIPS[@]}"; do
    SIZE=$(du -h "$clip" | awk '{print $1}')
    echo "  $(basename "$clip")  ($SIZE)"
done

# ── Build concat list (absolute paths so ffmpeg resolves them regardless of cwd) ─
LIST_FILE="$(mktemp)"
trap 'rm -f "$LIST_FILE"' EXIT

for clip in "${CLIPS[@]}"; do
    echo "file '$clip'" >> "$LIST_FILE"
done

OUT_PATH="$FOLDER/$OUTPUT"
info "Joining losslessly -> $OUT_PATH"

# Run ffmpeg from the folder so the output lands next to the clips
if ! (cd "$FOLDER" && $FFMPEG -f concat -safe 0 -i "$LIST_FILE" -c copy "$OUTPUT"); then
    error "Join failed. Clips may be incompatible (different codec/resolution/fps). See notes/ffmpeg-video-workflow.md for the re-encode fallback."
fi

success "Done. Output: $OUT_PATH"
info "Verify it plays, then delete the source clips."