[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Video,
    [Parameter(Mandatory)][string]$Audio,
    [string]$Out,
    [string]$Bitrate = '192k',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$CopyableAudioCodecs = @('aac', 'mp3', 'ac3', 'eac3', 'alac')

function Get-ToolPath {
    param([string]$Name, [string]$Executable)
    $onPath = (Get-Command $Executable -ErrorAction SilentlyContinue).Source
    if ($onPath) { return $onPath }
    $machineWide = Join-Path 'C:\Program Files\FFmpeg\bin' $Executable
    if (Test-Path -LiteralPath $machineWide) { return $machineWide }
    throw "$Name not found. Install FFmpeg or add it to PATH."
}

function Get-StreamCodec {
    param([string]$FFprobe, [string]$File, [string]$StreamSelector)
    $json = & $FFprobe -hide_banner -v error -select_streams $StreamSelector -show_entries stream=codec_name -of json $File
    if ($LASTEXITCODE -ne 0) { throw "ffprobe failed on $File" }
    $streams = ($json | ConvertFrom-Json).streams
    if (-not $streams) { return $null }
    $streams[0].codec_name
}

function Get-AudioArguments {
    param([string]$Codec, [string]$Bitrate)
    if ($CopyableAudioCodecs -contains $Codec) { return @('-c:a', 'copy') }
    @('-c:a', 'aac', '-b:a', $Bitrate)
}

function Get-StreamMd5 {
    param([string]$FFmpeg, [string]$File, [string]$Map)
    $output = & $FFmpeg -hide_banner -v error -i $File -map $Map -c copy -f md5 -
    if ($LASTEXITCODE -ne 0) { throw "ffmpeg md5 failed on $File" }
    ($output | Select-String 'MD5=').ToString().Trim() -replace '^MD5=', ''
}

$ffmpeg = Get-ToolPath -Name 'ffmpeg' -Executable 'ffmpeg.exe'
$ffprobe = Get-ToolPath -Name 'ffprobe' -Executable 'ffprobe.exe'

foreach ($path in @($Video, $Audio)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Not found: $path" }
}
$videoPath = (Resolve-Path -LiteralPath $Video).ProviderPath
$audioPath = (Resolve-Path -LiteralPath $Audio).ProviderPath

if (-not $Out) {
    $outDirectory = Split-Path -Parent $videoPath
    $outBase = [IO.Path]::GetFileNameWithoutExtension($videoPath)
    $Out = Join-Path $outDirectory "$outBase (cleaned).mp4"
}
if (Test-Path -LiteralPath $Out) {
    $outResolved = (Resolve-Path -LiteralPath $Out).ProviderPath
    if ($outResolved -eq $videoPath) { throw 'Output path would overwrite the source video.' }
}

$videoCodec = Get-StreamCodec -FFprobe $ffprobe -File $videoPath -StreamSelector 'v:0'
if (-not $videoCodec) { throw "No video stream found in $videoPath" }

$audioCodec = Get-StreamCodec -FFprobe $ffprobe -File $audioPath -StreamSelector 'a:0'
$audioArguments = Get-AudioArguments -Codec $audioCodec -Bitrate $Bitrate
$audioAction = if ($CopyableAudioCodecs -contains $audioCodec) { 'copy' } else { "aac $Bitrate (transcode)" }

Write-Host "video : $videoCodec (copy)" -ForegroundColor Cyan
Write-Host "audio : $audioCodec -> $audioAction" -ForegroundColor Cyan
Write-Host "out   : $Out"

if ($DryRun) {
    Write-Host "`nDry run - would remux and write $Out. Nothing changed." -ForegroundColor Yellow
    exit 0
}

& $ffmpeg -hide_banner -y -i $videoPath -i $audioPath `
    -map 0:v:0 -map 1:a:0 -c:v copy @audioArguments `
    -map_metadata 0 -movflags +faststart $Out
if ($LASTEXITCODE -ne 0) { throw "ffmpeg muxing failed with exit code $LASTEXITCODE" }

Write-Host "`nVerifying video packets were copied, not re-encoded..." -ForegroundColor Cyan
$sourceMd5 = Get-StreamMd5 -FFmpeg $ffmpeg -File $videoPath -Map '0:v:0'
$outputMd5 = Get-StreamMd5 -FFmpeg $ffmpeg -File $Out -Map '0:v:0'
if ($sourceMd5 -eq $outputMd5) {
    Write-Host "OK  video stream bit-identical ($outputMd5)" -ForegroundColor Green
} else {
    Write-Warning "Video packet MD5 differs: source=$sourceMd5 output=$outputMd5"
}

& $ffprobe -hide_banner -v error -show_entries stream=index,codec_type,codec_name,width,height,r_frame_rate,channels,sample_rate -show_entries format=duration,size -of default=nw=1 $Out
Write-Host "`nDone: $Out" -ForegroundColor Green
exit 0
