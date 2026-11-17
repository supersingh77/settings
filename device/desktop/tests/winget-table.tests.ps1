. (Join-Path $TestRepoRoot 'device\desktop\lib\winget-table.ps1')

function Get-WingetTableFixture {
    param([string[]]$Rows)
    $header = ('{0,-34}{1,-30}{2,-14}{3,-14}{4}' -f 'Name', 'Id', 'Version', 'Available', 'Source')
    $rule = '-' * 100
    @($header, $rule) + @($Rows)
}

function New-WingetRow([string]$Name, [string]$Id, [string]$Version, [string]$Available) {
    '{0,-34}{1,-30}{2,-14}{3,-14}{4}' -f $Name, $Id, $Version, $Available, 'winget'
}

function Test-ParsesTwoRows {
    $lines = Get-WingetTableFixture -Rows @(
        (New-WingetRow 'Git' 'Git.Git' '2.55.0' '2.56.0'),
        (New-WingetRow 'Microsoft.PowerShell' 'Microsoft.PowerShell' '7.5.2' '7.6.10')
    )
    $rows = @(ConvertFrom-WingetUpgradeTable -Lines $lines)

    Assert-Equal 2 $rows.Count 'both package rows must parse'
    Assert-Equal 'Git' $rows[0].Name 'name column'
    Assert-Equal 'Git.Git' $rows[0].Id 'id column'
    Assert-Equal '2.55.0' $rows[0].Version 'installed version column'
    Assert-Equal '2.56.0' $rows[0].Available 'available version column'
    Assert-Equal 'winget' $rows[0].Source 'source column'
    Assert-Equal 'Microsoft.PowerShell' $rows[1].Id 'a dotted id must survive'
}

function Test-ReturnsEmptyWhenNoHeader {
    $rows = @(ConvertFrom-WingetUpgradeTable -Lines @('winget: no applicable upgrade found', '', 'x'))
    Assert-Equal 0 $rows.Count 'unrecognised output must produce no rows, never an exception'
}

function Test-StopsAtTrailingText {
    $lines = Get-WingetTableFixture -Rows @(
        (New-WingetRow 'Git' 'Git.Git' '2.55.0' '2.56.0')
    )
    $rows = @(ConvertFrom-WingetUpgradeTable -Lines (@($lines) + @('', '2 upgrades available', '')))
    Assert-Equal 1 $rows.Count 'text after the table must not become a row'
}

function Test-SkipsSeparatorAndBlankLines {
    $header = ('{0,-34}{1,-30}{2,-14}{3,-14}{4}' -f 'Name', 'Id', 'Version', 'Available', 'Source')
    $lines = @($header, ('-' * 100), '', (New-WingetRow 'Git' 'Git.Git' '2.55.0' '2.56.0'))
    $rows = @(ConvertFrom-WingetUpgradeTable -Lines $lines)
    Assert-Equal 1 $rows.Count 'separator and blank lines are not rows'
}

function Test-AcceptsEmptyInput {
    $rows = @(ConvertFrom-WingetUpgradeTable -Lines @(''))
    Assert-Equal 0 $rows.Count 'empty output must not throw'
}
