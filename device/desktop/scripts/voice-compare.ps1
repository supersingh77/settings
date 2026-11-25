[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Path,
    [double]$NoiseSeconds = 5,
    [double]$VoiceStart = 5,
    [double]$VoiceSeconds = 12,
    [string[]]$AudioExtensions = @('.wav', '.m4a', '.mp3', '.flac', '.mp4', '.mkv', '.opus')
)

$ErrorActionPreference = 'Continue'

function Get-ToolPath {
    param([string]$Executable)
    $onPath = (Get-Command $Executable -ErrorAction SilentlyContinue).Source
    if ($onPath) { return $onPath }
    $machineWide = Join-Path 'C:\Program Files\FFmpeg\bin' $Executable
    if (Test-Path -LiteralPath $machineWide) { return $machineWide }
    return $null
}

function Get-AudioFiles {
    param([string]$Target, [string[]]$Extensions)
    if (Test-Path -LiteralPath $Target -PathType Container) {
        return @(Get-ChildItem -LiteralPath $Target -File | Where-Object { $_.Extension -in $Extensions })
    }
    return @(Get-Item -LiteralPath $Target)
}

function Get-AudioStreamInfo {
    param([string]$FFprobe, [string]$File)
    $json = & $FFprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels -show_entries format=duration -of json $File 2>$null | Out-String | ConvertFrom-Json
    if (-not $json.streams) { return $null }
    [pscustomobject]@{
        Codec = $json.streams[0].codec_name
        SampleRate = $json.streams[0].sample_rate
        Channels = $json.streams[0].channels
        Duration = [double]$json.format.duration
    }
}

function ConvertTo-Decibel {
    param($Match, [double]$Floor = -100)
    if (-not $Match) { return $null }
    $value = $Match.Matches[0].Groups[1].Value
    if ($value -eq '-inf') { return $Floor }
    [double]$value
}

function Measure-Levels {
    param([string]$FFmpeg, [string]$File, [string[]]$InputArgs = @(), [string]$Filter = 'anull')
    $output = & $FFmpeg -hide_banner -v info -i $File @InputArgs -af "$Filter,volumedetect" -f null NUL 2>&1
    [pscustomobject]@{
        Mean = ConvertTo-Decibel ($output | Select-String 'mean_volume:\s*(-?[\d.]+|-inf) dB' | Select-Object -First 1)
        Peak = ConvertTo-Decibel ($output | Select-String 'max_volume:\s*(-?[\d.]+|-inf) dB' | Select-Object -First 1)
    }
}

function Measure-Loudness {
    param([string]$FFmpeg, [string]$File)
    $output = & $FFmpeg -hide_banner -v info -i $File -af 'ebur128=peak=true' -f null NUL 2>&1
    $integrated = $output | Select-String 'I:\s*(-?[\d.]+|-inf) LUFS' | Select-Object -Last 1
    $range = $output | Select-String 'LRA:\s*(-?[\d.]+) LU' | Select-Object -Last 1
    $lufs = $null
    if ($integrated -and $integrated.Matches[0].Groups[1].Value -ne '-inf') {
        $lufs = [double]$integrated.Matches[0].Groups[1].Value
    }
    [pscustomobject]@{
        Lufs = $lufs
        Lra = if ($range) { [double]$range.Matches[0].Groups[1].Value } else { $null }
    }
}

function Measure-Bands {
    param([string]$FFmpeg, [string]$File, [string[]]$Segment)
    [pscustomobject]@{
        Body = (Measure-Levels -FFmpeg $FFmpeg -File $File -InputArgs $Segment -Filter 'lowpass=f=300').Mean
        Mid = (Measure-Levels -FFmpeg $FFmpeg -File $File -InputArgs $Segment -Filter 'highpass=f=300,lowpass=f=3000').Mean
        High = (Measure-Levels -FFmpeg $FFmpeg -File $File -InputArgs $Segment -Filter 'highpass=f=3000').Mean
    }
}

