# PC Hardware Documentation

> Generated: 30 May 2026 | Updated: 09 Oct 2026 — specs, driver and free space re-verified live (CIM/WMI + `Get-Volume`)
> Purpose: Streaming setup baseline

---

## System Overview

| Component | Detail |
|-----------|--------|
| **OS** | Microsoft Windows 11 Pro — Version 23H2 (Build 22631) |
| **Form Factor** | Desktop (Custom build, ASRock B450M-HDV R4.0 motherboard) |
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
| **Notes** | Great for gaming + streaming simultaneously; 8 cores handle encoding well |

---

## GPU

| Property | Value |
|----------|-------|
| **Model** | AMD Radeon RX 7600 |
| **VRAM** | 8 GB GDDR6 |
| **Driver** | AMD Software: Adrenalin Edition 26.8.1 (driver 32.0.31041.1004) |
| **Monitor** | MSI MAG 255XF — 1920×1080 |
| **Notes** | RX 7600 supports **AMD AMF** hardware encoding (H.264/H.265) for OBS. WMI `AdapterRAM` reports ~4 GB because it is a 32-bit field; the card's actual VRAM is **8 GB** (64-bit registry `HardwareInformation.qwMemorySize` = 8,573,157,376 bytes). 8 GB is comfortable for 1080p gaming + streaming. |

---

## Memory (RAM)

| Property | Value |
|----------|-------|
| **Total** | 16 GB (15.9 GB usable) |
| **Configuration** | 2 × 8 GB DDR4 (Kingston KF3200C16D4/8GX + G.Skill F4-3000C15-8GVRB) |
| **Speed** | 3000 MT/s (both modules report 3000, below their 3200 rated speed) |
| **Notes** | 16 GB is the minimum recommended for streaming. Fine for Assetto Corsa + OBS at 1080p, but closing browser tabs before streaming helps. |

---

## Storage

| Drive | Label | Type | Capacity | Free Space | Notes |
|-------|-------|------|----------|------------|-------|
| **C:** | _(System)_ | SSD (NVMe) — XPG GAMMIX S11 Pro | 126 GB partition | **13.0 GB** | ⚠️ Critically low. Windows + core apps only. |
| **V:** | Vacuum Drive | SSD (NVMe) — XPG GAMMIX S11 Pro | 350 GB | 32.4 GB | ✅ Games & streaming software. Assetto Corsa lives here. |
| **Z:** | Mass Storage | HDD — Seagate ST1000DM010 (1 TB) | 931 GB | 302.9 GB | ✅ Recordings, VODs, clips, OBS recording output. |

**SSD Details:**
- XPG GAMMIX S11 Pro — NVMe, 512 GB total (partitioned as C: + V:)
- Seagate ST1000DM010 — SATA HDD, 1 TB
- Both healthy

### ⚠️ Storage Action Needed
- **C: drive is critically low** (13.0 GB free, down from 22.6 GB in May). Free space on C: or move installs to **V:** — sized removal candidates are parked in [`disk-cleanup.md`](disk-cleanup.md) §6.
- **Z: drive recovered** to 302.9 GB free (was 287.9 GB) — still the overflow/recordings target.

---

## Network

| Adapter | Type | Status | Speed | Notes |
|---------|------|--------|-------|-------|
| Realtek PCIe GbE Ethernet | Wired | ✅ Up | 1 Gbps | Primary internet. Good for streaming (stable low latency). |
| Radmin VPN | Virtual adapter | ✅ Up | — | For LAN-emulation gaming with friends. |
| **Wi-Fi** | ❌ **Not detected** | — | — | Your PC has no built-in Wi-Fi. DroidCam will connect over **LAN (same network)** via Ethernet ←→ Phone Wi-Fi. |

**Streaming bandwidth check:** 1 Gbps Ethernet is more than enough for 1080p60 streaming (needs ~6-10 Mbps upload).

---

## Audio Devices

| Device | Type | Status |
|--------|------|--------|
| AMD High Definition Audio | GPU audio (HDMI/DP) | OK |
| AMD Streaming Audio Device | GPU audio (for stream capture) | OK |
| High Definition Audio Device | Motherboard onboard audio | OK |
| USB Audio 2.0 | _(likely your headset/mic)_ | OK |
| USB Audio Device | _(likely another USB audio device)_ | OK |

**Notes:** You have 5 audio devices. For streaming, you'll want to identify:
- Which one is your **headset / microphone**
- Set up OBS to capture game audio + mic separately

---

## Peripherals (noted)

| Device | Notes |
|--------|-------|
| Monitor | MSI MAG 255XF — 1920×1080, likely high refresh rate |
| Phone (webcam) | Will use **DroidCam** over Wi-Fi/LAN for facecam |

---

## Summary & Bottleneck Check for Streaming

| Area | Verdict |
|------|---------|
| **CPU** | ✅ Ryzen 7 5700X (8C/16T) — excellent for gaming + streaming |
| **GPU** | ✅ RX 7600 8GB — comfortable for 1080p gaming + streaming. Use AMD AMF encoder in OBS. |
| **RAM** | ✅ 16 GB — adequate for 1080p streaming |
| **Storage** | ⚠️ C: drive critically low (13.0 GB). Move installs to V: drive. Z: has 302.9 GB free. |
| **Network** | ✅ 1 Gbps Ethernet — plenty of headroom |
| **Webcam** | ⏳ DroidCam via Wi-Fi/LAN (phone connects to same network) |
| **Audio** | ✅ Multiple audio devices available — will need OBS routing setup |
