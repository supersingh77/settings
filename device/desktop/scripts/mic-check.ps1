# =============================================================================
# mic-check.ps1 - measure every microphone on the machine and report levels.
#
# Records a few seconds from each DirectShow capture device and reports mean /
# peak volume plus a verdict. Catches the two failure modes that silently ruin
# recordings: a muted/dead device (digital silence) and a device that is alive
# but far too quiet.
#
# Read-only: records to a temp file and deletes it. No admin needed.
#
# Usage:
#   pwsh device/desktop/scripts/mic-check.ps1
#   pwsh device/desktop/scripts/mic-check.ps1 -Seconds 8
#
# Speak normally while it runs - it measures whatever the mic hears.
# =============================================================================

[CmdletBinding()]
param(
    [int]$Seconds = 5
)

$ErrorActionPreference = 'Continue'

$ffmpeg = (Get-Command ffmpeg.exe -ErrorAction SilentlyContinue).Source
if (-not $ffmpeg) { $ffmpeg = 'C:\Program Files\FFmpeg\bin\ffmpeg.exe' }
if (-not (Test-Path $ffmpeg)) { Write-Error "ffmpeg not found"; exit 1 }

# --- enumerate audio capture devices ---------------------------------------
$list = & $ffmpeg -hide_banner -list_devices true -f dshow -i dummy 2>&1 | Out-String
$devices = [regex]::Matches($list, '"([^"]+)"\s+\(audio\)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
if (-not $devices) { Write-Host 'No DirectShow audio capture devices found.'; exit 1 }

Write-Host "Measuring $($devices.Count) microphone(s) for $Seconds s each - speak now.`n"

$results = foreach ($dev in $devices) {
    Write-Host "--- $dev" -ForegroundColor Cyan
    $r = & $ffmpeg -hide_banner -v info -f dshow -i "audio=$dev" -t $Seconds -af volumedetect -f null NUL 2>&1
    $mean = ($r | Select-String 'mean_volume:\s*(-?[\d.]+) dB' | Select-Object -First 1)
    $peak = ($r | Select-String 'max_volume:\s*(-?[\d.]+) dB' | Select-Object -First 1)

    $meanDb = if ($mean) { [double]$mean.Matches[0].Groups[1].Value } else { $null }
    $peakDb = if ($peak) { [double]$peak.Matches[0].Groups[1].Value } else { $null }

    $verdict =
        if ($null -eq $meanDb) { 'FAILED to open' }
        elseif ($meanDb -le -70) { 'SILENT - muted, dead, or privacy-blocked' }
        elseif ($meanDb -le -50) { 'very quiet - raise Windows mic level' }
        elseif ($meanDb -le -30) { 'quiet - usable with gain' }
        elseif ($peakDb -gt -3) { 'hot - close to clipping' }
        else { 'healthy' }

    [pscustomobject]@{
        Device = $dev
        MeanDb = $meanDb
        PeakDb = $peakDb
        Verdict = $verdict
    }
}

Write-Host ''
$results | Format-Table -AutoSize

Write-Host 'Reference: voice should average about -18 dB with peaks -12 to -6 dB.'
Write-Host 'Digital silence (-90 dB) means the device is muted or not really capturing,'
Write-Host 'not that the room is quiet - a live mic shows room noise around -45 to -60 dB.'
