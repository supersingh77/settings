# PC Hardware Documentation

> Generated: 30 May 2026
> Purpose: Streaming setup baseline

---

## System Overview

| Component | Detail |
|-----------|--------|
| **OS** | Microsoft Windows 11 Pro — Version 23H2 (Build 22631) |
| **Form Factor** | Desktop (Custom build, ASRock B450M-HDV R4.0 motherboard) |

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
| **VRAM** | 4 GB GDDR6 |
| **Driver** | AMD Software: Adrenalin Edition v32.0.31007.5012 (dated 12 May 2026) |
| **Monitor** | MSI MAG 255XF — 1920×1080 |
| **Notes** | RX 7600 supports **AMD AMF** hardware encoding (H.264/H.265) for OBS. 4GB VRAM is tight for 1080p streaming + gaming — consider closing background apps. |

---

## Memory (RAM)

| Property | Value |
|----------|-------|
| **Total** | 16 GB (15.9 GB usable) |
| **Type** | _(not detected — check speed via CPU-Z: 2×8GB?)_ |
| **Notes** | 16 GB is the minimum recommended for streaming. Fine for Assetto Corsa + OBS at 1080p, but closing browser tabs before streaming helps. |

---

## Storage

| Drive | Label | Type | Capacity | Free Space | Notes |
|-------|-------|------|----------|------------|-------|
| **C:** | _(System)_ | SSD (NVMe) — XPG GAMMIX S11 Pro | 126 GB partition | **22.6 GB** | ⚠️ Critically low. Windows + core apps only. |
| **V:** | Vacuum Drive | SSD (NVMe) — XPG GAMMIX S11 Pro | 350 GB | 60 GB | ✅ Good for games & streaming software. Assetto Corsa lives here. |
| **Z:** | Mass Storage | HDD — Seagate ST1000DM010 (1 TB) | 931 GB | 287.9 GB | ✅ Good for recordings, VODs, clips, OBS recording output. |

**SSD Details:**
- XPG GAMMIX S11 Pro — NVMe, 512 GB total (partitioned as C: + V:)
- Seagate ST1000DM010 — SATA HDD, 1 TB
- Both healthy

### ⚠️ Storage Action Needed
- **C: drive is critically low** (22.6 GB free, down from 30.5 GB). Before installing streaming software, you should free up space on C: or move OBS + DroidCam to **V:** drive instead.
- **Z: drive dropped** from 401 GB → 287.9 GB free (≈113 GB used since last check) — check for large recordings/VODs.

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
| **GPU** | ⚠️ RX 7600 4GB is capable but VRAM-limited at higher settings. Use AMD AMF encoder in OBS. |
| **RAM** | ✅ 16 GB — adequate for 1080p streaming |
| **Storage** | ⚠️ C: drive critically low (22.6 GB). Move installs to V: drive. Z: also losing space. |
| **Network** | ✅ 1 Gbps Ethernet — plenty of headroom |
| **Webcam** | ⏳ DroidCam via Wi-Fi/LAN (phone connects to same network) |
| **Audio** | ✅ Multiple audio devices available — will need OBS routing setup |
