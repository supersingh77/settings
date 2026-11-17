
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'

$BOLD   = "`e[1m"
$GREEN  = "`e[32m"
$YELLOW = "`e[33m"
$CYAN   = "`e[36m"
$RESET  = "`e[0m"

$exitCode = 0

function info    { Write-Host "${CYAN}[info]${RESET}  $($args -join ' ')" }
function success { Write-Host "${GREEN}[ok]${RESET}    $($args -join ' ')" }
function warn    { Write-Host "${YELLOW}[warn]${RESET}  $($args -join ' ')" }
function step    { Write-Host "`n${BOLD}--- $($args -join ' ') ---${RESET}" }

function Get-FolderMB {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    $sum = (Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    if ($null -eq $sum) { return 0 }
    return [math]::Round(($sum / 1MB), 1)
}

function Clear-FolderContents {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $before = Get-FolderMB $Path
    if ($DryRun) {
        info "Would clear $Path ($before MB)"
        return
    }
    Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $after = Get-FolderMB $Path
    success "$Path : $before MB -> $after MB"
}

if ($DryRun) {
    Write-Host "${YELLOW}[dry-run] No files will be deleted.${RESET}"
} else {
    Write-Host "${YELLOW}[info] Slow maintenance task - this can take several minutes.${RESET}"
}

step "Cleaning temp files"
Clear-FolderContents $env:TEMP
Clear-FolderContents "$env:SystemRoot\Temp"

step "Cleaning Windows Update components (DISM)"
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    warn "Not elevated - skipping DISM component cleanup."
} elseif ($DryRun) {
    info "Would run: Dism.exe /Online /Cleanup-Image /StartComponentCleanup"
} else {
    & Dism.exe /Online /Cleanup-Image /StartComponentCleanup | Out-Host
    if ($LASTEXITCODE -ne 0) {
        warn "DISM exited $LASTEXITCODE - component store not cleaned."
        $exitCode = 1
    }
    else {
        success "DISM component cleanup finished."
    }
}

step "Emptying Recycle Bin"
if ($DryRun) {
    info "Would empty the Recycle Bin."
} else {
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        success "Recycle Bin emptied."
    } catch {
        warn "Recycle Bin cleanup skipped (already empty or in use)."
    }
}

step "Flushing DNS cache"
if ($DryRun) {
    info "Would run: ipconfig /flushdns"
} else {
    ipconfig /flushdns | Out-Host
    if ($LASTEXITCODE -ne 0) {
        warn "ipconfig /flushdns exited $LASTEXITCODE."
        $exitCode = 1
    }
    else {
        success "DNS cache flushed."
    }
}

step "Cleaning Delivery Optimization cache"
$doCache = "$env:ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"
if (Test-Path -LiteralPath $doCache) {
    $before = Get-FolderMB $doCache
    if ($DryRun) {
        info "Would clear $doCache ($before MB)"
    } else {
        Get-ChildItem -LiteralPath $doCache -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        success "Delivery Optimization cache cleared ($before MB)."
    }
} else {
    info "Delivery Optimization cache not found - skipping."
}

step "Review-only: installer leftovers (not deleted)"
$review = @(
    'C:\AMD',
    (Join-Path $env:USERPROFILE 'Downloads')
)
foreach ($path in $review) {
    if (Test-Path -LiteralPath $path) {
        info "$path = $(Get-FolderMB $path) MB"
    }
}
info "Delete leftover installers by hand once the matching driver or app is confirmed working."

step "Cleanup complete"
Write-Host ""
Write-Host "${GREEN}Maintenance tasks finished.${RESET}"
if ($exitCode -eq 0) {
    Write-Host "${YELLOW}Tip:${RESET} run ${CYAN}winget upgrade --all${RESET} for app updates."
}
Write-Host ""
exit $exitCode
