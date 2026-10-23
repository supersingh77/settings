# Software Documentation — Installed Apps

> Updated: 23 Oct 2026 — clean ReviOS 26H2 install; checked against live `winget list`, ARP, Appx and on-disk paths
> Managers: **winget** (primary) · **scoop** (not installed yet) · Chocolatey 2.7.4 present but unused
> System/runtime components (VC++ runtimes, .NET, Xbox services) are listed only where they affect the setup.

---

## Machine-wide (Program Files)

| Software | Version | Location | Notes |
|----------|---------|----------|-------|
| **Git** | 2.55.0.5 | `C:\Program Files\Git` | Git for Windows; `C:\Program Files\Git\cmd` on machine PATH |
| **7-Zip** | 26.05 | `C:\Program Files\7-Zip` | Archive utility |
| **PowerShell 7** | 7.6.7 | `C:\Program Files\PowerShell\7` | Official Microsoft MSI, all users |
| **Python 3.14** | 3.14.7 | `C:\Program Files\Python314` | Official python.org installer, all users, PATH set |
| **GitHub CLI** | 2.103.0 | `C:\Program Files\GitHub CLI` | `gh` on machine PATH |
| **FFmpeg** | 9.0.2 | `C:\Program Files\FFmpeg\bin` | Moved out of winget's per-user cache; machine PATH set |
| **Steam** | 2.10.91.91 | `C:\Program Files (x86)\Steam` | First launch will update the client |
| **PotPlayer** | 26.10.21.0 | `C:\Program Files\DAUM\PotPlayer` | 64-bit; installed from the signed Kakao build |
| **HWiNFO** | 8.54 | `C:\Program Files\HWiNFO64` | Hardware monitoring |
| **Radmin VPN** | 2.1.4951.1 | `C:\Program Files (x86)\Radmin VPN` | LAN emulation for gaming |
| **PXN SimRacing** | 1.6.8.0 (installer 1.6.9) | `C:\Program Files (x86)\PXNSimRacing` | V10 Pro wheel/pedal config; A7 Gear Shift is a separate HID controller. Unsigned vendor app. |
| **Focusrite Control 2** | 1.1210.0.0 | `C:\Program Files\Focusrite\Focusrite Control 2` | Includes Focusrite Audio Drivers 4.150.0.432 |
| **AMD Software: Adrenalin** | 26.10.1 | `C:\Program Files\AMD` | RX 7600 driver 32.0.32015.7029 |
| **AMD Chipset Software** | 8.09.28.1124 | `C:\AMD\Chipset_Software` | B450 chipset, GPIO, SMBus, PCI, PSP, Ryzen power plan |
| **Realtek Audio Driver** | 6.0.9231.1 | DriverStore | Includes Realtek Audio Control |
| **Realtek Ethernet Driver** | 10.50.511.2021 | DriverStore | RTL8168 1 Gbps |
| **Revision Tool** | 2.14.4 | `C:\Program Files\Revision Tool` | ReviOS control panel |
| **Google Chrome** | 156.0.8078.48 | `C:\Program Files\Google\Chrome` | Primary browser |
| **Mozilla Firefox** | 158.0.1 | `C:\Program Files\Mozilla Firefox` | Backup browser |
| **Microsoft Visual C++ 2015–2022** | 14.51.36247.0 | x64 + x86 | Runtime dependency |

---

## Per-user / MSIX

| Software | Version | Location | Notes |
|----------|---------|----------|-------|
| **Discord** | 1.0.9265 | `%LOCALAPPDATA%\Discord` | Squirrel installer; per-user only |
| **Twinkle Tray** | 1.17.2 | `%LOCALAPPDATA%\Programs\twinkle-tray` | Electron app; per-user only |
| **LocalSend** | 1.18.2 | `%LOCALAPPDATA%\Programs\LocalSend` | LAN file transfer |
| **DeepSeek Harness** | 0.2.1-rc.2 | `%LOCALAPPDATA%\Programs\DeepSeek Harness` | Current AI coding harness |
| **Windows Terminal** | 1.24.11911.0 | MSIX | Store package |
| **Realtek Audio Control** | 1.1.137.0 | MSIX | Installed with the Realtek audio driver |
| **Store apps** | — | MSIX | Paint, Notepad, Calculator, Photos, Snipping Tool, Xbox/Game Bar, Phone Link |

---

## Drivers

| Component | Version | Notes |
|-----------|---------|-------|
| AMD Chipset | 8.09.28.1124 | Fixes `ACPI\AMDIF030` (AMD GPIO) |
| AMD GPU | 32.0.32015.7029 (Adrenalin 26.10.1) | RX 7600; 1920×1080 @ 300 Hz |
| MSI MAG 255XF monitor | 1.0.0.0 (2024-07-29) | WHQL INF `oem30.inf` + `MSI MAG 255XF.icm`; 300 Hz DP mode |
| Realtek Audio (ALC897) | 6.0.9231.1 | No analog endpoint currently active (no speakers detected) |
| Realtek LAN (RTL8168) | 10.50.511.2021 | 1 Gbps, link up |
| Focusrite Scarlett Solo | 4.150.0.432 | With Control 2 1.1210 |

No problem devices in Device Manager after the rebuild.

---

## Not reinstalled yet (from the previous 23H2 install)

These were documented before the clean install but are **not currently installed**:

| Category | Apps |
|----------|------|
| Streaming | OBS Studio, ShareX, DroidCam Client, DroidCam OBS Plugin, input-overlay |
| Media | VLC, MediaInfo, HandBrake, Foxit PDF Reader |
| Utilities | AutoHotkey, CPU-Z, LibreOffice, PicoTorrent, ExitLag, FxSound |
| Productivity | Microsoft Office 2021, DaVinci Resolve, Guitar Pro 8, Clockify |
| AI tools | Cursor, Claude, ChatGPT/Codex, Kimi, Antigravity, AutoClaw, ZCode, MiniMax Code, OpenWork Cloud |
| Input/gaming | vJoy, PXN SimRacing, Steam games (still on E:/D:) |

The old app list is preserved in Git history if any of these need to come back.

---

## Notes

- **winget machine scope is broken on this build:** `winget install --scope machine` returns `0x80070005` (“Failed to open the predefined source”). Default-scope installs were used instead; PowerShell and Python were then normalized with their official all-users MSIs, and FFmpeg was moved to `Program Files`.
- **`winget source update`** is the fix if winget starts returning “Failed to open the predefined source” even for `search`.
- **Discord, Twinkle Tray and LocalSend are per-user by design** — their installers do not offer a machine-wide mode.
- **Steam libraries:** `E:\Games\SteamLibrary` (6 game folders) and `D:\Games\SteamLibrary` (2 game folders) survived. Steam's config did not; add both libraries on first launch.
- **Disk:** C: 53.6 GB free of 126.1 GB; E: 137.6 GB free; D: 488.4 GB free.
- **Scoop** is intentionally not installed yet. Old scoop-only tools were `dark` and `innounp`; install scoop only if those are needed again.
