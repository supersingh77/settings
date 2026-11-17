param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'

. (Join-Path $PSScriptRoot '..\lib\winget-table.ps1')

$BOLD   = "`e[1m"
$GREEN  = "`e[32m"
$YELLOW = "`e[33m"
$CYAN   = "`e[36m"
$RESET  = "`e[0m"

function info    { Write-Host "${CYAN}[info]${RESET}  $($args -join ' ')" }
function success { Write-Host "${GREEN}[ok]${RESET}    $($args -join ' ')" }
function warn    { Write-Host "${YELLOW}[warn]${RESET}  $($args -join ' ')" }
function step    { Write-Host "`n${BOLD}--- $($args -join ' ') ---${RESET}" }

$excludedIds = @('Microsoft.PowerShell')
$wingetNothingToDo = -1978335189
$wingetNoUpgradesPattern = 'No installed package|No applicable upgrade|No packages'

function Invoke-Update {
    param([string]$Log)

    $winget = (Get-Command winget.exe -ErrorAction SilentlyContinue).Source
    if (-not $winget) {
        warn 'winget not found. Install/repair App Installer first.'
        return 1
    }

    step 'Refreshing winget sources'
    & $winget source update 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) {
        warn "Source update returned $LASTEXITCODE; continuing."
    }

    $listArguments = @('upgrade', '--include-unknown', '--accept-source-agreements')

    step 'Available upgrades'
    $listing = & $winget @listArguments 2>&1 | Out-String
    $listingExit = $LASTEXITCODE
    Write-Host $listing

    if ($DryRun) {
        info 'Dry run complete - no packages changed.'
        return 0
    }

    $rows = @(ConvertFrom-WingetUpgradeTable -Lines ($listing -split "`r?`n"))
    if ($rows.Count -eq 0) {
        if ($listingExit -eq $wingetNothingToDo -or $listing -match $wingetNoUpgradesPattern) {
            info 'Nothing to upgrade.'
            return 0
        }
        warn 'Could not read a single package from the winget listing above.'
        warn 'The table format may have changed; nothing was upgraded and the exit code is 1 on purpose.'
        return 1
    }

    $targets = @($rows | Where-Object { $_.Id -notin $excludedIds })
    $done = @()
    $failed = @()

    step 'Upgrading packages'
    info 'UAC prompts may appear per package. Some packages may need manual updates.'

    if ($targets.Count -eq 0) {
        info 'Nothing to upgrade.'
    }
    else {
        $n = 0
        foreach ($target in $targets) {
            $n++
            Write-Host "`n${BOLD}($n/$($targets.Count))${RESET} $($target.Name) [$($target.Id)] $($target.Version) -> $($target.Available)"
            & $winget upgrade --id $target.Id --exact --silent `
                --accept-package-agreements --accept-source-agreements
            $code = $LASTEXITCODE

            if ($code -eq 0 -or $code -eq $wingetNothingToDo) {
                $done += $target.Id
                success "$($target.Id) upgraded"
            }
            else {
                $failed += [pscustomobject]@{ Id = $target.Id; Exit = $code }
                warn "$($target.Id) exited $code - continuing with the rest"
            }
        }

        if ($failed.Count -eq 0) {
            success "All $($done.Count) package(s) upgraded."
        }
        else {
            warn "$($done.Count) upgraded, $($failed.Count) failed:"
            $failed | ForEach-Object { Write-Host "        $($_.Id) (exit $($_.Exit))" }
        }
    }

    step 'Remaining upgrades'
    $remaining = & $winget @listArguments 2>&1 | Out-String
    $remainingExit = $LASTEXITCODE
    Write-Host $remaining

    $psPending = ($remaining -split "`r?`n" |
        Where-Object { $_ -match 'Microsoft\.PowerShell\b' }).Count -gt 0
    if ($psPending) {
        step 'PowerShell is still pending'
        warn 'The PowerShell MSI cannot run inside the session it replaces.'
        warn 'Windows Installer closes pwsh mid-install and rolls back with 1603.'
        info 'Run this from Command Prompt (Win+R -> cmd), not from PowerShell:'
        Write-Host "`n    winget upgrade --id Microsoft.PowerShell --exact --accept-package-agreements --accept-source-agreements`n"
        info 'Expect every open PowerShell window to close during the install - that is the installer, not a crash.'
        info "Then re-run 'update' to confirm nothing else is left."
    }

    if ($remainingExit -ne 0 -and $remainingExit -ne $wingetNothingToDo) {
        warn "Final upgrade check exited $remainingExit."
    }
    if ($Log) { info "Log: $Log" } else { info 'Log: none - the transcript could not be started' }

    if ($failed.Count -gt 0) { return 1 }
    return 0
}

$logDir = Join-Path $env:LOCALAPPDATA 'DesktopMaintenance\logs'
$log = $null
$transcribing = $false
try {
    New-Item -ItemType Directory -Path $logDir -Force -ErrorAction Stop | Out-Null
    $log = Join-Path $logDir ("update-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Start-Transcript -Path $log -Force -ErrorAction Stop | Out-Null
    $transcribing = $true
}
catch {
    $log = $null
    warn 'Transcript unavailable - the log folder is not writable from this session.'
}

$exitCode = 1
try {
    $exitCode = Invoke-Update -Log $log
}
finally {
    if ($transcribing) { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null }
}

exit $exitCode
