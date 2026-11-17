[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
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

function Get-RepoProse([string]$Root) {
    $files = Get-ChildItem -Path $Root -Recurse -File -Include '*.ps1', '*.md' |
        Where-Object { $_.FullName -notmatch '\\\.git\\' }
    ($files | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
}

function Get-ScriptFacts([System.IO.FileInfo]$File) {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$tokens, [ref]$errors)
    [pscustomobject]@{
        Text     = [string](Get-Content -LiteralPath $File.FullName -Raw)
        Errors   = @($errors)
        Comments = @($tokens | Where-Object { $_.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment })
        HasExit  = @($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ExitStatementAst] }, $true)).Count -gt 0
        Globals  = @($ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
            $args[0].VariablePath.UserPath -like 'global:*'
        }, $true))
    }
}

function Test-JsonFile([System.IO.FileInfo]$File) {
    try { [void](Get-Content -LiteralPath $File.FullName -Raw | ConvertFrom-Json); return $null }
    catch { return $_.Exception.Message }
}

function Test-DryRunContract([string]$Text) {
    if ($Text -notmatch $WriteCommandPattern) { return $null }
    if ($Text -match '\$DryRun') { return $null }
    'writes but exposes no -DryRun switch'
}

function Test-ExplicitExit([string]$Text, [bool]$HasExit) {
    if ($Text -notmatch $WriteCommandPattern) { return $null }
    if ($HasExit) { return $null }
    'writes but never sets an explicit exit code'
}

function Test-GlobalState($Globals) {
    if (@($Globals).Count -eq 0) { return $null }
    'reads or writes global state on line(s) ' + ((@($Globals) | ForEach-Object { $_.Extent.StartLineNumber }) -join ', ')
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
$scripts = @(Get-ScriptFiles $RepoRoot)
$json = @(Get-DeclaredJson $RepoRoot)
$prose = Get-RepoProse $RepoRoot

foreach ($file in $scripts) {
    $relative = $file.FullName.Substring($RepoRoot.Length).TrimStart('\')
    $facts = Get-ScriptFacts $file

    if ($facts.Errors.Count -gt 0) {
        $message = ($facts.Errors | ForEach-Object { "$($_.Extent.StartLineNumber): $($_.Message)" }) -join '; '
        $results.Add((New-Result 'parses' $relative $message 'FAIL'))
    }

    $commentLines = @($facts.Comments | Where-Object { $_.Text -notmatch $CommentAllowPattern } |
        ForEach-Object { $_.Extent.StartLineNumber })
    if ($commentLines.Count -gt 0) {
        $results.Add((New-Result 'no-comments' $relative ("lines " + ($commentLines -join ', ')) 'FAIL'))
    }

    $dryRunProblem = Test-DryRunContract $facts.Text
    if ($dryRunProblem) { $results.Add((New-Result 'dry-run' $relative $dryRunProblem 'FAIL')) }

    $exitProblem = Test-ExplicitExit $facts.Text $facts.HasExit
    if ($exitProblem) { $results.Add((New-Result 'explicit-exit' $relative $exitProblem 'FAIL')) }

    $globalProblem = Test-GlobalState $facts.Globals
    if ($globalProblem) { $results.Add((New-Result 'no-global' $relative $globalProblem 'FAIL')) }

    $readmeProblem = Test-ReadmeIndex $file
    if ($readmeProblem) { $results.Add((New-Result 'indexed' $relative $readmeProblem 'FAIL')) }
}

foreach ($file in $json) {
    $relative = $file.FullName.Substring($RepoRoot.Length).TrimStart('\')
    $jsonProblem = Test-JsonFile $file
    if ($jsonProblem) { $results.Add((New-Result 'json-valid' $relative $jsonProblem 'FAIL')) }
    if ($prose -notmatch [regex]::Escape($file.Name)) {
        $results.Add((New-Result 'declared-referenced' $relative 'no script or document names this file' 'FAIL'))
    }
}

$failed = @($results | Where-Object Severity -eq 'FAIL')
$warned = @($results | Where-Object Severity -eq 'WARN')

Write-Host "verify  root=$RepoRoot  scripts=$($scripts.Count)  json=$($json.Count)`n" -ForegroundColor Cyan

if ($results.Count -eq 0) {
    Write-Host 'all checks passed' -ForegroundColor Green
} else {
    $results | Format-Table -AutoSize -Wrap
}

Write-Host ("{0} failure(s), {1} warning(s)" -f $failed.Count, $warned.Count) -ForegroundColor $(if ($failed.Count) { 'Red' } else { 'Green' })
if ($failed.Count -gt 0) { exit 1 }
exit 0
