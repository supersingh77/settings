# Desktop PC — Custom Build

> Status: Active | Last updated: 09 Oct 2026

## Quick Reference

- **Model**: Custom build — ASRock B450M-HDV R4.0, BIOS P10.60
- **OS**: Windows 11 Pro (Build 22631)
- **CPU**: AMD Ryzen 7 5700X (8C/16T)
- **GPU**: AMD Radeon RX 7600 (8 GB GDDR6) — Adrenalin 26.8.1
- **RAM**: 16 GB DDR4 (2×8 GB, 3000 MT/s)
- **Storage**: C: ~126 GB (NVMe, system) | V: ~350 GB (NVMe) | Z: ~1 TB (HDD)
- **Role**: Gaming + streaming box

## Documentation

- [Hardware Specs & Storage](hardware.md) — component breakdown, drive allocation, streaming verdict
- [Software Inventory](software.md) — installed winget/scoop apps, versions, custom scripts
- [Start Menu & Taskbar](startmenu-taskbar.md) — pinned taskbar (17) and Start menu, in true order
- [Desktop Layout](desktop.md) — the actual `C:\Users\amar\Desktop` folder (shortcuts + folders)
- [Disk Cleanup](disk-cleanup.md) — C: drive cleanup plan + sized removal candidates
- [Audit Playbook](audit-playbook.md) — verified commands for live pin/app/Steam state
- [Scripts/](scripts/) — `cleanup-system.ps1`, scroll-fix AHK scripts, `join-videos.ps1`

## Setup Notes

1. **Storage Rules**: Keep `C:` for OS + core apps only (it runs tight). Assetto Corsa and large games live on `V:`; recordings, VODs and archives go to `Z:`.
2. **Streaming**: OBS uses the AMD **AMF** hardware encoder (H.264/H.265). See [`../../notes/obs-stream-settings.md`](../../notes/obs-stream-settings.md) and [`../../notes/streaming-workflow.md`](../../notes/streaming-workflow.md).
3. **Before editing these docs**: run the checks in [`audit-playbook.md`](audit-playbook.md) first — pin lists, installed apps and Steam state change often, so verify live rather than from memory.
