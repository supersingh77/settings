<#
.SYNOPSIS
    Puts a cleaned / noise-reduced audio file back into the original video
    without re-encoding the video stream.

.DESCRIPTION
    The video stream is always stream-copied (-c:v copy), so picture quality is
    bit-identical to the original. The audio is copied too when its codec is
    MP4-compatible (AAC, MP3, AC-3, E-AC-3, ALAC); otherwise it is encoded to
    AAC once, which is unavoidable because the website's output format may be
    WAV/FLAC, and MP4 cannot hold those losslessly in a player-friendly way.

    After muxing, the script re-reads both files and compares the MD5 of the
    video packets to prove the video really was not re-encoded.

.EXAMPLE
    .\remux-audio-back.ps1 -Video "C:\Users\amar\Videos\2026-11-12 22-49-02.mp4" `
                           -Audio "C:\Users\amar\Downloads\cleaned.wav"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Video,
    [Parameter(Mandatory)][string]$Audio,
    [string]$Out,
    [string]$Bitrate = '192k'
)

$ErrorActionPreference = 'Stop'

foreach ($p in @($Video, $Audio)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "Not found: $p" }
}
$Video = (Resolve-Path -LiteralPath $Video).ProviderPath
$Audio = (Resolve-Path -LiteralPath $Audio).ProviderPath

if (-not $Out) {
    $dir  = Split-Path -Parent $Video
    $base = [IO.Path]::GetFileNameWithoutExtension($Video)
    $Out  = Join-Path $dir "$base (cleaned).mp4"
}
if (Test-Path -LiteralPath $Out) {
    $OutFull = (Resolve-Path -LiteralPath $Out).ProviderPath
    if ($OutFull -eq $Video) { throw 'Output path would overwrite the source video.' }
}

function Get-AudioCodec([string]$file) {
    $json = & ffprobe -hide_banner -v error -select_streams a:0 -show_entries stream=codec_name -of json $file
    if ($LASTEXITCODE -ne 0) { throw "ffprobe failed on $file" }
    ($json | ConvertFrom-Json).streams[0].codec_name
}

function Get-StreamMd5([string]$file, [string]$map) {
    $o = & ffmpeg -hide_banner -v error -i $file -map $map -c copy -f md5 -
    if ($LASTEXITCODE -ne 0) { throw "ffmpeg md5 failed on $file" }
    ($o | Select-String 'MD5=').ToString().Trim() -replace '^MD5=', ''
}

$vc = (& ffprobe -hide_banner -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 $Video).Trim()
if (-not $vc) { throw "No video stream found in $Video" }

$acodec   = Get-AudioCodec $Audio
$copyable = @('aac', 'mp3', 'ac3', 'eac3', 'alac') -contains $acodec
$cargs    = if ($copyable) { @('-c:a', 'copy') } else { @('-c:a', 'aac', '-b:a', $Bitrate) }

Write-Host "video : $vc (copy)" -ForegroundColor Cyan
Write-Host "audio : $acodec -> $(if ($copyable) { 'copy' } else { "aac $Bitrate (transcode)" })" -ForegroundColor Cyan
Write-Host "out   : $Out"

& ffmpeg -hide_banner -y -i $Video -i $Audio `
    -map 0:v:0 -map 1:a:0 -c:v copy @cargs `
    -map_metadata 0 -movflags +faststart $Out
if ($LASTEXITCODE -ne 0) { throw "ffmpeg muxing failed with exit code $LASTEXITCODE" }

Write-Host "`nVerifying video packets were copied, not re-encoded..." -ForegroundColor Cyan
$srcMd5 = Get-StreamMd5 $Video '0:v:0'
$outMd5 = Get-StreamMd5 $Out    '0:v:0'
if ($srcMd5 -eq $outMd5) {
    Write-Host "OK  video stream bit-identical ($outMd5)" -ForegroundColor Green
} else {
    Write-Warning "Video packet MD5 differs: source=$srcMd5 output=$outMd5"
}

ffprobe -hide_banner -v error -show_entries stream=index,codec_type,codec_name,width,height,r_frame_rate,channels,sample_rate -show_entries format=duration,size -of default=nw=1 $Out
Write-Host "`nDone: $Out" -ForegroundColor Green
