# PC Hardware Documentation

> Updated: 16 Nov 2026 — volumes, drives and driver versions re-verified live (registry `Enum`/`Class` + `DriveInfo`).
> CPU/RAM/VRAM/refresh/problem-devices re-verified 16 Nov 2026 **without WMI** — via SMBIOS types 4+17, `EnumDisplaySettings`, the driver key's `qwMemorySize`, and `pnputil`.
> Still unverified: **S.M.A.R.T. health** and the **CPU cooler** (both need WMI/admin sensor access). Those two remain from the 23 Oct 2026 pass.
> Drive letters did **not** change in the rebuild: the volumes are still **V:** (games) and **Z:** (archive). There is no `D:` or `E:` on this machine — earlier revisions of these docs claimed otherwise and were wrong.

## System Overview

| Component | Detail |
|-----------|--------|
| **OS** | Microsoft Windows 11 Pro 26H2 — build **26300.9457** (ReviOS) |
| **OS (registry caveat)** | `HKLM\…\CurrentVersion` → **ProductName = "Windows 10 Pro"**, DisplayVersion 26H2, UBR 9457. ReviOS left `ProductName` stale; trust `DisplayVersion` + `CurrentBuild.UBR`, never `ProductName` |
| **Form Factor** | Desktop — custom build, ASRock B450M-HDV R4.0 |
| **BIOS** | American Megatrends P10.60 (2026-04-17) |

## CPU

| Property | Value |
|----------|-------|
| **Model** | AMD Ryzen 7 5700X |
| **Cores / Threads** | 8 / 16 — re-verified 16 Nov 2026 from SMBIOS type 4 |
| **Base Clock** | 3.4 GHz (3401 MHz) |
| **L2 / L3** | 4 MB / 32 MB |
| **Cooling** | _needs-review — not detected_ |
| **Notes** | 8C/16T handles gaming + AMF streaming comfortably. |

## GPU & Display

| Property | Value |
|----------|-------|
| **Model** | AMD Radeon RX 7600 |
| **VRAM** | 8 GB GDDR6 — **7.98 GB** confirmed via `HardwareInformation.qwMemorySize` (8573157376 B) |
| **Driver** | Adrenalin **26.10.1** — driver **32.0.32015.7029** (2026-10-18) |
| **Primary monitor** | MSI MAG 255XF — 1920×1080 @ **300 Hz**, active mode re-verified 16 Nov (`EnumDisplaySettings`) |
| **Secondary monitor** | BenQ RL2240H — 1920×1080 @ 60 Hz (measured 16 Nov) |
| **Monitor driver** | MSI MAG 255XF INF **1.0.0.0** (WHQL, 2024-07-29) + `MSI MAG 255XF.icm` |
| **Notes** | AMF hardware encoding for OBS. WMI `AdapterRAM` reports ~4 GB due to the 32-bit field; the `MemorySize` value in the driver key is also 4 GB for the same reason. The QWORD field is the truthful one. |

## Memory (RAM)

| Property | Value |
|----------|-------|
| **Total** | 16 GB (15.9 GB usable) |
| **Configuration** | 2 × 8 GB DDR4 — Kingston KF3200C16D4/8GX + G.Skill F4-3000C15-8GVRB (both verified from SMBIOS type 17, 16 Nov 2026) |
| **Speed** | **3000 MT/s configured** on both sticks. The Kingston part is rated 3200 but runs 3000 — the pair settles on the slower SPD profile; don't chase "missing" 200 MT/s |
| **Notes** | Adequate for 1080p gaming + OBS; close browser tabs before streaming. |

## Storage

Measured 16 Nov 2026 (`[System.IO.DriveInfo]` + `Get-Volume`-free fallback):

| Drive | Label | Type | Capacity | Free | Purpose |
|-------|-------|------|----------|------|---------|
| **C:** | _(System)_ | NVMe — XPG GAMMIX S11 Pro | 126.1 GB | **66.5 GB** | OS + core apps |
| **V:** | Vacuum Drive | NVMe — XPG GAMMIX S11 Pro | 350.0 GB | 76.4 GB | Games/streaming |
| **Z:** | Mass Storage | HDD — Seagate ST1000DM010 | 931.5 GB | 481.1 GB | Recordings/archive |

- C: is at **66.5 GB free**, not the 98.8 GB quoted on 23 Oct. The 98.8 figure never reconciled against used space (an 11 GB pagefile alone plus the app set put it far lower) — treat this table as the reference.
- Growth is ordinary app install (Chrome/Discord/Python/.NET/obs) plus **1.87 GB of Nov 12–14 recordings sitting in `C:\Users\amar\Videos`**, which breaks the "recordings → Z:" rule.
- Steam: **`V:` is registered** in `libraryfolders.vdf` with 6 apps. **`Z:` is not registered** despite holding Celeste + Hollow Knight — add it in Steam → Settings → Storage.
- "Both disks report Healthy" is from the 23 Oct SMART check; not re-verifiable from an agent session.

