$ErrorActionPreference = 'Stop'
$out = & pnputil.exe /enum-devices /problem 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
[pscustomobject]@{ text = $out } | ConvertTo-Json -Compress
