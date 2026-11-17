[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$Filter = '*'
)

$ErrorActionPreference = 'Stop'

$TestRepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$script:fixtures = [System.Collections.Generic.List[string]]::new()

function Assert-Equal($Expected, $Actual, [string]$Because) {
    if ($Expected -ne $Actual) { throw "expected [$Expected], got [$Actual] - $Because" }
}

function Assert-True([bool]$Condition, [string]$Because) {
    if (-not $Condition) { throw "expected true - $Because" }
}

function Assert-False([bool]$Condition, [string]$Because) {
    if ($Condition) { throw "expected false - $Because" }
}

function New-FixtureDirectory([string]$Prefix) {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ('settings-test-' + $Prefix + '-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    $script:fixtures.Add($path)
    return $path
}

function New-FixtureFile([string]$Directory, [string]$Name, [string]$Content) {
    $path = Join-Path $Directory $Name
    $parent = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Set-Content -LiteralPath $path -Value $Content -Encoding UTF8
    return $path
}

function Get-FFmpegOrNull {
    $onPath = (Get-Command ffmpeg.exe -ErrorAction SilentlyContinue).Source
    if ($onPath) { return $onPath }
    $machineWide = 'C:\Program Files\FFmpeg\bin\ffmpeg.exe'
    if (Test-Path -LiteralPath $machineWide) { return $machineWide }
    return $null
}

function Invoke-Script {
    param([string]$Path, [string[]]$Arguments)
    $output = & pwsh -NoProfile -File $Path @Arguments 2>&1 | Out-String
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output }
}

function Remove-Fixtures {
    foreach ($fixture in $script:fixtures) {
        if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

$testFiles = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.tests.ps1' -File |
    Where-Object { $_.Name -like $Filter } |
    Sort-Object Name)

if ($DryRun) {
    Write-Host "dry run - test files under $PSScriptRoot : $($testFiles.Count)" -ForegroundColor Yellow
    foreach ($file in $testFiles) { Write-Host "  $($file.Name)" }
    Write-Host 'Nothing was executed and no fixture was created.'
    exit 0
}

$results = [System.Collections.Generic.List[object]]::new()

try {
    foreach ($file in $testFiles) {
        . $file.FullName
        $added = @(Get-ChildItem Function:\ | Where-Object {
            $_.Name -like 'Test-*' -and $_.ScriptBlock.File -eq $file.FullName
        })

        foreach ($name in $added) {
            $label = "$($file.Name)::$($name.Name)"
            try {
                & $name.Name
                $results.Add([pscustomobject]@{ Test = $label; Result = 'PASS'; Detail = '' })
            } catch {
                $results.Add([pscustomobject]@{ Test = $label; Result = 'FAIL'; Detail = $_.Exception.Message })
            }
        }
    }
}
finally {
    Remove-Fixtures
}

$passed = @($results | Where-Object Result -eq 'PASS')
$failed = @($results | Where-Object Result -eq 'FAIL')

Write-Host "`ntests  root=$TestRepoRoot  files=$($testFiles.Count)  tests=$($results.Count)`n" -ForegroundColor Cyan

foreach ($result in $results) {
    $colour = if ($result.Result -eq 'PASS') { 'Green' } else { 'Red' }
    Write-Host ("  {0}  {1}" -f $result.Result, $result.Test) -ForegroundColor $colour
    if ($result.Detail) { Write-Host ("        {0}" -f $result.Detail) -ForegroundColor Red }
}

Write-Host ("`n{0} passed, {1} failed" -f $passed.Count, $failed.Count) -ForegroundColor $(if ($failed.Count) { 'Red' } else { 'Green' })
if ($failed.Count -gt 0) { exit 1 }
exit 0
