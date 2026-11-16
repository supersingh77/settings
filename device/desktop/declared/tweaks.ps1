# =============================================================================
# tweaks.ps1 - converge the deliberate registry choices for this desktop.
#
# Only things that were changed on purpose, and only things that CAN be scripted.
# File-association defaults (UserChoice) are hash-protected by Windows and are
# deliberately not touched here - set those through Settings > Default apps.
#
# Idempotent: running twice changes nothing the second time.
# Requires an elevated shell to actually write; -DryRun is read-only.
#
# Usage:
#   pwsh device/desktop/declared/tweaks.ps1 -DryRun    # show what would change
#   pwsh device/desktop/declared/tweaks.ps1            # apply (elevated)
# =============================================================================

[CmdletBinding()]
param([switch]$DryRun)

$ErrorActionPreference = 'Continue'
$script:changes = 0
$script:skipped = 0

function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-DefaultProgId([string]$ext) {
    (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -ErrorAction SilentlyContinue).'(default)'
}

function Get-ProgIdCommand([string]$progId) {
    if (-not $progId) { return $null }
    (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$progId\shell\open\command" -ErrorAction SilentlyContinue).'(default)'
}

function Set-ExtensionDefault([string]$ext, [string]$progId) {
    $current = Get-DefaultProgId $ext
    if ($current -eq $progId) { Write-Host "  ok    $ext already -> $progId"; $script:skipped++; return }

    if (-not (Get-ProgIdCommand $progId)) {
        Write-Host "  skip  $ext : target ProgId '$progId' has no open command" -ForegroundColor Yellow
        $script:skipped++
        return
    }
    if ($DryRun) { Write-Host "  would $ext : '$current' -> '$progId'"; $script:changes++; return }

    Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$ext" -Name '(default)' -Value $progId -Force
    Write-Host "  set   $ext -> $progId" -ForegroundColor Green
    $script:changes++
}

# Expose the existing default handler in the "Open with" submenu. This is the
# working bypass while the app picker is broken (ShellHost.exe 0xC0000142).
function Add-OpenWithProgId([string]$ext) {
    $progId = Get-DefaultProgId $ext
    if (-not $progId -or -not (Get-ProgIdCommand $progId)) { return }
    $key = "Registry::HKEY_CLASSES_ROOT\$ext\OpenWithProgids"
    $existing = @()
    if (Test-Path $key) { $existing = (Get-Item $key).GetValueNames() }
    if ($existing -contains $progId) { return }

    if ($DryRun) { Write-Host "  would add '$progId' to $ext\OpenWithProgids"; $script:changes++; return }
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    New-ItemProperty -Path $key -Name $progId -Value '' -PropertyType String -Force | Out-Null
    Write-Host "  add   $progId -> $ext\OpenWithProgids" -ForegroundColor Green
    $script:changes++
}

$isAdmin = Test-Admin
Write-Host "tweaks.ps1  mode=$(if($DryRun){'DRY RUN'}else{'APPLY'})  admin=$isAdmin`n" -ForegroundColor Cyan

# --- 1. markdown: point at the ProgId that actually has a command ------------
Write-Host '1. .md handler'
$mdTarget = 'Markdown Document'
if (Get-ProgIdCommand $mdTarget) { Set-ExtensionDefault '.md' $mdTarget }
else { Write-Host "  skip  no command on '$mdTarget' (install a markdown app first)" -ForegroundColor Yellow }

# --- 2. media types: surface the real default in "Open with" ----------------
Write-Host "`n2. 'Open with' entries for media types"
$mediaExts = @(
    '.mp4', '.mkv', '.avi', '.mov', '.m4v', '.wmv', '.mpg', '.mpeg', '.ts', '.m2ts',
    '.mp3', '.m4a', '.flac', '.wav', '.aac', '.ogg', '.opus', '.wma', '.ac3'
)
foreach ($ext in $mediaExts) { Add-OpenWithProgId $ext }
Write-Host "  ($($mediaExts.Count) media types checked; $script:changes change(s) so far)" -ForegroundColor DarkGray

# --- 3. things that must be done by hand ------------------------------------
Write-Host "`n3. not scriptable by design" -ForegroundColor DarkGray
Write-Host '  - default apps (UserChoice): hash-protected; use Settings > Default apps' -ForegroundColor DarkGray
Write-Host '  - OBS settings: see declared/obs.json' -ForegroundColor DarkGray

Write-Host "`nsummary: $script:changes change(s)" + $(if ($DryRun) { ' (dry run - nothing written)' } else { '' })
if (-not $DryRun -and -not $isAdmin) { Write-Host 'WARNING: not elevated - writes to HKCR will fail' -ForegroundColor Red }
