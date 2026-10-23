# Software Documentation — Installed Apps

> Updated: 23 Oct 2026 — checked live against `winget list`, ARP, Appx and on-disk paths
> Managers: **winget** (primary) · **scoop** not installed · Chocolatey 2.7.4 present but unused
> System runtimes (VC++, .NET) are listed only where they affect the setup.

## Install Policy

- **Machine-wide first** (`Program Files`). Use per-user only when the vendor requires it.
- **Per-user exceptions:** Discord, Twinkle Tray, LocalSend, DeepSeek Harness, Windows Terminal/Realtek Audio Control (MSIX).
- **Excluded by request:** Razer Synapse, MCHOSE Hub, vJoy. PXN SimRacing is installed, but its bundled vJoy driver is not.

## Machine-wide (Program Files)

| Software | Version | Location | Notes |
|----------|---------|----------|-------|
| **Git** | 2.55.0.5 | `C:\Program Files\Git` | `cmd` on machine PATH |
| **7-Zip** | 26.05 | `C:\Program Files\7-Zip` | Archive utility |
| **PowerShell 7** | 7.6.7 | `C:\Program Files\PowerShell\7` | Official all-users MSI |
| **Python 3.14** | 3.14.7 | `C:\Program Files\Python314` | Official all-users installer; PATH set |
| **GitHub CLI** | 2.103.0 | `C:\Program Files\GitHub CLI` | `gh` on machine PATH |
| **FFmpeg** | 9.0.2 | `C:\Program Files\FFmpeg\bin` | Moved out of winget's per-user cache; PATH set |
| **Steam** | 2.10.91.91 | `C:\Program Files (x86)\Steam` | First launch updates the client; libraries need re-adding |
| **PotPlayer** | 26.10.21.0 | `C:\Program Files\DAUM\PotPlayer` | 64-bit; signed Kakao build |
| **HWiNFO** | 8.54 | `C:\Program Files\HWiNFO64` | Hardware monitoring |
| **Radmin VPN** | 2.1.4951.1 | `C:\Program Files (x86)\Radmin VPN` | LAN emulation for gaming |
| **PXN SimRacing** | 1.6.8.0 (installer 1.6.9) | `C:\Program Files (x86)\PXNSimRacing` | V10 Pro base/pedal config; unsigned vendor app; A7 shifter is separate |
| **Focusrite Control 2** | 1.1210.0.0 | `C:\Program Files\Focusrite\Focusrite Control 2` | Includes Focusrite Audio Drivers 4.150.0.432 |
| **AMD Software: Adrenalin** | 26.10.1 | `C:\Program Files\AMD` | RX 7600 driver 32.0.32015.7029 |
| **AMD Chipset Software** | 8.09.28.1124 | `C:\AMD\Chipset_Software` | B450 chipset, GPIO, SMBus, PCI, PSP, Ryzen power plan |
| **Realtek Audio Driver** | 6.0.9231.1 | DriverStore | Includes Realtek Audio Control |
| **Realtek Ethernet Driver** | 10.50.511.2021 | DriverStore | RTL8168 1 Gbps |
| **Revision Tool** | 2.14.4 | `C:\Program Files\Revision Tool` | ReviOS control panel |
| **Google Chrome** | 156.0.8078.48 | `C:\Program Files\Google\Chrome` | Primary browser |
| **Mozilla Firefox** | 158.0.1 | `C:\Program Files\Mozilla Firefox` | Backup browser |
| **Microsoft Visual C++ 2015–2022** | 14.51.36247.0 | x64 + x86 | Runtime dependency |

## Per-user / MSIX

| Software | Version | Location | Notes |
|----------|---------|----------|-------|
| **Discord** | 1.0.9265 | `%LOCALAPPDATA%\Discord` | Squirrel; per-user only |
| **Twinkle Tray** | 1.17.2 | `%LOCALAPPDATA%\Programs\twinkle-tray` | Electron; per-user only; needs MPRT off |
| **LocalSend** | 1.18.2 | `%LOCALAPPDATA%\Programs\LocalSend` | LAN file transfer |
| **DeepSeek Harness** | 0.2.1-rc.2 | `%LOCALAPPDATA%\Programs\DeepSeek Harness` | Current AI coding harness |
| **Windows Terminal** | 1.24.11911.0 | MSIX | Store package |
| **Realtek Audio Control** | 1.1.137.0 | MSIX | Installed with the Realtek audio driver |
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

No problem devices in Device Manager after the rebuild.

## Deliberately Not Installed

- **Old 23H2 app set:** not reinstalled. The previous inventory remains in Git history.
- **Excluded by request:** Razer Synapse, MCHOSE Hub, vJoy.
- **Steam games** remain on `E:\Games\SteamLibrary` and `D:\Games\SteamLibrary`; the Steam client config is fresh.

## Notes

- **winget machine scope is broken on this build:** `winget install --scope machine` returns `0x80070005`. Default-scope installs were verified to land in `Program Files`; PowerShell and Python were normalized with official all-users MSIs, and FFmpeg was moved manually.
- **`winget source update`** fixes `Failed to open the predefined source`.
- **Steam libraries:** add `E:\Games\SteamLibrary` and `D:\Games\SteamLibrary` on first launch.
- **PXN:** installer is unsigned (official PXN domain); app reports 1.6.8.0; vJoy not installed.
- **MPRT:** no DDC/CI VCP on this monitor; Twinkle Tray brightness requires MPRT off.
- **Disk:** C: 98.8 GB free of 126.1 GB; E: 137.6 GB; D: 488.4 GB.
