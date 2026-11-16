# Software Documentation — Installed Apps

> Updated: 16 Nov 2026 — full re-inventory from registry ARP + on-disk paths + file versions.
> Managers: **winget** (primary) · **scoop** not installed · Chocolatey 2.7.4 present but unused
> System runtimes (VC++, .NET) are listed only where they affect the setup.

## Install Policy

Order of preference, no exceptions without a note in the table:

1. **winget** package
2. **Vendor installer** (when winget has no usable manifest)
3. **scoop** — last resort; not installed today

Scope: **all users / machine-wide first**. Per-user only when the vendor requires it.

- **Per-user exceptions:** Discord, Twinkle Tray, LocalSend, DeepSeek Harness, T3 Code, Roblox, Windows Terminal / Realtek Audio Control (MSIX), Notion (AppX).
- **Excluded by request:** Razer Synapse, MCHOSE Hub, vJoy. PXN SimRacing is installed, but its bundled vJoy driver is not.
- **Removal:** `winget uninstall --id <id> --exact` from an **elevated** shell (machine-wide packages need UAC).

## Machine-wide (Program Files)

| Software | Version | Location | Notes |
|----------|---------|----------|-------|
| **Git** | 2.56.0.4 | `C:\Program Files\Git` | `cmd` on machine PATH |
| **7-Zip** | 26.06 | `C:\Program Files\7-Zip` | Archive utility |
| **PowerShell 7** | 7.6.10 | `C:\Program Files\PowerShell\7` | Official all-users MSI; never upgrade from inside `update` |
| **Python 3.14** | 3.14.10 | `C:\Program Files\Python314` | Official all-users installer; PATH set |
| **GitHub CLI** | 2.104.0 | `C:\Program Files\GitHub CLI` | `gh` on machine PATH |
| **FFmpeg** | 9.0.2 | `C:\Program Files\FFmpeg\bin` | Manual (gyan.dev build), no ARP entry; PATH set |
| **Steam** | 2.10.91.91 | `C:\Program Files (x86)\Steam` | `V:` library registered; `Z:` library still unregistered (see Notes) |
| **PotPlayer** | 26.10.21.0 | `C:\Program Files\DAUM\PotPlayer` | 64-bit; signed Kakao build |
| **HWiNFO** | 8.54 | `C:\Program Files\HWiNFO64` | Hardware monitoring |
| **Radmin VPN** | 2.1.4952.2 | `C:\Program Files (x86)\Radmin VPN` | LAN emulation for gaming |
| **PXN SimRacing** | 1.6.8.0 app (ARP shows 1.2.0.0) | `C:\Program Files (x86)\PXNSimRacing` | V10 Pro base/pedal config; unsigned vendor app; the ARP version comes from `uninst.exe`, the app itself is 1.6.8.0 |
| **Focusrite Control 2** | 1.1210.0.0 | `C:\Program Files\Focusrite\Focusrite Control 2` | Includes Focusrite Audio Drivers 4.150.0.432 |
| **AMD Software: Adrenalin** | 26.10.1 | `C:\Program Files\AMD` | RX 7600 driver 32.0.32015.7029; also installs AMD Settings, DVR, WVR, RyzenMasterSDK, Install Manager |
| **AMD Chipset Software** | 8.09.28.1124 | DriverStore | B450 chipset, GPIO, SMBus, PCI, PSP, Ryzen power plan. ARP still points at the old `C:\AMD\Chipset_Software` installer path |
| **Realtek Audio Driver** | 6.0.9231.1 | `C:\Program Files (x86)\Realtek\Audio` | Includes Realtek Audio Control |
| **Realtek Ethernet Driver** | 10.50.511.2021 | `C:\Program Files (x86)\Realtek\NICDRV_8169` | RTL8168 1 Gbps |
| **Revision Tool** | 2.15.1 | `C:\Program Files\Revision Tool` | ReviOS control panel |
| **Google Chrome** | 157.0.8103.51 | `C:\Program Files\Google\Chrome` | Primary browser |
| **Mozilla Firefox** | 160.0 | `C:\Program Files\Mozilla Firefox` | Backup browser |
| **OBS Studio** | 33.0.1 | `C:\Program Files\obs-studio` | Installed 24 Oct; **never launched** (no `%APPDATA%\obs-studio` profile yet) |
| **ExitLag** | 5.23.3 | `C:\Program Files\ExitLag` | Route optimizer |
| **GenOffice** | 0.13.18 | `C:\Program Files\GenOffice` | Office-suite shell; self-updater in `%LOCALAPPDATA%` |
| **ActivityWatch** | 0.14.3 | `C:\Program Files (x86)\ActivityWatch` | Time tracker; auto-starts from the user Startup folder |
| **Riot Vanguard** | 1.19.2-23 | `C:\Program Files\Riot Vanguard` | VALORANT anti-cheat; kernel driver, auto-starts |
| **Microsoft Visual C++ 2015–2022** | 14.52.37029 | x64 + x86 | Runtime dependency; older 2010/2012/2013 runtimes also present |
| **Microsoft .NET 8 (Host + Desktop Runtime)** | 8.0.34 | — | Runtime dependency; pulled in by OBS/ExitLag |

