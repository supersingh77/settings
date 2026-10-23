# Desktop PC — Custom Build

> Status: Active | Last verified: 23 Oct 2026 | OS: ReviOS 26H2

## Quick Reference

| Item | Detail |
|------|--------|
| **OS** | Windows 11 Pro 26H2 — build **26300.9457** (ReviOS) |
| **Board / BIOS** | ASRock B450M-HDV R4.0 / AMI P10.60 (2026-04-17) |
| **CPU** | AMD Ryzen 7 5700X (8C/16T) |
| **GPU** | AMD Radeon RX 7600 8 GB — Adrenalin 26.10.1 |
| **RAM** | 16 GB DDR4-3000 (2 × 8 GB) |
| **Storage** | C: 126 GB system (**98.8 GB free**) · E: 350 GB games · D: 1 TB archive |
| **Display** | MSI MAG 255XF — 1080p @ **300 Hz** |
| **Role** | Gaming + streaming |

## Documentation

| Doc | Covers |
|-----|--------|
| [Hardware](hardware.md) | Components, drivers, storage, audio/network, known quirks |
| [Software](software.md) | Installed apps, versions, install scope, drivers, exclusions |
| [Taskbar & Start](startmenu-taskbar.md) | Current pins, verified order |
| [Desktop Layout](desktop.md) | Actual `C:\Users\amar\Desktop` contents |
| [Disk Cleanup](disk-cleanup.md) | Drive map, recurring checklist, last cleanup result |
| [Audit Playbook](audit-playbook.md) | Commands to verify pins/apps/drivers/Steam live |
| [Scripts](scripts/README.md) | Maintenance, video join, legacy scroll-fix scripts |

## Setup Rules

1. **Storage:** C: = OS + core apps. Games/streaming software → E:. Recordings, VODs, archives → D:.
2. **Apps:** winget **machine-wide** first. Per-user only when the vendor requires it (Discord, Twinkle Tray, LocalSend, DeepSeek Harness, Windows Terminal/Realtek MSIX). No Razer Synapse, MCHOSE Hub, or vJoy.
3. **Display:** keep 300 Hz for desktop/gaming. MPRT must be **off** for Twinkle Tray brightness; MPRT has no DDC/CI control.
4. **Controllers:** the third-party Xbox 360 receiver opens Task View when the controller is off — unplug it or keep the controller on. PXN A7 shifter enumerates separately from the V10 Pro wheel.
5. **Before editing:** run the checks in [audit-playbook.md](audit-playbook.md). Bump the `Updated` date and record only verified values.

## Current Gaps

- OBS, ShareX, DroidCam, and input-overlay are not reinstalled.
- Steam is installed but its library config is fresh: re-add `E:\Games\SteamLibrary` and `D:\Games\SteamLibrary`.
- PXN SimRacing is installed and detects the wheel; in-game shifter binding still needs a sim.
