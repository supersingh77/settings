$ErrorActionPreference = 'Stop'
$vdf = 'C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf'
$registered = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
if (Test-Path -LiteralPath $vdf) {
    $matches = Select-String -Path $vdf -Pattern '"path"\s+"(.+)"' -AllMatches
    foreach ($m in $matches) {
        foreach ($hit in $m.Matches) {
            [void]$registered.Add(($hit.Groups[1].Value -replace '\\\\', '\'))
        }
    }
}
$candidates = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($r in $registered) { [void]$candidates.Add($r) }
foreach ($drive in [System.IO.DriveInfo]::GetDrives()) {
    if (-not $drive.IsReady) { continue }
    $lib = Join-Path $drive.Name 'Games\SteamLibrary'
    if (Test-Path -LiteralPath $lib) { [void]$candidates.Add($lib) }
}
$rows = @(foreach ($path in ($candidates | Sort-Object)) {
    $appsDir = Join-Path $path 'steamapps'
    $apps = if (Test-Path -LiteralPath $appsDir) {
        @(Get-ChildItem -LiteralPath $appsDir -Filter 'appmanifest_*.acf' -ErrorAction SilentlyContinue).Count
    } else { 0 }
    [pscustomobject]@{
        path = $path
        registered = $registered.Contains($path)
        apps = $apps
    }
})
ConvertTo-Json -InputObject $rows -Compress
