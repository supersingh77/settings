---
refs: gpu:AMD Radeon RX 7600
---

# Desktop GPU memory size

> Device: desktop

Windows stores two VRAM sizes on a display adapter's class key: `HardwareInformation.MemorySize`, a 32-bit value, and `HardwareInformation.qwMemorySize`, a 64-bit value. On this machine `MemorySize` reads 4293918720 bytes (about 4.0 GB) while `qwMemorySize` reads 8573157376 bytes (8176 MB, about 7.98 GB). The card is an RX 7600 with 8 GB, so the 32-bit field under-reports and is not usable.

[`hardware.ps1`](../src/facets/windows/hardware.ps1) reads `qwMemorySize` for each adapter and the parser puts it in `a.vramMb` on `gpu:AMD Radeon RX 7600`. A driver that sets only `MemorySize` leaves `vramMb` out of the item, so a missing value is not read as zero VRAM.