## Network

| Adapter | Type | Status | Speed | Driver |
|---------|------|--------|-------|--------|
| Realtek PCIe GbE (RTL8168) | Wired | Up | 1 Gbps | **10.50.511.2021** (2021-05-11) |
| Wi-Fi | — | Not present | — | No built-in Wi-Fi; phone/webcam uses the LAN |
| Bluetooth | USB dongle — TP-Link UB500 (BT 5.3) | Up | — | `USB\VID_2357&PID_0604`. Ran on inbox `bth.inf` 10.0.26100.9444; **16 Nov the TP-Link package was installed**, so `oem36.inf` (Realtek 1.9.1051.3009, 2023-09-11) is now "Best Ranked / Installed" and `bth.inf` is "Outranked". Detects and pairs; **1 paired device** (ZEB-COUNTY). Note the vendor driver is *older* than the inbox stack — roll back by uninstalling the oem36 package in Device Manager if LE audio or discovery misbehaves |

**IP:** 192.168.1.11 / 192.168.1.1

## Audio

| Device | Type | Status |
|--------|------|--------|
| **Realtek ALC897** (onboard) | Motherboard audio | Driver **6.0.9231.1** + Realtek Audio Control; no analog endpoint currently active |
| **Focusrite Scarlett Solo** (4th gen) | USB interface | Driver **4.150.0.432** + Control 2 **1.1210**; working |
| **Razer Barracuda X 2.4** | USB wireless headset | Headphones + mic work while awake (−45 dB mean, −27.7 dB peak), but the mic **auto-mutes/sleeps when idle** (down to −74 dB). Not safe as the default recording mic |
| **Kreo Owl Lite (webcam) mic** | USB (UVC) | Works — −31.8 dB mean / −6.1 dB peak measured. **OBS's pinned `Mic/Aux`**: wired, always on |
| **Digitek USB wireless mic** | USB (`USB\VID_3634&PID_4155`) | **Connected** 16 Nov: Windows endpoint `Microphone (USBAudio1.0)` is active, but **DirectShow cannot see it**, so ffmpeg/`mic-check.ps1` cannot measure it. OBS uses WASAPI and can |
| **Zebronics ZEB-COUNTY** | Bluetooth speaker | Paired 16 Nov. Playback `Headphones (ZEB-COUNTY)` at 44.1 kHz; **mic** `Headset (ZEB-COUNTY Hands-Free)` is an HFP telephony endpoint (8–16 kHz) — present but unsuitable for recording |
| **AMD HDMI Audio** | GPU → monitors | Endpoints for MAG 255XF and BenQ RL2240H. Output only — **no monitor microphone exists** |

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
| Controller | **GameSir** pad on a third-party wireless receiver (`VID_3537&PID_1093`). Enumerates as an Xbox 360 controller through the inbox `xusb22.inf` (XInput) — no vendor driver involved. GameSir Connect 1.17.4 is installed for firmware/remapping. Receiver firmware updated 2026-11-17 |
| Phone (webcam) | Retired — the phone/DroidCam route was replaced by the Kreo Owl Lite |
| Webcam | Kreo Owl Lite (`USB\VID_0C45&PID_6300&MI_00`) — USB Video Class on inbox `usbvideo.inf`, status Started. Video works; its mic is the default voice input |

## Known Quirks

### MPRT locks software brightness

When **MPRT** is enabled in the monitor OSD, the backlight is strobed and the monitor takes over brightness control. DDC/CI tools such as **Twinkle Tray** can no longer change brightness; FreeSync/VRR is usually disabled too.

- Turn **MPRT off** for software brightness control.
- If you want MPRT on, use the monitor's OSD joystick.
- **No DDC/CI toggle:** the MAG 255XF capability string exposes no MPRT VCP code, so Twinkle Tray and generic DDC/CI tools cannot switch it. No documented MSI software control exists for this model.

### Xbox 360 receiver opens Task View — **resolved 2026-11-17**

Historical: with the controller **powered off**, the third-party wireless receiver emitted phantom `Win+Tab` / Task View input, which looked like Task View opening when right-clicking the desktop, the taskbar or an icon. Powering the controller on stopped it immediately (verified 2026-10-23).

**Fixed 17 Nov 2026** by updating the controller/receiver firmware and installing **GameSir Connect 1.17.4**. The dongle is still the same one — this was a firmware defect, not a Windows setting. If the behaviour ever returns, suspect the firmware before the OS:

- Re-check the pad's firmware in GameSir Connect
- Unplug the receiver when not gaming, or keep the controller powered on
