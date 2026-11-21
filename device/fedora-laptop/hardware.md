# ASUS VivoBook X505ZA Hardware Profile

## Quick Profile

| Field | Verified detail |
|---|---|
| Model | ASUS VivoBook X505ZA |
| OS | Fedora Silverblue 44 |
| CPU / graphics | Ryzen 5 2500U (4C/8T), Radeon Vega 8 integrated graphics |
| Memory | 10 GiB visible to Linux; 8 GiB zram. Physical module inventory is listed below with an explicit verification caveat. |
| Storage | WD Green 480 GB NVMe for Silverblue; internal Seagate 1 TB HDD currently unmounted |
| Power | Battery reports dead/0 Wh; the laptop is used on AC and has documented UPower mitigations |

## System Overview
- **Model**: ASUS VivoBook X505ZA
- **Manufacturer**: ASUSTeK COMPUTER INC.
- **System Type**: x64-based PC
- **Form Factor**: Laptop

## Processor (CPU)
- **Model**: AMD Ryzen 5 2500U with Radeon Vega Mobile Gfx
- **Architecture**: x64
- **Cores**: 4 physical cores
- **Threads**: 8 logical processors
- **Base Clock**: ~2.0 GHz
- **Boost Clock**: ~3.6 GHz
- **TDP**: 15W (mobile processor)

## Graphics (GPU)
- **Integrated**: AMD Radeon Vega 8 Mobile Graphics
- **VRAM**: 1GB (shared system memory)
- **Driver**: AMDGPU (open-source, kernel-integrated)
- **DirectX Support**: DirectX 12
- **Current Resolution**: 1920 x 1080 (FHD)
- **Color Depth**: 32-bit (4294967296 colors)

## Memory (RAM)
**Configuration**: Dual-channel mixed configuration
- **Slot 1 (ChannelA-DIMM0)**: 4GB Samsung DDR4
  - Model: M471A5143EB1-CRC
  - Speed: 2400 MHz
- **Slot 2 (ChannelB-DIMM0)**: 8GB Samsung DDR4
  - Model: M471A1K43BB1-CRC
  - Speed: 2400 MHz
- **Documented module total**: 12GB RAM (4GB + 8GB modules; original inventory)
- **Live OS-visible memory (2026-11-21)**: 10GiB total, 6.4GiB available at check time, and an 8GiB zram swap device. Physical module sizes were not re-verified during this check.
- **Needs verification**: the live OS-visible total is lower than the documented 12GB physical-module total. This is a discrepancy, not proof the RAM changed; verify module sizes in firmware or by running `sudo dmidecode --type memory` locally.

## Storage Configuration
### Primary (System Drive)
- **Model**: WD Green M.2 2280 480GB
- **Interface**: NVMe M.2
- **Capacity**: 480GB
- **Filesystem**: Btrfs (with OSTree subvolumes)
- **Type**: SSD
- **Mount**: `/` (root), `/home`, `/var` as Btrfs subvolumes
- **Features**: SSD optimized (discard=async, space_cache=v2)

### Secondary (Data Drive)
- **Model**: ST1000LM035-1RK172
- **Capacity**: 1TB (1000GB)
- **Interface**: SATA 2.5"
- **Type**: HDD (5400 RPM typical)
- **Status**: Available for data storage (not currently mounted)

## Network
### Wireless
- **Model**: Intel Dual Band Wireless-AC 8265
- **Standards**: 802.11ac (Wi-Fi 5)
- **Maximum Speed**: 867 Mbps
- **Bands**: 2.4 GHz + 5 GHz
- **MAC Address**: D0:AB:D5:A5:09:88
- **Bluetooth**: Bluetooth 4.2 (typically with this chipset)

### Ethernet
- **Integrated**: Realtek RTL8111/8168/8411 (typical for ASUS laptops)
- **Speed**: Gigabit (1000 Mbps)

## Audio
- **Primary**: AMD High Definition Audio Device
- **Secondary**: AMD Streaming Audio Device
- **Tertiary**: Synaptics SmartAudio HD
- **Configuration**: Stereo speakers with headphone/microphone combo jack

## Motherboard
- **Model**: X505ZA
- **Manufacturer**: ASUSTeK COMPUTER INC.
- **Version**: 1.0
- **Serial Number**: QCCXKE2QE92600047
- **Chipset**: AMD A320

## BIOS/UEFI
- **Version**: X505ZA.313
- **Manufacturer**: American Megatrends Inc.
- **Release Date**: February 25, 2020
- **Type**: UEFI with Secure Boot support

## Input Devices
### Pointing
- **Type**: HID-compliant mouse (touchpad with gesture support)
- **Manufacturer**: Microsoft (driver)

