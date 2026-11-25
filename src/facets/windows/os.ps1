$ErrorActionPreference = 'Stop'
$cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
[pscustomobject]@{
    displayVersion = [string]$cv.DisplayVersion
    build = if ($cv.CurrentBuild) { "$($cv.CurrentBuild).$($cv.UBR)" } else { '' }
    productName = [string]$cv.ProductName
} | ConvertTo-Json -Compress
