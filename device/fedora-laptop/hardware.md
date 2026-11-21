# Fedora Laptop Hardware

## System

| Property | Value |
|---|---|
| Model | ASUS VivoBook X505ZA |
| OS | Fedora Silverblue 44 |
| CPU / graphics | Ryzen 5 2500U (4C/8T), Radeon Vega 8 |
| Memory | Fedora sees 10 GiB and 8 GiB zram; earlier module inventory says 12 GB. Physical DIMMs remain unverified. |
| System disk | WD Green 480 GB NVMe; Btrfs with OSTree |
| Data disk | Seagate ST1000LM035-1RK172, 1 TB; Btrfs label `data`, mounted at `/var/mnt/data` |
| Network | Intel Wireless-AC 8265; Realtek gigabit Ethernet |
| Firmware | ASUS X505ZA, BIOS X505ZA.313 (2020-02-25) |
| Battery | Dead/0 Wh; laptop normally runs on AC |

## Caveats

- Verify physical memory in firmware or with `sudo dmidecode --type memory` before buying RAM; OS-visible memory is not the installed-DIMM total.
- The dead battery causes unstable battery-state reports. UPower mitigation is deployment-specific on Silverblue; follow [`docs/troubleshooting.md`](docs/troubleshooting.md) after OS changes.
- The data drive’s persistent mount is configured by UUID in `/etc/fstab`. Current capacity and mount state are available through `findmnt /var/mnt/data` and `df -h /var/mnt/data`.
