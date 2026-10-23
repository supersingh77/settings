# Desktop Audit Playbook

> Device: desktop | Updated: 23 Oct 2026
> Verified on Windows 11 26H2 (build 26300.9457). Commands are PowerShell 7.
> Read this before editing `startmenu-taskbar.md`, `software.md`, or `disk-cleanup.md`.

## 1. Taskbar Pins — Names and Order

UI Automation is the only method that returns packaged/Store pins in true order:

```powershell
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$root = [System.Windows.Automation.AutomationElement]::RootElement
$tray = $root.FindFirst([System.Windows.Automation.TreeScope]::Children,
  (New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ClassNameProperty, 'Shell_TrayWnd')))
$tray.FindAll([System.Windows.Automation.TreeScope]::Descendants,
  (New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
    [System.Windows.Automation.ControlType]::Button))) |
  Where-Object { $_.Current.ClassName -eq 'Taskbar.TaskListButtonAutomationPeer' } |
  ForEach-Object { ($_.Current.Name -replace ' - .*$','' -replace ' pinned$','').Trim() }
```

- Names may include a suffix such as `- 1 running window pinned`; the `-replace` above strips it.
- The Start/Search buttons are `ToggleButton`; tray/clock items are `SystemTrayIcon`.
- `AutomationId` starts `Appid: ...`; packaged apps look like
  `Microsoft.WindowsTerminal_8wekyb3d8bbwe!App`.
- The registry `Favorites` blob is **UTF-8 / single-byte**, not UTF-16, and it misses packaged pins. Use UI Automation.

## 2. Start Menu Pins

```powershell
$layout = "$env:TEMP\start.json"
powershell.exe -NoProfile -Command "Export-StartLayout -Path '$layout'"
Get-Content $layout -Raw
```

- `pinnedList[]` is ordered; entries are `packagedAppId` or `desktopAppLink`.
- **Caveat on 26H2:** the export returned only **Settings** and **File Explorer** on 2026-10-23. If the Start UI shows more pins, the export is incomplete — verify visually instead of trusting it.
- **Dead end:** `...\StartMenuExperienceHost_...\LocalState\start2.bin` is compressed; don't decode it.

## 3. Installed Apps

```powershell
winget list
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' |
  Where-Object DisplayName |
  Select-Object DisplayName,DisplayVersion,InstallLocation
Get-AppxPackage | Where-Object { -not $_.IsFramework } | Select-Object Name,Version
```

- `winget list` misses some manually installed drivers and vendor payloads; cross-check ARP.
- **Known winget bug on this build:** `winget install --scope machine` returns `0x80070005`. Use default-scope installs and verify the target is `Program Files`; use official all-users MSIs for PowerShell/Python.
- If winget says `Failed to open the predefined source`, run `winget source update`.

## 4. Device & Driver Health

```powershell
Get-PnpDevice -PresentOnly | Where-Object Status -ne 'OK' |
  Select-Object Status,Class,FriendlyName,InstanceId
pnputil /enum-devices /problem
```

- Expected: **no problem devices**.
- Monitor should be `MSI MAG 255XF` on driver `1.0.0.0` (`oem30.inf`), not Generic PnP.
- MPRT is not exposed as a DDC/CI VCP on this monitor; don't chase software toggles.

## 5. "Is It Really Installed?"

```powershell
Test-Path 'C:\Program Files\<App>'
Get-ChildItem 'C:\Program Files\<App>' -Recurse -File | Measure-Object Length -Sum
```

- An empty folder or a stray log is **not** an install.
- Uninstalled/removed apps belong in `software.md` under "Deliberately not installed", not in the active inventory.

## 6. Steam Libraries

```powershell
Get-ChildItem 'C:\Program Files (x86)\Steam\steamapps\common' -Directory
Get-ChildItem 'E:\Games\SteamLibrary\steamapps\common' -Directory
Get-ChildItem 'D:\Games\SteamLibrary\steamapps\common' -Directory
```

- Libraries are on **E:** and **D:** (old V:/Z:).
- `libraryfolders.vdf` may not exist until Steam is launched once. Until then, inspect `steamapps\appmanifest_*.acf` directly.
- A folder under `common\` with no appmanifest is a leftover, not an install.

## 7. Doc Conventions

| Doc | Holds |
|-----|-------|
| `README.md` | Hub, quick reference, setup rules |
| `hardware.md` | Components, drivers, storage, quirks |
| `software.md` | Active app inventory + install scope + drivers |
| `startmenu-taskbar.md` | Current pins only, in order |
| `desktop.md` | Actual desktop contents |
| `disk-cleanup.md` | Drive map + measured cleanup targets |

Rules: bump the `Updated:` date · verify live, never recall · mark unverified values · tables over prose · cut historical waffle.
