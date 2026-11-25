$ErrorActionPreference = 'Stop'

$dir = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
$shell = New-Object -ComObject WScript.Shell
$rows = @(Get-ChildItem -LiteralPath $dir -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -eq '.lnk' } |
    ForEach-Object {
        $link = $shell.CreateShortcut($_.FullName)
        [pscustomobject]@{
            name = $_.BaseName
            target = [string]$link.TargetPath
            arguments = [string]$link.Arguments
        }
    })
ConvertTo-Json -InputObject $rows -Compress
