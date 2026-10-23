# =============================================================================
# update-system.ps1 - Update installed apps with winget
#
# Refreshes winget sources, lists available upgrades, then upgrades everything
# it can. Some packages (MSIX/Store apps, vendor installers) may still need a
# manual update or a UAC prompt.
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

    step "Upgrading all packages"
    info "UAC prompts may appear per package. Some packages may need manual updates."
    & $winget upgrade --all --include-unknown --silent `
        --accept-package-agreements --accept-source-agreements `
        --disable-interactivity 2>&1 | Out-Host
    $upgradeExit = $LASTEXITCODE

    step "Remaining upgrades"
    & $winget @listArgs 2>&1 | Out-Host

    if ($upgradeExit -eq 0) {
        success "winget upgrade completed."
    } else {
        warn "winget upgrade exited $upgradeExit. Review the output above for packages that need manual attention."
    }
    info "Log: $log"
}
finally {
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
}
