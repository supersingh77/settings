# Desktop audit fallbacks

Generated current hardware and software readings live in [`hardware.md`](hardware.md) and [`software.md`](software.md). Use this guide only when a reading needs manual investigation or a Windows API is unavailable in an agent session.

## 0. Environment limits (why some checks "fail")

Inside a sandboxed agent session (DeepSeek Harness, etc.) the following are **blocked, not broken**:

| Blocked | Symptom | Use instead |
|---|---|---|
| `Get-CimInstance` / `Get-WmiObject` / WMI | `Access denied` | SMBIOS registry blob (RAM + cores), `EnumDisplaySettings` (refresh), driver-key `qwMemorySize` (VRAM), `[System.IO.DriveInfo]` |
| `Get-Volume`, `Get-PhysicalDisk` | `Access denied` | `[System.IO.DriveInfo]::GetDrives()` |
| `Get-PnpDevice` | `Access denied` | `pnputil /enum-devices /problem` — **this one works** |
| `Get-AppxPackage` | `Access is denied` | HKCU `…\AppModel\Repository\Packages` — the package name carries the version (`Name_1.2.3.4_x64__publisher`). This is how Terminal and Notion versions are measured; `Taskband` still supplies packaged pin IDs |
| UI Automation on the taskbar | returns nothing | `User Pinned\TaskBar` folder + `Taskband\Favorites` blob |
| `Export-StartLayout` | `0x80070490 Element not found` | visual check |
| `winget` (any verb) | `0x8A150001` even for `--info` | run winget from an **elevated, unsandboxed** shell |
| Machine-wide uninstall | MSI 1603 / access denied | elevated shell (`winget uninstall --id <id> --exact`) |

**Still works inside the sandbox, and covers more than you'd expect:** registry reads of every kind, the `SMBiosData` blob, `pnputil.exe`, Win32 P/Invoke via `Add-Type` (`EnumDisplaySettings`), ARP keys, and on-disk state. `audit-state.ps1` uses exactly these.

**HWiNFO cannot help here.** Its report/logging CLI (`-r`, `-l`) is **Pro-only** — the free build accepts the flag and silently writes nothing. Don't plan an audit around it unless HWiNFO Pro is licensed.

So: **never record "0 problem devices" or a refresh rate you measured with WMI inside an agent session** — you cannot measure it there.

## 1. Taskbar pins — set and order

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
```

- The blob is written UTF-8/single-byte for `.lnk` entries and UTF-16 for packaged AppIds — you must search both encodings.
- UI Automation is the "correct" method but needs an interactive desktop; it returns **nothing** under DSH.
- Removing a pin = delete its `.lnk` from `User Pinned\TaskBar` (takes effect on next Explorer start). Uninstalling an app removes its pin automatically.

## 2. Start menu pins

```powershell
$layout = "$env:TEMP\start.json"
powershell.exe -NoProfile -Command "Export-StartLayout -Path '$layout'"
Get-Content $layout -Raw
```

- `pinnedList[]` is ordered; entries are `packagedAppId` or `desktopAppLink`.
- If export results differ from the Start UI, verify the pins visually.
- **Dead end:** `...\StartMenuExperienceHost_...\LocalState\start2.bin` is compressed; don't decode it.

## 3. Installed apps

```powershell
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' |
  Where-Object DisplayName |
  Select-Object DisplayName, DisplayVersion, InstallLocation, InstallDate
```

- `winget list` misses manually installed tools (FFmpeg) and vendor payloads; ARP misses portable installs. Cross-check both, then confirm on disk.
- Some uninstallers report their own version rather than the application's version. Verify the app executable's file version when the inventory needs clarification.
- If winget says `Failed to open the predefined source`, run `winget source update`.

## 4. Device and driver health

```powershell
pnputil /enum-devices /problem     # works even in a sandbox; "No devices were found" == healthy
Get-PnpDevice -PresentOnly | Where-Object Status -ne 'OK' |   # needs a non-sandboxed session
  Select-Object Status, Class, FriendlyName, InstanceId
```

Live display mode without WMI (this is how "300 Hz" is actually verified):

```powershell
Add-Type -TypeDefinition '<DEVMODE + EnumDisplaySettings signature>'
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

- The live audit reports problem devices, monitor INF matches, and active display modes.
- MPRT is not exposed as a DDC/CI VCP on this monitor; don't chase software toggles.

## 5. Check whether a folder is an install

```powershell
Test-Path 'C:\Program Files\<App>'
Get-ChildItem 'C:\Program Files\<App>' -Recurse -File | Measure-Object Length -Sum
```

- An empty folder or a stray config is **not** an install. The live audit checks configured trap paths.

## 6. Steam libraries

```powershell
Get-Content 'C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf' -Raw   # registered libraries
Get-ChildItem 'V:\Games\SteamLibrary\steamapps\common' -Directory
Get-ChildItem 'Z:\Games\SteamLibrary\steamapps\common' -Directory
```

- `libraryfolders.vdf` is the source for **registered** libraries; `appmanifest_*.acf` files are the source for **installed** apps. The live audit compares both.
- A folder under `common\` with no appmanifest is a leftover, not an install.
