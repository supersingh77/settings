# =============================================================================
# cleanup-system.ps1 — Slow maintenance tasks for Windows (ASUS ROG Strix)
#
# These tasks are safe but can take several minutes, so they're kept separate
# from the fast daily `winget upgrade --all`. Run occasionally (e.g. weekly/monthly).
#
# Cleans:
#   1. Scoop download cache (scoop cache rm *)
#   2. Scoop old versions (scoop cleanup *)
#   3. User + system temp files
#   4. Windows Update component cleanup (DISM)
#   5. Recycle Bin
#   6. DNS cache flush
#   7. Delivery Optimization cache
#
# Each section continues on failure — a failed task won't stop the rest.
#
# Usage:
#   pwsh scripts/cleanup-system.ps1
#   cleanup-system          # via alias (after adding to PATH / profile)
# =============================================================================

# Don't exit on error — each section handles its own failures
$ErrorActionPreference = 'Continue'

# ── Colors & helpers (mirrors _lib.sh on the Linux side) ─────────────────────
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

# Run a command, log result, never abort script (mirrors run_or_warn)
function run_or_warn {
    param(
        [string]$Description,
        [scriptblock]$Command
    )
    try {
        & $Command
        return $true
    } catch {
        warn "${Description} — continuing anyway."
        return $false
    }
}

Write-Host "${YELLOW}ℹ️  This is a slow maintenance task — it may take several minutes.${RESET}"

# ── 1. Scoop download cache ──────────────────────────────────────────────────
step "Clearing Scoop download cache"

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    run_or_warn "Scoop cache cleanup had issues" { scoop cache rm * }
    success "Scoop cache step complete."
} else {
    info "Scoop not installed — skipping."
}

# ── 2. Scoop old versions ────────────────────────────────────────────────────
step "Removing old Scoop versions"

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    run_or_warn "Scoop cleanup had issues" { scoop cleanup * }
    success "Scoop cleanup complete."
} else {
    info "Scoop not installed — skipping."
}

# ── 3. Temp files ────────────────────────────────────────────────────────────
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

        Get-ChildItem -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

        $after = (Get-ChildItem -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum
        $afterMB = [math]::Round(($after / 1MB), 1)

        success "$dir : $beforeMB MB → $afterMB MB"
    }
}

# ── 4. Windows Update component cleanup ──────────────────────────────────────
step "Cleaning Windows Update components (DISM)"

# Requires admin; skip gracefully if not elevated.
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

# ── 5. Recycle Bin ───────────────────────────────────────────────────────────
step "Emptying Recycle Bin"

try {
    Clear-RecycleBin -Force -ErrorAction Stop
    success "Recycle Bin emptied."
} catch {
    warn "Recycle Bin cleanup had issues — continuing anyway."
}

# ── 6. DNS cache flush ───────────────────────────────────────────────────────
step "Flushing DNS cache"

run_or_warn "DNS cache flush had issues" { ipconfig /flushdns | Out-Host }
success "DNS cache flushed."

# ── 7. Delivery Optimization cache ───────────────────────────────────────────
step "Cleaning Delivery Optimization cache"

# Delivery Optimization (Windows Update peer cache) — safe to clear.
$doCache = "$env:ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"
if (Test-Path -LiteralPath $doCache) {
    $before = (Get-ChildItem -LiteralPath $doCache -Recurse -Force -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    $beforeMB = [math]::Round(($before / 1MB), 1)

    Get-ChildItem -LiteralPath $doCache -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    success "Delivery Optimization cache cleared ($beforeMB MB)."
} else {
    info "Delivery Optimization cache not found — skipping."
}

# ── 8. Summary ───────────────────────────────────────────────────────────────
step "Cleanup complete"

Write-Host ""
Write-Host "${GREEN}All maintenance tasks finished.${RESET}"
Write-Host "${YELLOW}Tip:${RESET}  Run ${CYAN}winget upgrade --all${RESET} for app updates."
Write-Host ""