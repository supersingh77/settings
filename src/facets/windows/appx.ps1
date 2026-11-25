$ErrorActionPreference = 'Stop'
$repo = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages'
$rows = @(Get-ChildItem -LiteralPath $repo -ErrorAction SilentlyContinue | ForEach-Object {
    $parts = $_.PSChildName -split '_'
    if ($parts.Count -ge 2) {
        [pscustomobject]@{
            name = $parts[0]
            version = $parts[1]
        }
    }
})
ConvertTo-Json -InputObject $rows -Compress
