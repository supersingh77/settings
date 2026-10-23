# PC Hardware Documentation

> Updated: 23 Oct 2026 — clean ReviOS 26H2 install; specs, drivers and volumes verified live (CIM/WMI + `Get-Volume`)
> Purpose: Streaming / gaming setup baseline
> Migration note: this install replaced the previous Atlas OS setup. The old **V:** drive is now **E:**, and the old **Z:** drive is now **D:**. Older notes that still say V:/Z: are pre-rebuild.

---

## System Overview

| Component | Detail |
|-----------|--------|
| **OS** | Microsoft Windows 11 Pro 26H2 — build **26300.9457** (ReviOS) |
| **Form Factor** | Desktop (custom build, ASRock B450M-HDV R4.0) |
| **BIOS** | American Megatrends P10.60 (2026-04-17) |

---

## CPU

| Property | Value |
|----------|-------|
| **Model** | AMD Ryzen 7 5700X |
| **Cores / Threads** | 8 / 16 |
| **Base Clock** | 3.4 GHz (3401 MHz) |
| **L2 Cache** | 4 MB |
| **L3 Cache** | 32 MB |
| **Cooling** | _(not detected — check if stock or aftermarket)_ |
| **Notes** | 8 cores handle gaming + streaming simultaneously; AMF encoding keeps the CPU free. |

---

## GPU

| Property | Value |
|----------|-------|
| **Model** | AMD Radeon RX 7600 |
| **VRAM** | 8 GB GDDR6 |
| **Driver** | AMD Software: Adrenalin Edition **26.10.1** (driver **32.0.32015.7029**, 2026-10-18) |
| **Monitor** | MSI MAG 255XF — 1920×1080 @ **300 Hz** (primary); BenQ RL2240H secondary |
| **Notes** | RX 7600 supports **AMD AMF** hardware encoding (H.264/H.265) for OBS. WMI `AdapterRAM` reports ~4 GB because it is a 32-bit field; the card's actual VRAM is **8 GB**. |

---

## Memory (RAM)

| Property | Value |
|----------|-------|
| **Total** | 16 GB (15.9 GB usable) |
| **Configuration** | 2 × 8 GB DDR4 (Kingston KF3200C16D4/8GX + G.Skill F4-3000C15-8GVRB) |
| **Speed** | 3000 MT/s (both modules; below the 3200 rating of the Kingston kit) |
| **Notes** | 16 GB is the minimum comfortable baseline for 1080p gaming + OBS. Close browser tabs before streaming. |

---

## Storage

| Drive | Label | Type | Capacity | Free Space | Notes |
|-------|-------|------|----------|------------|-------|
| **C:** | _(System)_ | SSD (NVMe) — XPG GAMMIX S11 Pro | 126.1 GB | **53.6 GB** | ✅ Healthy. Windows + core apps only. |
| **E:** | Vacuum Drive | SSD (NVMe) — XPG GAMMIX S11 Pro | 350 GB | 137.6 GB | Games & streaming software. Formerly **V:**. |
| **D:** | Mass Storage | HDD — Seagate ST1000DM010 (1 TB) | 931.5 GB | 488.4 GB | Recordings, VODs, clips, OBS output. Formerly **Z:**. |

**SSD Details:**
- XPG GAMMIX S11 Pro — NVMe, 512 GB total (partitioned as C: + E:)
- Seagate ST1000DM010 — SATA HDD, 1 TB
- Both healthy

### Storage Notes
- C: is no longer critical after the clean install (**53.6 GB free** vs 13 GB before).
- Existing Steam libraries survived: `E:\Games\SteamLibrary` (6 game folders) and `D:\Games\SteamLibrary` (2 game folders).
- Steam's own config was on the old C: install, so the two libraries must be re-added on first Steam launch.

---

## Network

| Adapter | Type | Status | Speed | Notes |
|---------|------|--------|-------|-------|
| Realtek PCIe GbE (RTL8168) | Wired | ✅ Up | 1 Gbps | Driver **10.50.511.2021** (2021-05-11). Primary internet. |
| **Wi-Fi** | ❌ **Not detected** | — | — | No built-in Wi-Fi; DroidCam/phone must use the LAN. |

**IP:** 192.168.1.11 / 192.168.1.1

---

## Audio

| Device | Type | Status |
|--------|------|--------|
| **Realtek ALC897** (onboard) | Motherboard audio | Driver **6.0.9231.1** + Realtek Audio Control installed. No analog endpoint currently active (no speakers detected). |
| **Focusrite Scarlett Solo** (4th gen) | USB audio interface | Driver **4.150.0.432** + Focusrite Control 2 **1.1210**. Working. |
| **Razer Barracuda X 2.4** | USB wireless headset | Working; mic + headphones endpoints present. |
| **AMD HDMI Audio** | GPU audio to monitors | Working; endpoints for MAG 255XF and BenQ RL2240H. |

**Notes:** For streaming, capture game audio from the Focusrite/Razer endpoint and mic separately in OBS. The onboard Realtek analog jacks are currently unused.

---

## Peripherals

| Device | Notes |
|--------|-------|
| Monitor (primary) | MSI MAG 255XF — 1920×1080, 300 Hz |
| Monitor (secondary) | BenQ RL2240H — 1920×1080, 60 Hz |
| Audio interface | Focusrite Scarlett Solo 4th gen |
| Headset | Razer Barracuda X 2.4 |
| Wheel + pedals | PXN V10 Pro (`VID_36E6&PID_400B`) — PXN SimRacing detects the base and reads pedal/keymap settings |
| Shifter | A7 Gear Shift (`VID_11FF&PID_B772`) — appears as a separate HID game controller; bind it per game |
| Controller | Xbox 360 controller on a third-party wireless receiver (`VID_3537&PID_1093`) |
| Phone (webcam) | DroidCam over LAN — client/plugin not reinstalled yet |

### Known quirk — Xbox 360 receiver opens Task View

When the controller is **powered off**, the third-party receiver can emit phantom `Win+Tab` / Task View input. It shows up as Task View opening when right-clicking the desktop or clicking the taskbar. **Powering the controller on stops it immediately** (verified 2026-10-23) because the receiver switches out of its idle/emulated keyboard-mouse state.

Permanent options:
- Unplug the receiver when not gaming (cleanest).
- Leave the controller powered on while the receiver is plugged in (battery drain; it may sleep and bring the issue back).
- Replace the third-party dongle with a genuine Xbox Wireless Adapter or use a wired controller.

No Windows setting or driver was at fault.

---

## Summary & Bottleneck Check

| Area | Verdict |
|------|---------|
| **CPU** | ✅ Ryzen 7 5700X (8C/16T) — excellent for gaming + streaming |
| **GPU** | ✅ RX 7600 8 GB — comfortable for 1080p gaming + AMF streaming |
| **RAM** | ✅ 16 GB — adequate for 1080p streaming |
| **Storage** | ✅ C: 53.6 GB free; E: 137.6 GB; D: 488.4 GB |
| **Network** | ✅ 1 Gbps Ethernet — plenty of headroom |
| **Audio** | ✅ Focusrite + Razer + Realtek all healthy |
