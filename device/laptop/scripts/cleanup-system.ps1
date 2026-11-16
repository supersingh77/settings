[CmdletBinding()]
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

function info    { Write-Host "${CYAN}ℹ️  $($args -join ' ')${RESET}" }
function success { Write-Host "${GREEN}✅ $($args -join ' ')${RESET}" }
function warn    { Write-Host "${YELLOW}⚠️  $($args -join ' ')${RESET}" }
function step    { Write-Host "`n${BOLD}━━━ $($args -join ' ') ━━━${RESET}" }

function run_or_warn {
    param(
        [string]$Description,
        [scriptblock]$Command
    )
    if ($DryRun) {
        info "would run: $Description"
        return $true
    }
    try {
        & $Command
        return $true
    } catch {
        warn "${Description} — continuing anyway."
        return $false
    }
}

if ($DryRun) {
    Write-Host "${YELLOW}ℹ️  Dry run — nothing will be deleted.${RESET}"
} else {
    Write-Host "${YELLOW}ℹ️  This is a slow maintenance task — it may take several minutes.${RESET}"
}

step "Clearing Scoop download cache"
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    run_or_warn "Scoop cache cleanup had issues" { scoop cache rm * }
    success "Scoop cache step complete."
} else {
    info "Scoop not installed — skipping."
}

step "Removing old Scoop versions"
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    run_or_warn "Scoop cleanup had issues" { scoop cleanup * }
    success "Scoop cleanup complete."
} else {
    info "Scoop not installed — skipping."
}

step "Cleaning temp files"
$tempDirs = @(
    $env:TEMP,
    "$env:SystemRoot\Temp"
)
foreach ($dir in $tempDirs) {
    if (Test-Path -LiteralPath $dir) {
        $before = (Get-ChildItem -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum
        $beforeMB = [math]::Round(($before / 1MB), 1)

        if ($DryRun) {
            info "would clear $dir ($beforeMB MB)"
            continue
        }

        Get-ChildItem -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

        $after = (Get-ChildItem -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum
        $afterMB = [math]::Round(($after / 1MB), 1)

        success "$dir : $beforeMB MB → $afterMB MB"
    }
}

step "Cleaning Windows Update components (DISM)"
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if ($isAdmin) {
    run_or_warn "DISM component cleanup had issues" {
        & Dism.exe /Online /Cleanup-Image /StartComponentCleanup | Out-Host
    }
    success "DISM step complete."
} else {
    warn "Not running as administrator — skipping DISM component cleanup."
    warn "Re-run from an elevated terminal to clean Windows Update components."
}

step "Emptying Recycle Bin"
if ($DryRun) {
    info "would empty the Recycle Bin"
} else {
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        success "Recycle Bin emptied."
    } catch {
        warn "Recycle Bin cleanup had issues — continuing anyway."
    }
}

step "Flushing DNS cache"
if ($DryRun) {
    info "would run: ipconfig /flushdns"
} else {
    run_or_warn "DNS cache flush had issues" { ipconfig /flushdns | Out-Host }
    success "DNS cache flushed."
}

step "Cleaning Delivery Optimization cache"
$doCache = "$env:ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"
if (Test-Path -LiteralPath $doCache) {
    $before = (Get-ChildItem -LiteralPath $doCache -Recurse -Force -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    $beforeMB = [math]::Round(($before / 1MB), 1)

    if ($DryRun) {
        info "would clear $doCache ($beforeMB MB)"
    } else {
        Get-ChildItem -LiteralPath $doCache -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        success "Delivery Optimization cache cleared ($beforeMB MB)."
    }
} else {
    info "Delivery Optimization cache not found — skipping."
}

step "Cleanup complete"
Write-Host ""
Write-Host "${GREEN}All maintenance tasks finished.${RESET}"
Write-Host "${YELLOW}Tip:${RESET}  Run ${CYAN}winget upgrade --all${RESET} for app updates."
Write-Host ""

exit 0