## Per-user / MSIX

| Software | Version | Location | Notes |
|----------|---------|----------|-------|
| **Discord** | 1.0.9265 | `%LOCALAPPDATA%\Discord` | Squirrel; per-user only |
| **Twinkle Tray** | 1.17.2 | `%LOCALAPPDATA%\Programs\twinkle-tray` | Electron; per-user only; needs MPRT off |
| **LocalSend** | 1.18.2 | `%LOCALAPPDATA%\Programs\LocalSend` | LAN file transfer |
| **DeepSeek Harness** | 0.2.2-rc.3 | `%LOCALAPPDATA%\Programs\DeepSeek Harness` | Current AI coding harness |
| **T3 Code (Beta)** | 0.1.9 | `%LOCALAPPDATA%\Programs\t3code` | Pinned on the taskbar |
| **Roblox Player** | — | `%LOCALAPPDATA%\Roblox` | Auto-starts to tray; Studio also present |
| **Notion** | _needs-review_ | AppX | Installed 16 Nov; packaged, version not readable without AppX enumeration |
| **Windows Terminal** | 1.24.11911.0 | MSIX | Store package; pinned |
| **Realtek Audio Control** | 1.1.137.0 | MSIX | Installed with the Realtek audio driver (last verified 23 Oct) |
| **Microsoft Edge WebView2** | 157.0.4341.60 | `C:\Program Files (x86)\Microsoft\EdgeWebView` | Runtime dependency |
| **Store apps** | — | MSIX | Paint, Notepad, Calculator, Photos, Snipping Tool, Xbox/Game Bar, Phone Link |

## Drivers

| Component | Version | Notes |
|-----------|---------|-------|
| AMD Chipset | 8.09.28.1124 | Fixes `ACPI\AMDIF030` (AMD GPIO) |
| AMD GPU | 32.0.32015.7029 (Adrenalin 26.10.1) | RX 7600; 1080p @ 300 Hz |
| MSI MAG 255XF monitor | 1.0.0.0 (2024-07-29) | WHQL `oem30.inf` + `MSI MAG 255XF.icm`; 300 Hz DP mode |
| Realtek Audio (ALC897) | 6.0.9231.1 | No analog endpoint currently active |
| Realtek LAN (RTL8168) | 10.50.511.2021 | 1 Gbps, link up |
| Focusrite Scarlett Solo | 4.150.0.432 | With Control 2 1.1210 |

Device Manager had no problem devices at the 23 Oct check; not re-verified 16 Nov (WMI/CIM is blocked inside agent sessions — see `audit-playbook.md`).

## Deliberately Not Installed

- **Old 23H2 app set:** not reinstalled. The previous inventory remains in Git history.
- **Excluded by request:** Razer Synapse, MCHOSE Hub, vJoy.
- **Not reinstalled since the rebuild:** ShareX, DroidCam client + OBS plugin, input-overlay. (`C:\Program Files\DroidCam` exists but is empty — that is not an install.)
- **Steam games** stay on `V:\Games\SteamLibrary` and `Z:\Games\SteamLibrary`.

## Removed

| Software | Removed | How |
|----------|---------|-----|
| **Notepad++ 8.9.9.1** | 16 Nov 2026 | `winget uninstall` (elevated) — was only installed while troubleshooting the shell bug |
| **Obsidian 1.15.1** | 16 Nov 2026 | `winget uninstall` (elevated), NSIS uninstaller finished the job; the `Documents\Obsidian Vault` folder was left in place |

## Notes

- **winget machine scope is broken on this build:** `winget install --scope machine` returns `0x80070005`. Default-scope installs were verified to land in `Program Files`; PowerShell and Python were normalized with official all-users MSIs, and FFmpeg was moved manually.
- **`winget source update`** fixes `Failed to open the predefined source`.
- **winget dies inside a sandboxed agent session** with `0x8A150001` (every verb, including `--info`). Run winget from a normal elevated shell.
- **Steam libraries:** `V:\Games\SteamLibrary` is registered in `libraryfolders.vdf` (6 apps). `Z:\Games\SteamLibrary` has 2 app manifests on disk but is **not** registered — add it from Steam → Settings → Storage.
- **PXN:** installer is unsigned (official PXN domain); app reports 1.6.8.0; vJoy not installed.
- **MPRT:** no DDC/CI VCP on this monitor; Twinkle Tray brightness requires MPRT off.
- **Disk:** C: 66.5 GB free of 126.1 GB; V: 76.4 GB; Z: 481.1 GB.
- **`ProductName` lies:** the registry reports **Windows 10 Pro** on this 26H2 image. ReviOS left it stale — trust `DisplayVersion` + `CurrentBuild.UBR`, not `ProductName`.
- **Not installs, despite looking like it:** `C:\tools\php84` holds only a `php.ini` (no binary, no `php` on PATH) and `C:\AMD\Chipset_Software` holds a single log file. An empty folder or stray config is not an install.
