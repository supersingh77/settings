# join-videos.ps1
# Lossless concat of video clips in a folder, ordered by filename.
#
# Usage:
#   .\join-videos.ps1 -Folder "C:\Users\amar\Downloads" -Output "joined.mp4"
#
# Notes:
#   - Joins ALL video files in the folder, ordered by filename (chronological
#     for phone/OBS timestamps like VID_20260905_160401.mp4).
#   - Lossless (stream copy) — requires all clips to share codec/resolution/fps/audio.
#   - If clips are incompatible, ffmpeg will error; fall back to the re-encode
#     command in notes/ffmpeg-video-workflow.md.
#   - This is a convenience template, not a magic black box. For one-off joins
#     with unique cuts, just run the ffmpeg commands directly.

param(
    [Parameter(Mandatory = $true)]
    [string]$Folder,

    [string]$Output = "joined.mp4"
)

$ErrorActionPreference = "Stop"

# Resolve folder
$dir = (Resolve-Path $Folder).Path

# Find video files (common extensions), ordered by name
$exts = @("*.mp4", "*.mkv", "*.mov", "*.avi", "*.webm", "*.ts")
$clips = @()
foreach ($ext in $exts) {
    $clips += Get-ChildItem -Path $dir -File -Filter $ext
}
$clips = $clips | Sort-Object Name

if ($clips.Count -lt 2) {
    Write-Host "Need at least 2 video files in $dir (found $($clips.Count))." -ForegroundColor Yellow
    exit 1
}

Write-Host "Found $($clips.Count) clips (ordered by filename):" -ForegroundColor Cyan
$clips | ForEach-Object { Write-Host "  $($_.Name)  ($([math]::Round($_.Length/1MB)) MB)" }

# Build concat list
$listFile = Join-Path $dir "clips.txt"
$clips | ForEach-Object { "file '$($_.Name)'" } | Set-Content -Path $listFile -Encoding ascii

$outPath = Join-Path $dir $Output

Write-Host "`nJoining losslessly -> $outPath" -ForegroundColor Cyan
ffmpeg -f concat -safe 0 -i $listFile -c copy $outPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDone. Output: $outPath" -ForegroundColor Green
    Write-Host "Verify it plays, then delete clips.txt and the source clips."
} else {
    Write-Host "`nJoin failed. Clips may be incompatible (different codec/resolution/fps)." -ForegroundColor Red
    Write-Host "See notes/ffmpeg-video-workflow.md for the re-encode fallback."
}

# Clean up the temp list file
Remove-Item -Path $listFile -Force
