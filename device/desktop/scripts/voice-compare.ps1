# =============================================================================
# voice-compare.ps1 - objective A/B of voice recordings, for picking a mic.
#
# Feed it one or more audio files recorded with the SAME script and the SAME
# speaking distance. It reports the numbers that actually separate one mic from
# another: noise floor, voice level, signal-to-noise, loudness, headroom and
# where the energy sits in the spectrum.
#
# Expected test pattern per file (speak normally, don't whisper):
#     0-5 s   silence, sit still          -> noise floor
#     5-20 s  talk at normal volume       -> voice level, spectrum
# A few seconds of silence at the start is the whole trick: it turns "sounds
# noisy" into a number.
#
# Read-only. Usage:
#   pwsh device/desktop/scripts/voice-compare.ps1 -Path 'Z:\Recordings'
#   pwsh device/desktop/scripts/voice-compare.ps1 -Path 'Z:\Recordings\mic-test.m4a'
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Path,
    [double]$NoiseSeconds = 5,
    [double]$VoiceStart = 5,
    [double]$VoiceSeconds = 12
)

$ErrorActionPreference = 'Continue'

$ffmpeg = (Get-Command ffmpeg.exe -ErrorAction SilentlyContinue).Source
if (-not $ffmpeg) { $ffmpeg = 'C:\Program Files\FFmpeg\bin\ffmpeg.exe' }
if (-not (Test-Path $ffmpeg)) { Write-Error "ffmpeg not found"; exit 1 }

$files = if (Test-Path $Path -PathType Container) {
    Get-ChildItem $Path -File | Where-Object { $_.Extension -in '.wav', '.m4a', '.mp3', '.flac', '.mp4', '.mkv', '.opus' }
} else {
    Get-Item $Path
}
if (-not $files) { Write-Error "No audio files found at $Path"; exit 1 }

# $inputArgs are ffmpeg options (-ss/-t); $filter is the audio filter chain.
function Measure-Levels {
    param([string]$File, [string[]]$InputArgs = @(), [string]$Filter = 'anull')
    $r = & $ffmpeg -hide_banner -v info -i $File @InputArgs -af "$Filter,volumedetect" -f null NUL 2>&1
    $mean = $r | Select-String 'mean_volume:\s*(-?[\d.]+|-inf) dB' | Select-Object -First 1
    $peak = $r | Select-String 'max_volume:\s*(-?[\d.]+|-inf) dB' | Select-Object -First 1
    [pscustomobject]@{
        Mean = if ($mean) { $v = $mean.Matches[0].Groups[1].Value; if ($v -eq '-inf') { -100 } else { [double]$v } } else { $null }
        Peak = if ($peak) { $v = $peak.Matches[0].Groups[1].Value; if ($v -eq '-inf') { -100 } else { [double]$v } } else { $null }
    }
}

function Measure-Loudness {
    param([string]$File)
    $r = & $ffmpeg -hide_banner -v info -i $File -af 'ebur128=peak=true' -f null NUL 2>&1
    $i = $r | Select-String 'I:\s*(-?[\d.]+|-inf) LUFS' | Select-Object -Last 1
    $l = $r | Select-String 'LRA:\s*(-?[\d.]+) LU' | Select-Object -Last 1
    [pscustomobject]@{
        Lufs = if ($i -and $i.Matches[0].Groups[1].Value -ne '-inf') { [double]$i.Matches[0].Groups[1].Value } else { $null }
        Lra = if ($l) { [double]$l.Matches[0].Groups[1].Value } else { $null }
    }
}

