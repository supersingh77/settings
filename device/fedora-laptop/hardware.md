# ASUS VivoBook X505ZA Hardware Profile

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
- **Live OS-visible memory (2026-10-08)**: about 10GiB; `free -h` reported 10GiB total, about 8.0GiB available, and an 8GiB zram swap device. `dmidecode` could not be checked because this review did not enter a sudo password.
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
- **Quirk**: EC oscillates charging ↔ discharging every ~10–20 s; with the wrong UPower
  config this triggered a clean power-off after boot (see
  [Troubleshooting §5](docs/troubleshooting.md#5-random-power-off-after-system-update))

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
- Dead battery (BAT0, 0 Wh) — UPower `-nan` errors every 5 seconds in the Aug deployment
  (UPower 1.91.3); mitigated via UPower config, **applied in both deployments** (see
  [Troubleshooting §1](docs/troubleshooting.md#1-dead-battery-freeze))

### 🔧 Current Optimizations
- Btrfs filesystem with SSD optimizations (`discard=async`, `space_cache=v2`) ✅
- AMDGPU open-source driver for graphics ✅
- `fstrim.timer` enabled — weekly SSD TRIM runs automatically ✅
- OSTree immutable base system for reliability ✅
- UPower dead-battery fix: ✅ **applied (both deployments)** — `CriticalPowerAction=Ignore` +
  `AllowRiskyCriticalPowerAction=true` (see [Troubleshooting §1](docs/troubleshooting.md#1-dead-battery-freeze))
- TLP power management: ❌ **not installed** — see [Power Optimization](#power-optimization-tlp) below

## Upgrade Recommendations
### High Priority
1. **Memory**: Consider upgrading to 2x8GB matching modules for dual-channel optimization
2. **SSD Upgrade**: Replace 1TB HDD with 2TB NVMe SSD for significant performance boost

### Medium Priority
1. **Thermal Paste**: CPU repaste for better thermal management
2. **BIOS Update**: Check for newer BIOS versions if available
3. **TLP**: Install for CPU frequency management, WiFi power saving, and 1TB HDD spin-down — see [Power Optimization](#power-optimization-tlp) below
4. **Journal size cap**: Add `SystemMaxUse=64M` to `/etc/systemd/journald.conf` — the
   dead-battery UPower `-nan` spam (UPower 1.91.3, Aug deployment) inflates logs fast

---

## Power Optimization (TLP)

TLP provides fine-grained Linux power management beyond what GNOME's default settings offer.
On this hardware it helps with: CPU frequency idle tuning, Intel WiFi power saving, and spinning
down the secondary 1TB HDD when idle.

> **Note**: Fedora Silverblue does not ship `power-profiles-daemon` by default in this
> configuration. Verify before installing TLP:
> ```bash
> rpm -q power-profiles-daemon && systemctl is-enabled power-profiles-daemon
> ```
> If `power-profiles-daemon` **is** installed and enabled, you must disable it before enabling TLP
> (they conflict). If it's not installed (as is currently the case here), proceed directly.

### Install TLP (rpm-ostree layer)

```bash
# Stage TLP and the rfkill/radio device companion
rpm-ostree install tlp tlp-rdw

# Reboot to activate the layered packages
sudo systemctl reboot
```

After reboot:

```bash
# TLP starts automatically on boot — confirm it's active
sudo tlp-stat -s

# Check battery (will show "dead/not found" for BAT0 — that's expected)
sudo tlp-stat -b
```

### Key TLP Benefits for This Hardware

| Feature | Effect |
|---------|--------|
| `CPU_SCALING_GOVERNOR_ON_AC=schedutil` | AMD Ryzen stays responsive on AC |
| `WIFI_PWR_ON_AC=off` | Disables WiFi power saving on AC (better latency) |
| `WIFI_PWR_ON_BAT=on` | Saves power when on battery (less relevant with dead battery) |
| `DISK_APM_LEVEL_ON_AC="254 254"` | Keeps 1TB HDD always spinning when on AC |
| `DISK_APM_LEVEL_ON_BAT="128 128"` | Allows HDD spin-down on battery |

### Optional: Custom TLP Config

```bash
# TLP config lives at (create if missing):
sudo nano /etc/tlp.conf

# Minimal recommended additions for this laptop:
# CPU_SCALING_GOVERNOR_ON_AC=schedutil
# CPU_SCALING_GOVERNOR_ON_BAT=powersave
# WIFI_PWR_ON_AC=off
# DISK_APM_LEVEL_ON_AC="254 254"
# NMI_WATCHDOG=0
```

### Journal Size Cap (Prevent UPower Log Bloat)

The dead-battery `-nan` spam can inflate `/var/log/journal` quickly. Cap it:

```bash
# Add to /etc/systemd/journald.conf under [Journal]:
sudo tee -a /etc/systemd/journald.conf > /dev/null << 'EOF'

# Cap journal size — prevents UPower -nan spam from inflating logs
[Journal]
SystemMaxUse=64M
MaxRetentionSec=2week
EOF

# Apply immediately (no reboot needed):
sudo systemctl restart systemd-journald

# Verify:
journalctl --disk-usage
```

> **Note**: Fix the UPower dead-battery issue ([Troubleshooting §1](docs/troubleshooting.md#1-dead-battery-freeze))
> first — that eliminates the root cause. The journal cap is a safety net.

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
