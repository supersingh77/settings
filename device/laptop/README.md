# Windows laptop — ASUS ROG Strix G513QY

## Documentation

- [Hardware Specs & Storage Strategy](hardware.md) — full component breakdown, VRAM headroom, drive allocation
- [Software Inventory & Desktop Differences](software.md) — installed winget/scoop packages, excluded items, maintenance workflow
- [Cleanup script](scripts/cleanup-system.ps1) — preview maintenance with `-DryRun` first.

## Setup Notes

1. **Storage Rules**: Core tools, shells, and desktop utilities on `C:\`. Steam library, large mod packs, and OBS video output on `D:\`.
2. **Power & Fan Control**: Use ASUS Armoury Crate or G-Helper for fan profiles (Performance / Turbo / Silent). Ryzen Master not needed — mobile CPUs handle thermal targets dynamically.
3. **Peripheral & Audio Routing**: Built-in Wi-Fi 6 & Bluetooth for wireless peripherals. OBS uses AMD AMF hardware encoder natively for 1080p / 1440p recording and streaming.

## Cleanup script

Run from the repository root in PowerShell 7:

```powershell
pwsh device/laptop/scripts/cleanup-system.ps1 -DryRun
```

The script handles Scoop cache and old versions, temporary files, DISM component cleanup, Recycle Bin, DNS, and Delivery Optimization cache. Review the dry run before applying; DISM requires elevation. Its dry run was checked on the desktop, not this laptop.
