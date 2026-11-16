[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'

$WriteCommandPattern = 'Set-ItemProperty|New-ItemProperty|Remove-Item|Set-Content|New-Item|Add-AppxPackage|Start-Process|Copy-Item'
$CommentAllowPattern = '^#Requires'

function Get-ScriptFiles([string]$Root) {
    Get-ChildItem -Path $Root -Recurse -Filter '*.ps1' -File |
        Where-Object { $_.FullName -notmatch '\\\.git\\' }
}

function Get-DeclaredJson([string]$Root) {
    Get-ChildItem -Path $Root -Recurse -Filter '*.json' -File |
        Where-Object { $_.FullName -match '\\declared\\' -and $_.FullName -notmatch '\\\.git\\' }
}

function Test-Parses([System.IO.FileInfo]$File) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count -eq 0) { return $null }
    ($errors | ForEach-Object { "$($_.Extent.StartLineNumber): $($_.Message)" }) -join '; '
}

function Get-CommentViolations([System.IO.FileInfo]$File) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$tokens, [ref]$errors)
    $tokens |
        Where-Object { $_.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment } |
        Where-Object { $_.Text -notmatch $CommentAllowPattern } |
        ForEach-Object { $_.Extent.StartLineNumber }
}

function Test-JsonFile([System.IO.FileInfo]$File) {
    try { [void](Get-Content -LiteralPath $File.FullName -Raw | ConvertFrom-Json); return $null }
    catch { return $_.Exception.Message }
}

function Test-DryRunContract([System.IO.FileInfo]$File) {
    $text = Get-Content -LiteralPath $File.FullName -Raw
    if ($text -notmatch $WriteCommandPattern) { return $null }
    if ($text -match '\$DryRun') { return $null }
    'writes but exposes no -DryRun switch'
}

function Test-ReadmeIndex([System.IO.FileInfo]$File) {
    $readme = Join-Path $File.DirectoryName 'README.md'
    if (-not (Test-Path $readme)) { return 'no README.md in this folder' }
    $text = Get-Content -LiteralPath $readme -Raw
    if ($text -notmatch [regex]::Escape($File.Name)) { return "not listed in $($File.Directory.Name)\README.md" }
    $null
}

function New-Result([string]$Rule, [string]$Target, [string]$Problem, [string]$Severity) {
    [pscustomobject]@{ Rule = $Rule; Target = $Target; Severity = $Severity; Detail = $Problem }
}

$results = [System.Collections.Generic.List[object]]::new()
$scripts = Get-ScriptFiles $RepoRoot
$json = Get-DeclaredJson $RepoRoot
$softSeverity = if ($Strict) { 'FAIL' } else { 'WARN' }

foreach ($file in $scripts) {
    $relative = $file.FullName.Substring($RepoRoot.Length).TrimStart('\')

    $parseError = Test-Parses $file
    if ($parseError) { $results.Add((New-Result 'parses' $relative $parseError 'FAIL')) }

    $commentLines = @(Get-CommentViolations $file)
    if ($commentLines.Count -gt 0) {
        $results.Add((New-Result 'no-comments' $relative ("lines " + ($commentLines -join ', ')) $softSeverity))
    }

    $dryRunProblem = Test-DryRunContract $file
    if ($dryRunProblem) { $results.Add((New-Result 'dry-run' $relative $dryRunProblem $softSeverity)) }

    $readmeProblem = Test-ReadmeIndex $file
    if ($readmeProblem) { $results.Add((New-Result 'indexed' $relative $readmeProblem $softSeverity)) }
}

foreach ($file in $json) {
    $relative = $file.FullName.Substring($RepoRoot.Length).TrimStart('\')
    $jsonProblem = Test-JsonFile $file
    if ($jsonProblem) { $results.Add((New-Result 'json-valid' $relative $jsonProblem 'FAIL')) }
}

$failed = @($results | Where-Object Severity -eq 'FAIL')
$warned = @($results | Where-Object Severity -eq 'WARN')

Write-Host "verify  root=$RepoRoot  scripts=$($scripts.Count)  json=$($json.Count)  strict=$Strict`n" -ForegroundColor Cyan

if ($results.Count -eq 0) {
    Write-Host 'all checks passed' -ForegroundColor Green
} else {
    $results | Format-Table -AutoSize -Wrap
}

Write-Host ("{0} failure(s), {1} warning(s)" -f $failed.Count, $warned.Count) -ForegroundColor $(if ($failed.Count) { 'Red' } else { 'Green' })
if ($failed.Count -gt 0) { exit 1 }
exit 0
