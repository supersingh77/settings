$ErrorActionPreference = 'Stop'

function Read-Ini([string]$path) {
    $map = @{}
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $map }
    $section = ''
    foreach ($line in [System.IO.File]::ReadAllLines($path)) {
        $text = $line.Trim()
        if ($text -eq '' -or $text.StartsWith(';')) { continue }
        if ($text.StartsWith('[') -and $text.EndsWith(']')) {
            $section = $text.Substring(1, $text.Length - 2)
            continue
        }
        $eq = $text.IndexOf('=')
        if ($eq -le 0) { continue }
        $key = "$section/" + $text.Substring(0, $eq).Trim()
        $map[$key] = $text.Substring($eq + 1).Trim() -replace '\\\\', '\'
    }
    return $map
}

function Add-IniValue($out, [hashtable]$ini, [string]$section, [string]$key) {
    $name = "$section/$key"
    if ($ini.ContainsKey($name) -and $ini[$name] -ne '') { $out[$key] = $ini[$name] }
}

function Pick([hashtable]$ini, [string]$section, [string[]]$keys) {
    $out = [ordered]@{}
    foreach ($key in $keys) { Add-IniValue $out $ini $section $key }
    return [pscustomobject]$out
}

$configRoot = Join-Path $env:APPDATA 'obs-studio'
$globals = Read-Ini (Join-Path $configRoot 'global.ini')
$profileRoot = Join-Path $configRoot 'basic\profiles'
$profiles = @(Get-ChildItem -LiteralPath $profileRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'basic.ini') -PathType Leaf })

$wanted = ''
foreach ($name in @('Basic/Profile', 'Basic/ProfileDir')) {
    if ($globals.ContainsKey($name) -and $globals[$name] -ne '') { $wanted = $globals[$name]; break }
}
$chosen = $null
if ($wanted -ne '') { $chosen = $profiles | Where-Object { $_.Name -eq $wanted } | Select-Object -First 1 }
if (-not $chosen -and $profiles.Count -eq 1) { $chosen = $profiles[0] }
if (-not $chosen -and $profiles.Count -gt 1) {
    $chosen = $profiles | Sort-Object { (Get-Item -LiteralPath (Join-Path $_.FullName 'basic.ini')).LastWriteTimeUtc } -Descending | Select-Object -First 1
}
if (-not $chosen) { [pscustomobject]@{} | ConvertTo-Json -Compress; exit 0 }

$ini = Read-Ini (Join-Path $chosen.FullName 'basic.ini')
$advanced = [ordered]@{}
foreach ($key in @('RecType', 'RecFormat2', 'RecEncoder', 'RecFilePath', 'RecTracks', 'Encoder')) {
    Add-IniValue $advanced $ini 'AdvOut' $key
}
$trackKeys = @($ini.Keys | Where-Object { $_ -match '^AdvOut/Track\d+(Bitrate|Name)$' } | ForEach-Object { ($_ -split '/', 2)[1] } | Sort-Object)
foreach ($key in $trackKeys) { Add-IniValue $advanced $ini 'AdvOut' $key }

[pscustomobject]@{
    profile = $chosen.Name
    video = (Pick $ini 'Video' @('BaseCX', 'BaseCY', 'OutputCX', 'OutputCY', 'FPSType', 'FPSCommon', 'FPSInt', 'FPSNum', 'FPSDen', 'ScaleType', 'ColorFormat', 'ColorSpace', 'ColorRange'))
    output = (Pick $ini 'Output' @('Mode'))
    advanced = [pscustomobject]$advanced
    audio = (Pick $ini 'Audio' @('SampleRate', 'ChannelSetup'))
} | ConvertTo-Json -Compress -Depth 4
