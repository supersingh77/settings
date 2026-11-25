$ErrorActionPreference = 'Stop'
$targets = @(
    @{ name = 'ffmpeg'; path = 'C:\Program Files\FFmpeg\bin\ffmpeg.exe'; args = @('-version'); pattern = '^ffmpeg version ([^\s]+)' }
)
$rows = @(foreach ($t in $targets) {
    if (-not (Test-Path -LiteralPath $t.path)) { continue }
    $ver = ''
    try {
        $out = & $t.path @($t.args) 2>$null
        $line = [string]@($out)[0]
        if ($line -match $t.pattern) { $ver = $Matches[1] }
    } catch { }
    if (-not $ver) {
        try { $ver = [string](Get-Item -LiteralPath $t.path -ErrorAction Stop).VersionInfo.FileVersion } catch { }
    }
    [pscustomobject]@{
        name = $t.name
        path = $t.path
        version = $ver
    }
})
ConvertTo-Json -InputObject $rows -Compress
