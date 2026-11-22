# PC Hardware Documentation

> Detected hardware is generated from live desktop readings. The sections below cover details the audit does not yet collect.
> S.M.A.R.T. health and the CPU cooler remain unverified by the inventory collector.

## Detected hardware

> Generated from live desktop readings by `update-inventory.ps1`. Run it with `-Apply` to refresh this section.

### OS

```text
| OS | Windows 26H2 build 26300.9457 |
| ⚠ ProductName | reads 'Windows 10 Pro' - stale on ReviOS images; trust DisplayVersion + build |
```

### Firmware / CPU

```text
| Board | ASRock B450M-HDV R4.0 |
| BIOS | American Megatrends Inc. P10.60 04/17/2026 |
| CPU | AMD Ryzen 7 5700X 8-Core Processor @ 3394 MHz |
| Cores / threads | 8C / 16T |
| DIMM | 8192 MB DDR4 | rated 3000 / configured 3000 MT/s | Unknown | F4-3000C15-8GVRB |
| DIMM | 8192 MB DDR4 | rated 3000 / configured 3000 MT/s | Kingston | KF3200C16D4/8GX |
| RAM total | 16 GB |
```

### GPU / monitor

```text
| GPU | AMD Radeon RX 7600 - 32.0.32029.2010 (11-18-2026) |
| VRAM | 7.98 GB (qwMemorySize; the 32-bit MemorySize field under-reports) |
| Monitor INF | oem30.inf |
| Monitor ICM | MSI MAG 255XF.icm |
| Display | @monitor.inf,%nonpnpmonitor.devicedesc%;Generic Non-PnP Monitor |
| Display | @monitor.inf,%pnpmonitor.devicedesc%;Generic PnP Monitor |
| Display | @oem30.inf,%4bc2_dp1%;MSI MAG 255XF |
```

### Display modes

```text
| \\.\DISPLAY1 | 1920x1080 @ 300 Hz, 32 bpp |
| \\.\DISPLAY2 | 1920x1080 @ 60 Hz, 32 bpp |
```

### Problem devices

```text
None.
```

### Volumes

| Drive | Label | Type | Capacity | Free |
|---|---|---|---|---|
| **C:** | _ | Fixed | 126.1 GB | 58.5 GB free |
| **V:** | Vacuum Drive | Fixed | 350.0 GB | 133.0 GB free |
| **Z:** | Mass Storage | Fixed | 931.5 GB | 477.8 GB free |

## Additional notes

- CPU base clock: 3.4 GHz. CPU cooler: needs review.
- RAM modules: Kingston KF3200C16D4/8GX and G.Skill F4-3000C15-8GVRB. Both run at 3000 MT/s; the Kingston module is rated for 3200 MT/s.

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
