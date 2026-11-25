---
refs: gpu:AMD Radeon RX 7600, os:windows, data/devices/desktop/state/hardware.jsonl
---

# Desktop hardware notes

> Device: desktop

## GPU memory size

Windows stores two VRAM sizes on a display adapter's class key: `HardwareInformation.MemorySize`, a 32-bit value, and `HardwareInformation.qwMemorySize`, a 64-bit value. On this machine `MemorySize` reads 4293918720 bytes (about 4.0 GB) while `qwMemorySize` reads 8573157376 bytes (8176 MB, about 7.98 GB). The card is an RX 7600 with 8 GB, so the 32-bit field under-reports and is not usable.

[`hardware.ps1`](../src/facets/windows/hardware.ps1) reads `qwMemorySize` for each adapter and the parser puts it in `a.vramMb` on `gpu:AMD Radeon RX 7600`. A driver that sets only `MemorySize` leaves `vramMb` out of the item, so a missing value is not read as zero VRAM.

## Stale OS product name

`os:windows` still reports `ProductName = "Windows 10 Pro"` on this ReviOS image. The build and DisplayVersion are the real version, so read the product name as cosmetic and do not "fix" it.

## What no probe captures

- S.M.A.R.T. health and the CPU cooler are not collected anywhere; check them by hand when diagnosing stability or heat.
- There is no network or audio probe. The desktop is wired and has no built-in Wi-Fi. Bluetooth is a TP-Link UB500 USB dongle whose vendor driver is older than the Windows inbox stack; if LE audio or device discovery misbehaves, roll back to the inbox driver.
- Microphone and desktop-audio choices, and the reasons for them, are in [`obs-recording-setup.md`](obs-recording-setup.md).
