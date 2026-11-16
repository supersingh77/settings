# Desktop Audit Playbook

> Device: desktop | Updated: 16 Nov 2026
> Verified on Windows 11 26H2 (build 26300.9457) — `ProductName` lies and says "Windows 10 Pro".
> Read this before editing `startmenu-taskbar.md`, `software.md`, `hardware.md`, or `disk-cleanup.md`.
> **Fastest path:** run `pwsh device/desktop/scripts/audit-state.ps1` — it prints every fact these docs claim, in one shot. Use the sections below when you need to go deeper.

## 0. Environment limits (why some checks "fail")

Inside a sandboxed agent session (DeepSeek Harness, etc.) the following are **blocked, not broken**:

| Blocked | Symptom | Use instead |
|---|---|---|
| `Get-CimInstance` / `Get-WmiObject` / WMI | `Access denied` | SMBIOS registry blob (RAM + cores), `EnumDisplaySettings` (refresh), driver-key `qwMemorySize` (VRAM), `[System.IO.DriveInfo]` |
| `Get-Volume`, `Get-PhysicalDisk` | `Access denied` | `[System.IO.DriveInfo]::GetDrives()` |
| `Get-PnpDevice` | `Access denied` | `pnputil /enum-devices /problem` — **this one works** |
| `Get-AppxPackage` | `Access is denied` | ARP keys; `Taskband` blob for packaged pin IDs |
| UI Automation on the taskbar | returns nothing | `User Pinned\TaskBar` folder + `Taskband\Favorites` blob |
| `Export-StartLayout` | `0x80070490 Element not found` | visual check |
| `winget` (any verb) | `0x8A150001` even for `--info` | run winget from an **elevated, unsandboxed** shell |
| Machine-wide uninstall | MSI 1603 / access denied | elevated shell (`winget uninstall --id <id> --exact`) |

**Still works inside the sandbox, and covers more than you'd expect:** registry reads of every kind, the `SMBiosData` blob, `pnputil.exe`, Win32 P/Invoke via `Add-Type` (`EnumDisplaySettings`), ARP keys, and on-disk state. `audit-state.ps1` uses exactly these.

**HWiNFO cannot help here.** Its report/logging CLI (`-r`, `-l`) is **Pro-only** — the free build accepts the flag and silently writes nothing. Don't plan an audit around it unless HWiNFO Pro is licensed.

So: **never record "0 problem devices" or a refresh rate you measured with WMI inside an agent session** — you cannot measure it there.

## 1. Taskbar Pins — Set and Order

**Set** (authoritative for desktop-app pins):

```powershell
Get-ChildItem "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" -Force |
  Select-Object Name, LastWriteTime
```

Packaged pins (Store, Terminal, Notion…) may have no `.lnk` there. For those, plus the true left→right **order**, decode the blob — each pin's name sits at a byte offset, so sorting by offset gives the order:

```powershell
$b = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband').Favorites
function Find-Off([string]$n, [bool]$utf16) {
  $pat = if ($utf16) { [Text.Encoding]::Unicode.GetBytes($n) } else { [Text.Encoding]::GetEncoding(28591).GetBytes($n) }
  for ($i = 0; $i -le $b.Length - $pat.Length; $i++) {
    $ok = $true
    for ($j = 0; $j -lt $pat.Length; $j++) { if ($b[$i+$j] -ne $pat[$j]) { $ok = $false; break } }
    if ($ok) { return $i }
  }
  return [int]::MaxValue
}
# 'X.lnk' names are single-byte; 'Microsoft.X_8wekyb3d8bbwe' AppIds are UTF-16
```

- The blob is written UTF-8/single-byte for `.lnk` entries and UTF-16 for packaged AppIds — you must search both encodings.
- UI Automation is the "correct" method but needs an interactive desktop; it returns **nothing** under DSH.
- Removing a pin = delete its `.lnk` from `User Pinned\TaskBar` (takes effect on next Explorer start). Uninstalling an app removes its pin automatically.

## 2. Start Menu Pins

```powershell
$layout = "$env:TEMP\start.json"
powershell.exe -NoProfile -Command "Export-StartLayout -Path '$layout'"
Get-Content $layout -Raw
```

- `pinnedList[]` is ordered; entries are `packagedAppId` or `desktopAppLink`.
- **Caveat on 26H2:** the export returned only **Settings** and **File Explorer** on 2026-10-23, and inside an agent session it fails with `0x80070490`. If the Start UI shows more pins, the export is incomplete — verify visually.
- **Dead end:** `...\StartMenuExperienceHost_...\LocalState\start2.bin` is compressed; don't decode it.

