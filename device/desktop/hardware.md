# PC Hardware Documentation

> Updated: 23 Oct 2026 — ReviOS 26H2 clean install; specs, drivers and volumes verified live (CIM/WMI + `Get-Volume`).
> Drive letters changed after the rebuild: old **V:** is now **E:**; old **Z:** is now **D:**.

## System Overview

| Component | Detail |
|-----------|--------|
| **OS** | Microsoft Windows 11 Pro 26H2 — build **26300.9457** (ReviOS) |
| **Form Factor** | Desktop — custom build, ASRock B450M-HDV R4.0 |
| **BIOS** | American Megatrends P10.60 (2026-04-17) |

## CPU

| Property | Value |
|----------|-------|
| **Model** | AMD Ryzen 7 5700X |
| **Cores / Threads** | 8 / 16 |
| **Base Clock** | 3.4 GHz (3401 MHz) |
| **L2 / L3** | 4 MB / 32 MB |
| **Cooling** | _needs-review — not detected_ |
| **Notes** | 8C/16T handles gaming + AMF streaming comfortably. |

## GPU & Display

| Property | Value |
|----------|-------|
| **Model** | AMD Radeon RX 7600 |
| **VRAM** | 8 GB GDDR6 |
| **Driver** | Adrenalin **26.10.1** — driver **32.0.32015.7029** (2026-10-18) |
| **Primary monitor** | MSI MAG 255XF — 1920×1080 @ **300 Hz** |
| **Secondary monitor** | BenQ RL2240H — 1920×1080 |
| **Monitor driver** | MSI MAG 255XF INF **1.0.0.0** (WHQL, 2024-07-29) + `MSI MAG 255XF.icm` |
| **Notes** | AMF hardware encoding for OBS. WMI `AdapterRAM` reports ~4 GB due to the 32-bit field; the card is 8 GB. |

## Memory (RAM)

| Property | Value |
|----------|-------|
| **Total** | 16 GB (15.9 GB usable) |
| **Configuration** | 2 × 8 GB DDR4 — Kingston KF3200C16D4/8GX + G.Skill F4-3000C15-8GVRB |
| **Speed** | 3000 MT/s |
| **Notes** | Adequate for 1080p gaming + OBS; close browser tabs before streaming. |

## Storage

| Drive | Label | Type | Capacity | Free | Purpose |
|-------|-------|------|----------|------|---------|
| **C:** | _(System)_ | NVMe — XPG GAMMIX S11 Pro | 126.1 GB | **52.2 GB** | OS + core apps |
| **E:** | Vacuum Drive | NVMe — XPG GAMMIX S11 Pro | 350 GB | 137.6 GB | Games/streaming |
| **D:** | Mass Storage | HDD — Seagate ST1000DM010 | 931.5 GB | 488.4 GB | Recordings/archive |

- C: is no longer space-constrained; 52.2 GB free after the clean install.
- Steam libraries survived on E: (6 game folders) and D: (2 game folders); Steam's config did not, so re-add both on first launch.
- Both disks report Healthy.

## Network

| Adapter | Type | Status | Speed | Driver |
|---------|------|--------|-------|--------|
| Realtek PCIe GbE (RTL8168) | Wired | Up | 1 Gbps | **10.50.511.2021** (2021-05-11) |
| Wi-Fi | — | Not present | — | No built-in Wi-Fi; phone/webcam uses the LAN |

**IP:** 192.168.1.11 / 192.168.1.1

## Audio

| Device | Type | Status |
|--------|------|--------|
| **Realtek ALC897** (onboard) | Motherboard audio | Driver **6.0.9231.1** + Realtek Audio Control; no analog endpoint currently active |
| **Focusrite Scarlett Solo** (4th gen) | USB interface | Driver **4.150.0.432** + Control 2 **1.1210**; working |
| **Razer Barracuda X 2.4** | USB wireless headset | Headphones + mic endpoints working |
| **AMD HDMI Audio** | GPU → monitors | Endpoints for MAG 255XF and BenQ RL2240H |

For streaming, capture game audio from the Focusrite/Razer endpoint and mic separately in OBS. The onboard Realtek jacks are currently unused.

## Peripherals

| Device | Notes |
|--------|-------|
| Monitor (primary) | MSI MAG 255XF — 1080p, 300 Hz |
| Monitor (secondary) | BenQ RL2240H — 1080p, 60 Hz |
| Audio interface | Focusrite Scarlett Solo 4th gen |
| Headset | Razer Barracuda X 2.4 |
| Wheel + pedals | PXN V10 Pro (`VID_36E6&PID_400B`) — PXN SimRacing reads base/pedal/keymap data |
| Shifter | A7 Gear Shift (`VID_11FF&PID_B772`) — separate HID game controller; bind per game |
| Controller | Xbox 360 controller on a third-party wireless receiver (`VID_3537&PID_1093`) |
| Phone (webcam) | DroidCam over LAN — client/plugin not reinstalled |

## Known Quirks

### MPRT locks software brightness

When **MPRT** is enabled in the monitor OSD, the backlight is strobed and the monitor takes over brightness control. DDC/CI tools such as **Twinkle Tray** can no longer change brightness; FreeSync/VRR is usually disabled too.

- Turn **MPRT off** for software brightness control.
- If you want MPRT on, use the monitor's OSD joystick.
- **No DDC/CI toggle:** the MAG 255XF capability string exposes no MPRT VCP code, so Twinkle Tray and generic DDC/CI tools cannot switch it. No documented MSI software control exists for this model.

### Xbox 360 receiver opens Task View

When the controller is **powered off**, its third-party receiver can emit phantom `Win+Tab` / Task View input. It appears as Task View opening when right-clicking the desktop or clicking the taskbar. **Powering the controller on stops it immediately** (verified 2026-10-23).

- Unplug the receiver when not gaming (cleanest), or keep the controller powered on.
- Replace the third-party dongle with a genuine receiver or use a wired controller.

No Windows setting or driver was at fault.
