# Laptop (Windows) — ASUS ROG Strix G513QY

> Status: Active | Last updated: 12 August 2026

## Quick Reference

- **Model**: ASUSTeK ROG Strix G513QY (Advantage Edition)
- **OS**: Windows 11 Home (Build 26200)
- **CPU**: AMD Ryzen 9 5900HX (8C/16T)
- **GPU**: AMD Radeon RX 6800M (12 GB GDDR6) + Radeon iGPU
- **RAM**: 32 GB DDR4-3200 (2x16GB Kingston)
- **Storage**: C: (~250 GB NVMe SSD) | D: (~700 GB NVMe SSD)

## Documentation

- [Hardware Specs & Storage Strategy](hardware.md) — full component breakdown, VRAM headroom, drive allocation
- [Software Inventory & Desktop Differences](software.md) — installed winget/scoop packages, excluded items, maintenance workflow
- [Scripts/](scripts/) — `cleanup-system.ps1`

## Setup Notes

1. **Storage Rules**: Core tools, shells, and desktop utilities on `C:\`. Steam library, large mod packs, and OBS video output on `D:\`.
2. **Power & Fan Control**: Use ASUS Armoury Crate or G-Helper for fan profiles (Performance / Turbo / Silent). Ryzen Master not needed — mobile CPUs handle thermal targets dynamically.
3. **Peripheral & Audio Routing**: Built-in Wi-Fi 6 & Bluetooth for wireless peripherals. OBS uses AMD AMF hardware encoder natively for 1080p / 1440p recording and streaming.
