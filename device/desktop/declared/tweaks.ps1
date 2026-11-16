[CmdletBinding()]
param(
    [string]$Manifest = (Join-Path $PSScriptRoot 'associations.json'),
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'
$script:changes = 0

function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-DefaultProgId {
    param([string]$Extension)
    (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$Extension" -ErrorAction SilentlyContinue).'(default)'
}

function Get-ProgIdCommand {
    param([string]$ProgId)
    if (-not $ProgId) { return $null }
    (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ProgId\shell\open\command" -ErrorAction SilentlyContinue).'(default)'
}

function Set-ExtensionDefault {
    param([string]$Extension, [string]$ProgId)
    $current = Get-DefaultProgId $Extension
    if ($current -eq $ProgId) {
        Write-Host "  ok    $Extension already -> $ProgId"
        return
    }
    if (-not (Get-ProgIdCommand $ProgId)) {
        Write-Host "  skip  $Extension : target ProgId '$ProgId' has no open command" -ForegroundColor Yellow
        return
    }
    if ($DryRun) {
        Write-Host "  would $Extension : '$current' -> '$ProgId'"
        $script:changes++
        return
    }
    Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$Extension" -Name '(default)' -Value $ProgId -Force
    Write-Host "  set   $Extension -> $ProgId" -ForegroundColor Green
    $script:changes++
}

function Add-OpenWithProgId {
    param([string]$Extension)
    $progId = Get-DefaultProgId $Extension
    if (-not $progId -or -not (Get-ProgIdCommand $progId)) { return }

    $key = "Registry::HKEY_CLASSES_ROOT\$Extension\OpenWithProgids"
    $existing = @()
    if (Test-Path $key) { $existing = (Get-Item $key).GetValueNames() }
    if ($existing -contains $progId) { return }

    if ($DryRun) {
        Write-Host "  would add '$progId' to $Extension\OpenWithProgids"
        $script:changes++
        return
    }
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    New-ItemProperty -Path $key -Name $progId -Value '' -PropertyType String -Force | Out-Null
    Write-Host "  add   $progId -> $Extension\OpenWithProgids" -ForegroundColor Green
    $script:changes++
}

function Repair-QuotedCommand {
    param([string]$ProgId)
    $key = "Registry::HKEY_CLASSES_ROOT\$ProgId\shell\open\command"
    $current = (Get-ItemProperty $key -ErrorAction SilentlyContinue).'(default)'
    if (-not $current) { return }
    if ($current -match '^\s*"') { return }
    if ($current -notmatch '^(.+?\.exe)\s+(.*)$') { return }
    $fixed = '"' + $Matches[1].Trim() + '" ' + $Matches[2].Trim()
    if ($DryRun) {
        Write-Host "  would quote $ProgId"
        Write-Host "        -> $fixed"
        $script:changes++
        return
    }
    Set-ItemProperty -Path $key -Name '(default)' -Value $fixed -Force
    Write-Host "  quoted $ProgId" -ForegroundColor Green
    $script:changes++
}

function Register-Application {
    param([string]$ExePath, [string]$FriendlyName)
    if (-not (Test-Path -LiteralPath $ExePath)) {
        Write-Host "  skip  $ExePath not installed" -ForegroundColor Yellow
        return
    }
    $exeName = Split-Path -Leaf $ExePath
    $root = "Registry::HKEY_CLASSES_ROOT\Applications\$exeName"
    $command = '"' + $ExePath + '" "%1"'
    $current = (Get-ItemProperty "$root\shell\open\command" -ErrorAction SilentlyContinue).'(default)'
    if ($current -eq $command) { return }

    if ($DryRun) {
        Write-Host "  would register $exeName as '$FriendlyName'"
        $script:changes++
        return
    }
    New-Item -Path "$root\shell\open\command" -Force | Out-Null
    Set-ItemProperty -Path $root -Name '(default)' -Value $FriendlyName -Force
    Set-ItemProperty -Path $root -Name 'FriendlyAppName' -Value $FriendlyName -Force
    Set-ItemProperty -Path "$root\shell\open\command" -Name '(default)' -Value $command -Force
    Write-Host "  registered $exeName" -ForegroundColor Green
    $script:changes++
}

function Ensure-ProgId {
    param([string]$Name, [string]$Description, [string]$Command)
    $key = "Registry::HKEY_CLASSES_ROOT\$Name"
    $current = (Get-ItemProperty "$key\shell\open\command" -ErrorAction SilentlyContinue).'(default)'
    if ($current -eq $Command) { return }
    if ($DryRun) {
        Write-Host "  would create ProgId $Name -> $Command"
        $script:changes++
        return
    }
    New-Item -Path "$key\shell\open\command" -Force | Out-Null
    Set-ItemProperty -Path $key -Name '(default)' -Value $Description -Force
    Set-ItemProperty -Path "$key\shell\open\command" -Name '(default)' -Value $Command -Force
    Write-Host "  created ProgId $Name" -ForegroundColor Green
    $script:changes++
}

function Set-OpenWithProgram {
    param([string]$Extension, [string]$Executable)
    if (-not $Executable) { return }
    $listKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$Extension\OpenWithList"
    $current = (Get-ItemProperty $listKey -ErrorAction SilentlyContinue).'a'
    $mru = (Get-ItemProperty $listKey -ErrorAction SilentlyContinue).MRUList
    if ($current -eq $Executable -and $mru -eq 'a') { return }
    if ($DryRun) {
        Write-Host "  would set $Extension OpenWithList a=$Executable"
        $script:changes++
        return
    }
    if (-not (Test-Path $listKey)) { New-Item -Path $listKey -Force | Out-Null }
    Set-ItemProperty -Path $listKey -Name 'a' -Value $Executable -Force
    Set-ItemProperty -Path $listKey -Name 'MRUList' -Value 'a' -Force
    Write-Host "  $Extension OpenWithList a=$Executable" -ForegroundColor Green
    $script:changes++
}

$isAdmin = Test-Admin
$plan = Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json

Write-Host "tweaks.ps1  mode=$(if ($DryRun) { 'DRY RUN' } else { 'APPLY' })  admin=$isAdmin  manifest=$Manifest`n" -ForegroundColor Cyan

Write-Host "`n1. ProgIds"
foreach ($progId in $plan.progIds) { Ensure-ProgId -Name $progId.name -Description $progId.description -Command $progId.command }

Write-Host "`n2. $($plan.markdown.extension) handler"
if (Get-ProgIdCommand $plan.markdown.targetProgId) {
    Set-ExtensionDefault -Extension $plan.markdown.extension -ProgId $plan.markdown.targetProgId
    Set-OpenWithProgram -Extension $plan.markdown.extension -Executable $plan.markdown.openWithExe
} else {
    Write-Host "  skip  no command on '$($plan.markdown.targetProgId)'" -ForegroundColor Yellow
}

Write-Host "`n3. 'Open with' entries"
foreach ($extension in $plan.mediaExtensions) { Add-OpenWithProgId -Extension $extension }
Write-Host "  ($($plan.mediaExtensions.Count) media types checked; $script:changes change(s) so far)" -ForegroundColor DarkGray

Write-Host "`n4. quoted command paths"
foreach ($progId in $plan.quoteCommandsForProgIds) { Repair-QuotedCommand -ProgId $progId }

Write-Host "`n5. application registrations"
foreach ($app in $plan.applicationRegistrations) {
    Register-Application -ExePath $app.exePath -FriendlyName $app.friendlyName
}

Write-Host "`n6. not scriptable by design" -ForegroundColor DarkGray
Write-Host '  - default apps (UserChoice): hash-protected; use Settings > Default apps' -ForegroundColor DarkGray
Write-Host '  - OBS settings: see declared/obs.json' -ForegroundColor DarkGray

Write-Host "`nsummary: $script:changes change(s)" + $(if ($DryRun) { ' (dry run - nothing written)' } else { '' })
if (-not $DryRun -and -not $isAdmin) { Write-Host 'WARNING: not elevated - HKCR writes will fail' -ForegroundColor Red }
if ($script:changes -gt 0 -and -not $DryRun) { exit 0 }
exit 0