function New-AnalysisRow {
    param([string]$FFmpeg, [string]$FFprobe, [System.IO.FileInfo]$File, [string[]]$NoiseSegment, [string[]]$VoiceSegment)
    $info = Get-AudioStreamInfo -FFprobe $FFprobe -File $File.FullName
    if (-not $info) { return $null }

    $noise = (Measure-Levels -FFmpeg $FFmpeg -File $File.FullName -InputArgs $NoiseSegment).Mean
    $voice = Measure-Levels -FFmpeg $FFmpeg -File $File.FullName -InputArgs $VoiceSegment
    $loudness = Measure-Loudness -FFmpeg $FFmpeg -File $File.FullName
    $bands = Measure-Bands -FFmpeg $FFmpeg -File $File.FullName -Segment $VoiceSegment

    [pscustomobject]@{
        File = $File.Name
        Secs = [math]::Round($info.Duration, 1)
        Fmt = "$($info.Codec) $($info.SampleRate)Hz x$($info.Channels)"
        SnrDb = if ($null -ne $voice.Mean -and $null -ne $noise) { [math]::Round($voice.Mean - $noise, 1) } else { $null }
        NoiseDb = $noise
        VoiceDb = $voice.Mean
        PeakDb = $voice.Peak
        Lufs = $loudness.Lufs
        Lra = $loudness.Lra
        BodyDb = $bands.Body
        MidDb = $bands.Mid
        HighDb = $bands.High
    }
}

function Get-Verdict {
    param($Row)
    $notes = @()
    if ($null -ne $Row.SnrDb) {
        if ($Row.SnrDb -lt 3) { $notes += 'no silent lead-in - pattern not followed' }
        elseif ($Row.SnrDb -ge 30) { $notes += 'clean' }
        elseif ($Row.SnrDb -ge 20) { $notes += 'usable' }
        else { $notes += 'NOISY' }
    }
    if ($null -ne $Row.PeakDb -and $Row.PeakDb -gt -3) { $notes += 'near clipping' }
    if ($null -ne $Row.Lufs -and $Row.Lufs -lt -30) { $notes += 'too quiet' }
    if ($null -ne $Row.HighDb -and $null -ne $Row.MidDb -and ($Row.HighDb - $Row.MidDb) -gt 6) { $notes += 'harsh/sibilant' }
    if ($null -ne $Row.BodyDb -and $null -ne $Row.MidDb -and ($Row.BodyDb - $Row.MidDb) -gt 12) { $notes += 'boomy' }
    if (-not $notes) { $notes += 'balanced' }
    ($notes -join ', ')
}

$ffmpeg = Get-ToolPath 'ffmpeg.exe'
$ffprobe = Get-ToolPath 'ffprobe.exe'
if (-not $ffmpeg -or -not $ffprobe) {
    Write-Host 'ffmpeg/ffprobe not found' -ForegroundColor Red
    exit 1
}

$files = Get-AudioFiles -Target $Path -Extensions $AudioExtensions
if ($files.Count -eq 0) {
    Write-Host "No audio files found at $Path" -ForegroundColor Yellow
    exit 1
}

Write-Host "Analysing $($files.Count) file(s)`n" -ForegroundColor Cyan

$noiseSegment = @('-t', "$NoiseSeconds")
$voiceSegment = @('-ss', "$VoiceStart", '-t', "$VoiceSeconds")
$rows = foreach ($file in $files) {
    Write-Host "--- $($file.Name)" -ForegroundColor DarkGray
    $row = New-AnalysisRow -FFmpeg $ffmpeg -FFprobe $ffprobe -File $file -NoiseSegment $noiseSegment -VoiceSegment $voiceSegment
    if (-not $row) {
        Write-Warning "$($file.Name) has no audio stream"
        continue
    }
    $row | Add-Member -PassThru -NotePropertyName Verdict -NotePropertyValue (Get-Verdict $row)
}

$rows | Format-Table SnrDb, NoiseDb, VoiceDb, PeakDb, Lufs, Lra, BodyDb, MidDb, HighDb, Verdict -AutoSize
Write-Host 'SNR: >=30 clean, >=20 usable, <20 noisy; PeakDb above -3 is near clipping; Lufs below -30 is too quiet.'

exit 0
