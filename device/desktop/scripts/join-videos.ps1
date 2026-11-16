[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Folder,

    [string]$Output = 'joined.mp4',

    [string[]]$Extensions = @('.mp4', '.mkv', '.mov', '.avi', '.webm', '.ts'),

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Get-FFmpegPath {
    $onPath = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
    if ($onPath) { return $onPath }
    $machineWide = 'C:\Program Files\FFmpeg\bin\ffmpeg.exe'
    if (Test-Path -LiteralPath $machineWide) { return $machineWide }
    return $null
}

function Get-ClipFiles {
    param([string]$Directory, [string[]]$Patterns)
    $found = foreach ($pattern in $Patterns) {
        Get-ChildItem -LiteralPath $Directory -File -Filter "*$pattern"
    }
    @($found | Sort-Object Name)
}

function Format-ConcatEntry {
    param([System.IO.FileInfo]$Clip)
    "file '$($Clip.Name)'"
}

$ffmpeg = Get-FFmpegPath
if (-not $ffmpeg) {
    Write-Host 'FFmpeg not found. Install it or add C:\Program Files\FFmpeg\bin to PATH.' -ForegroundColor Red
    exit 1
}

$directory = (Resolve-Path -LiteralPath $Folder).Path
$clips = Get-ClipFiles -Directory $directory -Patterns $Extensions

if ($clips.Count -lt 2) {
    Write-Host "Need at least 2 video files in $directory (found $($clips.Count))." -ForegroundColor Yellow
    exit 1
}

$outputPath = Join-Path $directory $Output
$listPath = Join-Path $directory 'clips.txt'

Write-Host "Found $($clips.Count) clips (ordered by filename):" -ForegroundColor Cyan
$clips | ForEach-Object { Write-Host "  $($_.Name)  ($([math]::Round($_.Length / 1MB)) MB)" }
Write-Host "Output: $outputPath"

if ($DryRun) {
    Write-Host "`nDry run - would concat $($clips.Count) clips and write $listPath. Nothing changed." -ForegroundColor Yellow
    exit 0
}

$clips | ForEach-Object { Format-ConcatEntry $_ } | Set-Content -Path $listPath -Encoding ascii
& $ffmpeg -f concat -safe 0 -i $listPath -c copy $outputPath
$ffmpegExit = $LASTEXITCODE
Remove-Item -LiteralPath $listPath -Force -ErrorAction SilentlyContinue

if ($ffmpegExit -eq 0) {
    Write-Host "`nDone. Output: $outputPath" -ForegroundColor Green
    Write-Host 'Verify it plays, then delete the source clips.'
    exit 0
}

Write-Host "`nJoin failed. Clips are probably not identical in codec/resolution/fps/audio." -ForegroundColor Red
Write-Host 'Re-encode fallback: notes/ffmpeg-video-workflow.md'
exit 1
