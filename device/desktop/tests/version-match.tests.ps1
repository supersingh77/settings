. (Join-Path $TestRepoRoot 'device\desktop\lib\version-match.ps1')

function New-InstalledApp([string]$Name, [string]$Version) {
    [pscustomobject]@{ DisplayName = $Name; DisplayVersion = $Version }
}

function Test-ClaimThatMatchesExactly {
    $installed = @(New-InstalledApp 'Git' '2.56.0.4')
    Assert-Equal $null (Get-VersionMismatch -Name 'Git' -Claimed '2.56.0.4' -Installed $installed) 'an exact match must pass'
}

function Test-ClaimShorterThanInstalledVersionPasses {
    $installed = @(New-InstalledApp 'PowerShell 7-x64' '7.6.10.0')
    Assert-Equal $null (Get-VersionMismatch -Name 'PowerShell 7' -Claimed '7.6.10' -Installed $installed) '7.6.10 is a prefix of 7.6.10.0'
}

function Test-SuffixedNameMatches {
    $installed = @(New-InstalledApp 'PotPlayer-64 bit' '26.10.21.0')
    Assert-Equal $null (Get-VersionMismatch -Name 'PotPlayer' -Claimed '26.10.21.0' -Installed $installed) 'a hyphenated vendor name still resolves'
}

function Test-MismatchIsReported {
    $installed = @(New-InstalledApp 'Radmin VPN' '2.1.2')
    $problem = Get-VersionMismatch -Name 'Radmin VPN' -Claimed '2.1.4952.2' -Installed $installed
    Assert-True ($problem -match '2\.1\.4952\.2') 'the claim must be in the message'
    Assert-True ($problem -match '2\.1\.2') 'the installed version must be in the message'
}

function Test-ExactNameDoesNotPoachALongerOne {
    $installed = @(New-InstalledApp 'GitHub CLI' '2.104.0', (New-InstalledApp 'Git' '2.56.0.4'))
    Assert-Equal $null (Get-VersionMismatch -Name 'Git' -Claimed '2.56.0.4' -Installed $installed) 'Git must not compare against GitHub CLI'
}

function Test-UncheckableClaimsReturnNull {
    $installed = @(New-InstalledApp 'Something' '1.0')
    Assert-Equal $null (Get-VersionMismatch -Name 'Something' -Claimed '_needs-review_' -Installed $installed) 'a placeholder is not a version'
    Assert-Equal $null (Get-VersionMismatch -Name 'PXN SimRacing' -Claimed '1.6.8.0 app (ARP shows 1.2.0.0)' -Installed $installed) 'a cell that names ARP is explaining itself'
    Assert-Equal $null (Get-VersionMismatch -Name 'Absent App' -Claimed '9.9.9' -Installed $installed) 'no installed entry means no claim to check'
}

function Test-EntryWithoutVersionIsSkipped {
    $installed = @(New-InstalledApp 'Riot Vanguard' '')
    Assert-Equal $null (Get-VersionMismatch -Name 'Riot Vanguard' -Claimed '1.19.2-23' -Installed $installed) 'an empty ARP version cannot contradict anything'
}