Write-Host "Analysing $($files.Count) file(s)`n" -ForegroundColor Cyan
$rows = foreach ($f in $files) {
    Write-Host "--- $($f.Name)" -ForegroundColor DarkGray

    # -select_streams belongs to ffprobe, not ffmpeg
    $ffprobe = if ($ffmpeg -match 'ffmpeg\.exe$') { $ffmpeg -replace 'ffmpeg\.exe$', 'ffprobe.exe' } else { 'ffprobe.exe' }
    $probe = & $ffprobe -v error -select_streams a:0 `
        -show_entries stream=codec_name,sample_rate,channels `
        -show_entries format=duration -of json $f.FullName 2>$null | Out-String | ConvertFrom-Json

    if (-not $probe.streams) { Write-Warning "$($f.Name) has no audio stream"; continue }

    $dur = [double]$probe.format.duration
    $sr = $probe.streams[0].sample_rate
    $ch = $probe.streams[0].channels

    $noiseSeg = @('-t', "$NoiseSeconds")
    $voiceSeg = @('-ss', "$VoiceStart", '-t', "$VoiceSeconds")

    $noise = (Measure-Levels -File $f.FullName -InputArgs $noiseSeg).Mean
    $voice = (Measure-Levels -File $f.FullName -InputArgs $voiceSeg)
    $loud = Measure-Loudness -File $f.FullName

    $body = (Measure-Levels -File $f.FullName -InputArgs $voiceSeg -Filter 'lowpass=f=300').Mean
    $mid = (Measure-Levels -File $f.FullName -InputArgs $voiceSeg -Filter 'highpass=f=300,lowpass=f=3000').Mean
    $high = (Measure-Levels -File $f.FullName -InputArgs $voiceSeg -Filter 'highpass=f=3000').Mean

    [pscustomobject]@{
        File = $f.Name
        Secs = [math]::Round($dur, 1)
        Fmt = "$($probe.streams[0].codec_name) ${sr}Hz x$ch"
        SnrDb = if ($null -ne $voice.Mean -and $null -ne $noise) { [math]::Round($voice.Mean - $noise, 1) } else { $null }
        NoiseDb = $noise
        VoiceDb = $voice.Mean
        PeakDb = $voice.Peak
        Lufs = $loud.Lufs
        Lra = $loud.Lra
        BodyDb = $body
        MidDb = $mid
        HighDb = $high
    }
}

function Get-Verdict($r) {
    $notes = @()
    if ($null -ne $r.SnrDb) {
        if ($r.SnrDb -lt 3) { $notes += 'no silent lead-in - pattern not followed' }
        elseif ($r.SnrDb -ge 30) { $notes += 'clean' }
        elseif ($r.SnrDb -ge 20) { $notes += 'usable' }
        else { $notes += 'NOISY' }
    }
    if ($null -ne $r.PeakDb -and $r.PeakDb -gt -3) { $notes += 'near clipping' }
    if ($null -ne $r.Lufs -and $r.Lufs -lt -30) { $notes += 'too quiet' }
    if ($null -ne $r.HighDb -and $null -ne $r.MidDb -and ($r.HighDb - $r.MidDb) -gt 6) { $notes += 'harsh/sibilant' }
    if ($null -ne $r.BodyDb -and $null -ne $r.MidDb -and ($r.BodyDb - $r.MidDb) -gt 12) { $notes += 'boomy' }
    if (-not $notes) { $notes += 'balanced' }
    ($notes -join ', ')
}

$report = $rows | ForEach-Object {
    $_ | Add-Member -PassThru -NotePropertyName Verdict -NotePropertyValue (Get-Verdict $_)
}
$report | Format-Table SnrDb, NoiseDb, VoiceDb, PeakDb, Lufs, Lra, BodyDb, MidDb, HighDb, Verdict -AutoSize

Write-Host ''
Write-Host 'How to read this:'
Write-Host '  SnrDb   voice minus noise floor. 30+ dB clean, 20-30 dB usable, <20 dB hissy.'
Write-Host '  NoiseDb room tone during the quiet opening. -60 dB is good, -45 dB is a noisy room.'
Write-Host '  Lufs    integrated loudness. Aim -16 to -20 LUFS; much lower = input gain too low.'
Write-Host '  Body/Mid/High  mean level per band. Body >> Mid = boomy, Mid >> Body = thin,'
Write-Host '                 High near Mid = bright and clear (harsh if it exceeds Mid).'
Write-Host 'Pick the best SNR with a Mid-dominant balance, then confirm by ear.'
