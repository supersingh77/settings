# Fedora Laptop Hardware

## Detected system

| Property | Value |
|---|---|
| Model | ASUSTeK COMPUTER INC. VivoBook_ASUS Laptop X505ZA_X505ZA |
| OS | Fedora Linux 44.20261119.1 (Silverblue) 44.20261119.1 |
| CPU | AMD Ryzen 5 2500U with Radeon Vega Mobile Gfx (4 cores / 8 threads) |
| Memory | 10.6 GiB visible to Linux; 8.0 GiB swap |
| Storage devices | ST1000LM035-1RK172 (1000 GB); WD Green M.2 2280 480GB (480 GB) |
| Graphics | Advanced Micro Devices, Inc. [AMD/ATI] Raven Ridge [Radeon Vega Series / Radeon Vega Mobile Series] [1002:15dd] (rev c4) |
| Network | Intel Corporation Wireless 8265 / 8275 [8086:24fd] (rev 78); Realtek Semiconductor Co., Ltd. RTL8111/8168/8211/8411 PCI Express Gigabit Ethernet Controller [10ec:8168] (rev 15) |
| Firmware | X505ZA.313 02/25/2020 |

## Caveats

- The firmware reports installed memory separately from memory usable by Linux. Review live `MemTotal` and zram values with installed DIMM details before purchasing memory.
- Battery capacity is read from the kernel power-supply interface. This does not establish that the battery can safely sustain the laptop; consult [`docs/troubleshooting.md`](docs/troubleshooting.md) for the known power behavior.
- The data drive’s persistent mount is configured by UUID in `/etc/fstab`. Capacity and mount state change over time and are intentionally not included in this stable hardware inventory.