### Keyboard
- **Type**: Standard laptop keyboard
- **Layout**: Enhanced (101/102-key)

## USB Controllers
- **Controller**: AMD USB 3.10 eXtensible Host Controller - 1.10
- **Ports**: Typically 1x USB 3.0 Type-C, 1x USB 3.0 Type-A, 1x USB 2.0 Type-A
- **Power Delivery**: USB-C with charging capability

## Power Management
- **Battery**: ASUS Battery (BAT0)
- **Status**: Dead — 0 Wh capacity (~375 cycles); system runs on AC only
- **Chemistry**: Li-ion (typical)
- **Management**: AMD PowerNow!
- **Quirk**: EC oscillates charging ↔ discharging; UPower settings were adjusted to avoid
  critical battery actions. Verify those settings on each booted deployment.

## Additional Features
- **Card Reader**: SD card reader (typical for VivoBook series)
- **Webcam**: Integrated webcam
- **Fingerprint Reader**: Not present (based on model)
- **Thunderbolt**: Not available on this model

## Fedora Silverblue Compatibility
### ✅ Excellent Compatibility
- AMD Ryzen 5 2500U: Full support with AMD pstate driver
- Radeon Vega 8: Excellent open-source AMDGPU driver (kernel-integrated)
- Intel Wireless-AC 8265: Full support with iwlwifi driver
- Audio: Full support with PipeWire

### ⚠️ Considerations
- Mixed RAM configuration (4GB + 8GB) — works but could be improved with matched pairs
- HDD performance slower than SSD for secondary storage
- Dead battery (BAT0, 0 Wh) — UPower configuration was adjusted to prevent battery events
  from triggering power actions; re-check the active deployment after an OS upgrade (see
  [recovery notes](docs/troubleshooting.md))

### 🔧 Current Optimizations
- Btrfs filesystem with SSD optimizations (`discard=async`, `space_cache=v2`) ✅
- AMDGPU open-source driver for graphics ✅
- `fstrim.timer` enabled — weekly SSD TRIM runs automatically ✅
- OSTree immutable base system for reliability ✅
- UPower dead-battery mitigation: configured; verify per active deployment (see
  [recovery notes](docs/troubleshooting.md))

## Follow-up

The only unresolved hardware inventory item is physical RAM capacity: verify DIMM sizes in firmware
or with `sudo dmidecode --type memory` before buying replacement memory. The internal 1 TB HDD is
present but unmounted; decide whether to mount it for a specific use before changing storage setup.

Keep Fedora's default power-management stack unless there is a measured issue. After an OS update,
confirm the active deployment and UPower settings using [`docs/troubleshooting.md`](docs/troubleshooting.md).

---

## Filesystem

### Storage Layout

```
/dev/sdb (480GB NVMe — WD Green M.2)
├─ /dev/sdb1  599MB   vfat   EFI Boot Partition
├─ /dev/sdb2    2GB   ext4   /boot (kernel storage)
└─ /dev/sdb3  445GB   btrfs  Main filesystem (root, home, var)

/dev/sda (1TB HDD — ST1000LM035)
└─ Not currently mounted — available for data/backups
```

**Btrfs subvolumes**: `/root` (read-only via OSTree), `/var`, `/home`

### Active Btrfs Features

- **SSD optimizations**: `ssd,discard=async,space_cache=v2`
- **Copy-on-write**: Safer writes, instant snapshots
- **Checksums**: Data integrity verification on every read
- **OSTree integration**: Each deployment is a Btrfs snapshot — instant rollback with `rpm-ostree rollback`

### Maintenance Commands

```bash
# Filesystem info
sudo btrfs filesystem show /
sudo btrfs filesystem usage /var

# Check for errors
sudo btrfs device stats /var

# Monthly scrub (detects silent data corruption)
# NOTE: now automated — `cleanup` runs `sudo btrfs scrub start -B /var`.
sudo btrfs scrub start -B /var

# Light rebalance (reclaim unallocated space)
sudo btrfs balance start -dusage=20 /var

# Remove stale rpm-ostree deployments (frees Btrfs snapshot space)
rpm-ostree cleanup -m       # remove pending/rollback deployments
rpm-ostree cleanup -b       # remove base-package cache

# Remove unused Flatpak runtimes
flatpak uninstall --unused -y

# Vacuum journal logs (safe, no third-party cleaner needed)
journalctl --vacuum-time=2weeks --vacuum-size=64M
```

### Optional: Enable Compression

```bash
# Enable zstd compression (10–30% space savings, negligible performance cost)
sudo btrfs property set /var compression zstd
sudo btrfs property set /var/home compression zstd

# Compress existing files
sudo btrfs filesystem defragment -r -v -czstd /var
```
