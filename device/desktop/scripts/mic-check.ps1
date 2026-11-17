[CmdletBinding()]
param(
    [int]$Seconds = 5
)

$ErrorActionPreference = 'Continue'

. (Join-Path $PSScriptRoot '..\lib\audio-levels.ps1')

function Get-FFmpegPath {
    $onPath = (Get-Command ffmpeg.exe -ErrorAction SilentlyContinue).Source
    if ($onPath) { return $onPath }
    $machineWide = 'C:\Program Files\FFmpeg\bin\ffmpeg.exe'
    if (Test-Path -LiteralPath $machineWide) { return $machineWide }
    return $null
}

function Get-CaptureDevices {
    param([string]$FFmpeg)
    $listing = & $FFmpeg -hide_banner -list_devices true -f dshow -i dummy 2>&1 | Out-String
    $names = [regex]::Matches($listing, '"([^"]+)"\s+\(audio\)') | ForEach-Object { $_.Groups[1].Value }
    @($names | Sort-Object -Unique)
}

function Measure-Capture {
    param([string]$FFmpeg, [string]$Device, [int]$Duration)
    $output = & $FFmpeg -hide_banner -v info -f dshow -i "audio=$Device" -t $Duration -af volumedetect -f null NUL 2>&1
    $meanMatch = $output | Select-String 'mean_volume:\s*(-?[\d.]+) dB' | Select-Object -First 1
    $peakMatch = $output | Select-String 'max_volume:\s*(-?[\d.]+) dB' | Select-Object -First 1
    [pscustomobject]@{
        MeanDb = if ($meanMatch) { [double]$meanMatch.Matches[0].Groups[1].Value } else { $null }
        PeakDb = if ($peakMatch) { [double]$peakMatch.Matches[0].Groups[1].Value } else { $null }
    }
}

$ffmpeg = Get-FFmpegPath
if (-not $ffmpeg) {
    Write-Host 'ffmpeg not found' -ForegroundColor Red
    exit 1
}

$devices = Get-CaptureDevices -FFmpeg $ffmpeg
if ($devices.Count -eq 0) {
    Write-Host 'No DirectShow audio capture devices found.' -ForegroundColor Yellow
    exit 1
}

Write-Host "Measuring $($devices.Count) microphone(s) for $Seconds s each - speak now.`n"

$results = foreach ($device in $devices) {
    Write-Host "--- $device" -ForegroundColor DarkGray
    $levels = Measure-Capture -FFmpeg $ffmpeg -Device $device -Duration $Seconds
    [pscustomobject]@{
        Device = $device
        MeanDb = $levels.MeanDb
        PeakDb = $levels.PeakDb
        Verdict = Get-CaptureVerdict -MeanDb $levels.MeanDb -PeakDb $levels.PeakDb
    }
}

Write-Host ''
$results | Format-Table -AutoSize
Write-Host 'Thresholds and how to read this: scripts/README.md'

exit 0
