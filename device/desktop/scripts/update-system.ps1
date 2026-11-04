# =============================================================================
# update-system.ps1 - Update installed apps with winget
#
# Refreshes winget sources, lists available upgrades, then upgrades everything
# it can, one package at a time. Some packages (MSIX/Store apps, vendor
# installers) may still need a manual update or a UAC prompt.
#
# PowerShell itself is excluded from the upgrade pass on purpose. Its MSI has
# to replace the binaries of the running engine, so Windows Installer shuts
# this pwsh down mid-install and the transaction rolls back with MSI 1603
# (seen 24 Oct, 1 Nov, 3 Nov 2026). The run ends by handing that one upgrade
# off to Command Prompt, which survives the shutdown.
#
# Note: winget 1.29 has no --exclude for 'upgrade --all', so the target list is
# parsed from 'winget upgrade' and driven per package. That also means one
# failing package no longer aborts the rest of the run.
#
# Usage:
#   pwsh device/desktop/scripts/update-system.ps1
#   pwsh device/desktop/scripts/update-system.ps1 -DryRun
# =============================================================================

param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'

$BOLD   = "`e[1m"
$GREEN  = "`e[32m"
$YELLOW = "`e[33m"
$CYAN   = "`e[36m"
$RED    = "`e[31m"
$RESET  = "`e[0m"

function info    { Write-Host "${CYAN}[info]${RESET}  $($args -join ' ')" }
function success { Write-Host "${GREEN}[ok]${RESET}    $($args -join ' ')" }
function warn    { Write-Host "${YELLOW}[warn]${RESET}  $($args -join ' ')" }
function step    { Write-Host "`n${BOLD}--- $($args -join ' ') ---${RESET}" }

# Packages that must never be upgraded from inside this session.
# Microsoft.PowerShell: the MSI replaces the binaries of the pwsh running this
# script; the installer shuts it down and rolls back (1603) every time.
$excludedIds = @('Microsoft.PowerShell')

# 0x8A15002B - winget found nothing applicable; not an error for this script.
$wingetNothingToDo = -1978335189

# winget prints its upgrade list as a fixed-width table. The column start
# offsets come from the header line, so long package names do not shift it.
function ConvertFrom-WingetUpgradeTable {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $rows = @()
    $headerIndex = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^Name\s+Id\s+Version\s+Available\s+Source\s*$') {
            $headerIndex = $i
            break
        }
    }
    if ($headerIndex -lt 0) { return $rows }

    $header   = $Lines[$headerIndex]
    $idCol    = $header.IndexOf('Id')
    $verCol   = $header.IndexOf('Version')
    $availCol = $header.IndexOf('Available')
    $srcCol   = $header.IndexOf('Source')
    if ($idCol -lt 1 -or $verCol -le $idCol -or $availCol -le $verCol -or $srcCol -le $availCol) {
        return $rows
    }

    for ($i = $headerIndex + 1; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -match '^-+\s*$') { continue }           # column rule
        if ($line.Length -le $srcCol) { break }            # "N upgrades available." etc.
        $id = $line.Substring($idCol, $verCol - $idCol).Trim()
        if (-not $id) { break }

        $rows += [pscustomobject]@{
            Name      = $line.Substring(0, $idCol).Trim()
            Id        = $id
            Version   = $line.Substring($verCol, $availCol - $verCol).Trim()
            Available = $line.Substring($availCol, $srcCol - $availCol).Trim()
            Source    = $line.Substring($srcCol).Trim()
        }
    }
    return $rows
}

function Get-WingetUpgradeRows {
    param([Parameter(Mandatory)][string]$Winget)
    $lines = & $Winget upgrade --include-unknown --accept-source-agreements 2>&1 |
        ForEach-Object { [string]$_ }
    return ConvertFrom-WingetUpgradeTable -Lines $lines
}

$logDir = Join-Path $env:LOCALAPPDATA 'DesktopMaintenance\logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$log = Join-Path $logDir ("update-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
Start-Transcript -Path $log -Force -ErrorAction SilentlyContinue | Out-Null

try {
    $winget = (Get-Command winget.exe -ErrorAction SilentlyContinue).Source
    if (-not $winget) {
        warn "winget not found. Install/repair App Installer first."
        exit 1
    }

    step "Refreshing winget sources"
    & $winget source update 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) {
        warn "Source update returned $LASTEXITCODE; continuing."
    }

    $listArgs = @('upgrade', '--include-unknown', '--accept-source-agreements')

    step "Available upgrades"
    & $winget @listArgs 2>&1 | Out-Host

    if ($DryRun) {
        info "Dry run complete - no packages changed."
        exit 0
    }

    # --- Build the target list -------------------------------------------
    $rows = Get-WingetUpgradeRows -Winget $winget
    $targets = @($rows | Where-Object { $_.Id -notin $excludedIds })

    step "Upgrading packages"
    info "UAC prompts may appear per package. Some packages may need manual updates."

    if ($targets.Count -eq 0) {
        info "Nothing to upgrade."
    }
    else {
        $done   = @()
        $failed = @()
        $n = 0
        foreach ($t in $targets) {
            $n++
            Write-Host "`n${BOLD}($n/$($targets.Count))${RESET} $($t.Name) [$($t.Id)] $($t.Version) -> $($t.Available)"
            # Deliberately NOT piped: winget only draws its download progress bar
            # when stdout is a real console. Piping turned a stalled download into
            # a silent 4-minute hang on 4 Nov 2026. This text therefore misses the
            # transcript; winget's own logs in DiagOutputDir have it.
            & $winget upgrade --id $t.Id --exact --silent `
                --accept-package-agreements --accept-source-agreements
            $code = $LASTEXITCODE

            if ($code -eq 0 -or $code -eq $wingetNothingToDo) {
                $done += $t.Id
                success "$($t.Id) upgraded"
            }
            else {
                $failed += [pscustomobject]@{ Id = $t.Id; Exit = $code }
                warn "$($t.Id) exited $code - continuing with the rest"
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

    # --- Remaining state -------------------------------------------------
    step "Remaining upgrades"
    $remaining = & $winget @listArgs 2>&1 | Out-String
    Write-Host $remaining
    $remainingExit = $LASTEXITCODE

    # --- PowerShell self-upgrade hand-off --------------------------------
    $psPending = ($remaining -split "`r?`n" |
        Where-Object { $_ -match 'Microsoft\.PowerShell\b' }).Count -gt 0
    if ($psPending) {
        step "PowerShell is still pending"
        warn "The PowerShell MSI cannot run inside the session it replaces."
        warn "Windows Installer closes pwsh mid-install and rolls back with 1603."
        info "Run this from Command Prompt (Win+R -> cmd), not from PowerShell:"
        Write-Host "`n    winget upgrade --id Microsoft.PowerShell --exact --accept-package-agreements --accept-source-agreements`n"
        info "Expect every open PowerShell window to close during the install - that is the installer, not a crash."
        info "Then re-run 'update' to confirm nothing else is left."
    }

    if ($remainingExit -ne 0 -and $remainingExit -ne $wingetNothingToDo) {
        warn "Final upgrade check exited $remainingExit."
    }
    info "Log: $log"
}
finally {
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
}
