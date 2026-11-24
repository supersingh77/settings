$ErrorActionPreference = 'Stop'
$tmp = [System.IO.Path]::GetTempFileName()
try {
    & winget.exe export -o $tmp --include-versions --accept-source-agreements 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Get-Content -LiteralPath $tmp -Raw -Encoding UTF8
}
finally {
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}
