$ErrorActionPreference = 'Stop'
$roots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$rows = @(foreach ($root in $roots) {
    Get-ItemProperty $root -ErrorAction SilentlyContinue |
        Where-Object DisplayName |
        ForEach-Object {
            [pscustomobject]@{
                name = [string]$_.DisplayName
                version = if ($null -ne $_.DisplayVersion) { [string]$_.DisplayVersion } else { '' }
            }
        }
})
ConvertTo-Json -InputObject $rows -Compress