## 3. Installed Apps

```powershell
# authoritative when WMI/AppX are blocked
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' |
  Where-Object DisplayName |
  Select-Object DisplayName, DisplayVersion, InstallLocation, InstallDate
```

- `winget list` misses manually installed tools (FFmpeg) and vendor payloads; ARP misses portable installs. Cross-check both, then confirm on disk.
- **Version traps:** PXN SimRacing's ARP version (1.2.0.0) comes from `uninst.exe`, not the app (1.6.8.0). Discord's `InstallDate` is garbage (`20262123`). Verify with `(Get-Item app.exe).VersionInfo.FileVersion`.
- **Known winget bug on this build:** `winget install --scope machine` returns `0x80070005`. Use default-scope installs and verify the target landed in `Program Files`; use official all-users MSIs for PowerShell/Python.
- If winget says `Failed to open the predefined source`, run `winget source update`.

## 4. Device & Driver Health

```powershell
pnputil /enum-devices /problem     # works even in a sandbox; "No devices were found" == healthy
Get-PnpDevice -PresentOnly | Where-Object Status -ne 'OK' |   # needs a non-sandboxed session
  Select-Object Status, Class, FriendlyName, InstanceId
```

Live display mode without WMI (this is how "300 Hz" is actually verified):

```powershell
Add-Type -TypeDefinition '<DEVMODE + EnumDisplaySettings signature>'
# then EnumDisplaySettings('\\.\DISPLAY1', -1, [ref]$dm) -> dmDisplayFrequency
```

`audit-state.ps1` already does this and prints every attached display's current mode. Use `ENUM_CURRENT_SETTINGS` (`-1`) — passing mode indexes enumerates the capability list instead.

Registry fallback when WMI is blocked:

```powershell
Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' |
  ForEach-Object { Get-ItemProperty $_.PSPath } |
  Where-Object DriverDesc | Select-Object DriverDesc, DriverVersion, DriverDate
Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY' -Recurse |
  ForEach-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DeviceDesc } |
  Where-Object { $_ }
```

- Expected: **no problem devices** (last verified 23 Oct).
- Monitor should resolve through `oem30.inf` → `MSI MAG 255XF`, with `MSI MAG 255XF.icm` in `System32\spool\drivers\color`. A `Generic PnP Monitor` entry means the INF did not take.
- MPRT is not exposed as a DDC/CI VCP on this monitor; don't chase software toggles.

## 5. "Is It Really Installed?"

```powershell
Test-Path 'C:\Program Files\<App>'
Get-ChildItem 'C:\Program Files\<App>' -Recurse -File | Measure-Object Length -Sum
```

- An empty folder or a stray config is **not** an install. Live examples: `C:\Program Files\DroidCam` (empty), `C:\tools\php84` (only a `php.ini`), `C:\AMD\Chipset_Software` (one log).
- Uninstalled/removed apps belong in `software.md` under "Deliberately not installed" or "Removed", never in the active inventory.

## 6. Steam Libraries

```powershell
Get-Content 'C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf' -Raw   # registered libraries
Get-ChildItem 'V:\Games\SteamLibrary\steamapps\common' -Directory
Get-ChildItem 'Z:\Games\SteamLibrary\steamapps\common' -Directory
```

- Libraries live on **V:** and **Z:** (there is no `D:`/`E:`).
- `libraryfolders.vdf` is the truth for **registered** libraries; `appmanifest_*.acf` count is the truth for **installed** apps. They disagree right now: `V:` is registered with 6 apps, `Z:` has 2 manifests but is not registered.
- A folder under `common\` with no appmanifest is a leftover, not an install.

## 7. Doc Conventions

| Doc | Holds |
|-----|-------|
| `README.md` | Hub, quick reference, setup rules |
| `hardware.md` | Components, drivers, storage, quirks |
| `software.md` | Active app inventory + install scope + drivers + removals |
| `startmenu-taskbar.md` | Current pins only, in order |
| `desktop.md` | Actual desktop contents |
| `disk-cleanup.md` | Drive map + measured cleanup targets |

Rules: bump the `Updated:` date · **verify live, never recall** · mark unverified values `needs-review` · tables over prose · cut historical waffle.

> The 23 Oct pass got six files wrong about drive letters because it was written from memory instead of measured. Run `audit-state.ps1` first; it exists so that mistake cannot repeat.
