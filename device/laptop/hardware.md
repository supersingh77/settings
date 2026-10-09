# Laptop Hardware Documentation — ASUS ROG Strix G513QY

> Documented: 12 August 2026 | Updated: 13 August 2026
> Purpose: Laptop hardware baseline & specs record
> Source: Windows CIM queries (Win32_*), machine: `DESKTOP-78G1F9P`

---

## Machine

| Field | Value |
|---|---|
| Manufacturer | ASUSTeK COMPUTER INC. |
| Model | ROG Strix G513QY (Advantage Edition), board: G513QY |
| Series | ROG Strix |
| Form factor | Gaming Laptop (PCSystemType: Portable) |
| BIOS | American Megatrends, version G513QY.331 (2023-02-24) |
| Serial number | MANRKD031592412 |

## Operating System

| Field | Value |
|---|---|
| OS | Microsoft Windows 11 Home, 64-bit |
| Version / Build | 10.0.26200 (build 26200) |
| Installed | 2025-02-21 |
| Last boot | 2026-08-12 20:30 |

---

## CPU

| Property | Value |
|---|---|
| **Model** | AMD Ryzen 9 5900HX with Radeon Graphics |
| **Cores / Threads** | 8 cores / 16 threads |
| **Base Clock** | 3.3 GHz (boost up to 4.6 GHz per AMD spec) |
| **L2 / L3 Cache** | 4 MB / 16 MB |
| **Tuning / Control** | Managed natively via ASUS Armoury Crate / G-Helper & Windows Power Plans *(Ryzen Master not required)* |

---

## Memory (RAM)

| Property | Value |
|---|---|
| **Total** | 32 GB (31.4 GB usable) |
| **Configuration** | 2 × 16 GB Kingston KF3200C20S4/16G (DDR4 SODIMM) |
| **Speed** | 3200 MT/s |

---

## Graphics

| Property | Value |
|---|---|
| **Discrete GPU** | AMD Radeon RX 6800M (driver 32.0.21045.1000) |
| **Integrated GPU** | AMD Radeon(TM) Graphics — Vega iGPU (driver 31.0.21923.11000) |
| **VRAM** | 12 GB GDDR6 — high headroom for gaming & OBS hardware encoding |
| **Encoder** | AMD AMF (H.264 / H.265) |
| **Display** | 2560 x 1440 (laptop panel) |

> Note: WMI reports the RX 6800M's video memory as ~4 GB due to a 32-bit
> reporting limit; actual VRAM is 12 GB GDDR6 per spec.

---

## Storage Layout

| Drive | Label | Type | Capacity | Free Space | Usage Guidelines |
|---|---|---|---|---|---|
| **C:** | System Drive | NVMe SSD (Intel 670p, 1 TB total) | ~249 GB | ~141.1 GB | Operating System, core desktop apps, system tools |
| **D:** | Media | NVMe SSD (same drive) | ~703.8 GB | ~502.9 GB | Games (Steam library), OBS recordings, heavy media assets |

- Single 1 TB Intel SSDPEKNU010TZ (Intel 670p) NVMe SSD, split into C: and D:.

---

## Network & Connectivity

| Interface | Hardware | Status | Speed |
|---|---|---|---|
| Wi-Fi 6 | MediaTek Wi-Fi 6 MT7921 Wireless LAN Card | Up | 720.5 Mbps |
| Ethernet | Realtek PCIe GbE Family Controller | Disconnected (no cable) | 1 Gbps capable |

MAC addresses: Ethernet `04-42-1A-D1-63-9C`, Wi-Fi `90-E8-68-D1-2B-81`

---

## Battery

| Field | Value |
|---|---|
| Model | GA50358 |
| Charge at inventory time | 60 % |

---

## Summary & Hardware Notes vs Desktop

- **Processing & Memory**: Ryzen 9 5900HX + 32 GB RAM provides ample compute and memory for gaming, development, and streaming.
- **VRAM Headroom**: 12 GB VRAM on RX 6800M resolves the 4 GB VRAM bottleneck present on the desktop RX 7600.
- **Storage Strategy**: Keep `C:` for OS and core apps; route Steam library and OBS recordings to `D:\`.
- **Power & Fan Control**: Use ASUS Armoury Crate or G-Helper for fan profiles (Performance / Turbo / Silent). Ryzen Master is excluded — mobile CPUs handle thermal targets dynamically.
