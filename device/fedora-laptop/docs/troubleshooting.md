# Troubleshooting

Quick reference for known issues on Fedora Silverblue 44 (ASUS VivoBook X505ZA).

---

## Contents

1. [Dead Battery Freeze](#1-dead-battery-freeze)
2. [Missing App Icons (Gear Icon)](#2-missing-app-icons-gear-icon)
3. [GNOME Software Update Loop](#3-gnome-software-update-loop)
4. [EOL Flatpak Runtimes](#4-eol-flatpak-runtimes)
5. [Random Power-Off After System Update](#5-random-power-off-after-system-update)
6. [Freeze / Update Follow-up (2026-10-08)](#6-freeze--update-follow-up-2026-10-08)
7. [systemd-remount-fs Failure on Silverblue Composefs Root (2026-10-08)](#7-systemd-remount-fs-failure-on-silverblue-composefs-root-2026-10-08)

---

## 1. Dead Battery Freeze

**Issue**: System freezes caused by dead ASUS battery (BAT0) reporting invalid values to UPower.
**Status**: ⚠️ Mitigated — UPower config applied (see below); the udev rule is **inert** (UPower never reads it — see "Why the udev Rule Doesn't Hide the Battery"). `-nan` errors still fire every 5 seconds (cosmetic; UPower 1.91.3 computes NaN percentage for the dead battery) but no longer cause freezes. See also [Random Power-Off After System Update](#5-random-power-off-after-system-update).

### Root Cause

Dead battery (BAT0, 375 cycles, 0 Wh capacity) reports `0/0` → UPower calculates `-nan`
→ UPower crashes every 5 seconds → GNOME Shell hangs → system freezes.

### Verify Current State

```bash
# Count how many -nan errors have fired today (should be 0 after fix)
journalctl -u upower --since "today" | grep -c "\-nan"

# Check if UPower config fix is applied (must show "true")
grep "NoPollBatteries" /etc/UPower/UPower.conf

# Check if udev rule is installed (must return a file path)
ls /etc/udev/rules.d/99-ignore-dead-battery.rules 2>/dev/null || echo "RULE NOT INSTALLED"
```

### One-Shot Fix (run all at once)

```bash
# 1. Apply UPower config changes
sudo sed -i \
  -e 's/^NoPollBatteries=false/NoPollBatteries=true/' \
  -e 's/^IgnoreLid=false/IgnoreLid=true/' \
  -e 's/^UsePercentageForPolicy=true/UsePercentageForPolicy=false/' \
  /etc/UPower/UPower.conf

# 2. Install the udev rule (inert — UPOWER_IGNORE_DEVICE is not implemented in current UPower; kept as documentation)
sudo cp ~/Desktop/settings/device/fedora-laptop/scripts/99-ignore-dead-battery.rules \
    /etc/udev/rules.d/99-ignore-dead-battery.rules

# 3. Reload udev and restart UPower
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo systemctl restart upower
```

### Verify Fix Applied

```bash
# Watch live UPower logs — -nan lines should stop immediately
journalctl -u upower -f

# Confirm config values
grep -E "NoPollBatteries|UsePercentageForPolicy|IgnoreLid" /etc/UPower/UPower.conf
# Expected output:
#   NoPollBatteries=true
#   IgnoreLid=true
#   UsePercentageForPolicy=false
```

### Why the udev Rule Doesn't Hide the Battery

Neither `ENV{UPOWER_IGNORE}="1"` nor `ENV{UPOWER_IGNORE_DEVICE}="1"` is read by current UPower —
grepping the 1.91.x source shows no such variable anywhere. The rule in `scripts/` is inert:
udev applies it, but UPower never checks it, so BAT0 stays exposed. The freeze mitigation comes
entirely from the config changes (`NoPollBatteries`/`IgnoreLid`/`UsePercentageForPolicy`), not
from the rule. The rule is kept only as documentation of intent.

### Long-Term Options

1. **Physical battery removal** — 100% fix, ideal since system always runs on AC power
2. **Replace battery** (~$30–60) — revert UPower config changes after replacement:

```bash
# After replacing battery, revert:
sudo sed -i \
  -e 's/^NoPollBatteries=true/NoPollBatteries=false/' \
  -e 's/^IgnoreLid=true/IgnoreLid=false/' \
  -e 's/^UsePercentageForPolicy=false/UsePercentageForPolicy=true/' \
  /etc/UPower/UPower.conf
sudo rm /etc/udev/rules.d/99-ignore-dead-battery.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo systemctl restart upower
```

---

## 2. Missing App Icons (Gear Icon)

**Issue**: Some apps show a generic gear icon (⚙️) in GNOME Activities instead of their real icon.

### Why It Happens

GNOME resolves icons through an **icon theme cache** (`icon-theme.cache`). When stale or missing,
GNOME falls back to a gear icon even if the icon file exists on disk.

| Cause | Affected Apps |
|-------|--------------|
| Flatpak system icon cache outdated | Chrome, Celluloid, Mission Center |
| User icon cache stale | OpenWork, UAD-NG, distrobox apps |
| `.desktop` file has bad `Icon=` name | Custom `.desktop` entries |
| App ships SVG-only icon | Chrome, Celluloid (requires librsvg) |

### Fixes

**Rebuild user icon cache** (run after installing any custom-icon app):

```bash
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor/
```

**Rebuild Flatpak system icon cache** (requires sudo):

```bash
sudo gtk-update-icon-cache -f -t /var/lib/flatpak/exports/share/icons/hicolor/
```

**Restart GNOME Shell** to pick up the new cache:
- Wayland (default): log out and back in
- X11: `Alt+F2` → type `r` → Enter

**Check a `.desktop` Icon= entry:**

```bash
grep "^Icon=" ~/.local/share/applications/*.desktop
```

The value must be an absolute path or a name that exists in the active icon theme.

**Force Flatpak icon re-export:**

```bash
flatpak repair --user
```

### Quick Fix (all in one)

```bash
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor/
sudo gtk-update-icon-cache -f -t /var/lib/flatpak/exports/share/icons/hicolor/
update-desktop-database ~/.local/share/applications/
echo "Done — log out and back in to apply."
```

---

## 3. GNOME Software Update Loop

**Issue**: GNOME Software keeps showing the same system update after it was already installed.
**Status**: ✅ Normal behavior — not a bug.

### Why It Happens

`rpm-ostree upgrade` **stages** updates but doesn't apply them until reboot. GNOME Software sees
the staged (unapplied) update and shows it again as pending.

### Fix

```bash
rpm-ostree upgrade --reboot   # stage + reboot in one step
```

### Update Types on Silverblue

| Type | Command | Reboot? |
|------|---------|---------|
| System (rpm-ostree) | `rpm-ostree upgrade` | ✅ Yes |
| Flatpak apps | `flatpak update` | No |
| Toolbox packages | `toolbox run sudo dnf upgrade` | No |
| OpenWork AppImage | `update-openwork` | No |

> **Why does Antigravity update so often?** Google uses continuous deployment — multiple builds
> per day with the same version number. This is normal; update on your own schedule.

---

## 4. EOL Flatpak Runtimes

**Issue**: Some Flatpak apps use end-of-life runtimes (no security updates).
**Status**: Monitoring — waiting for developers to push updates.

### Affected Apps

| App | EOL Runtime | Action |
|-----|------------|--------|
| VLC | KDE Platform 5.15 | Wait for developer update |
| ~~GNOME Photos~~ | ~~GNOME Platform 47~~ | ✅ Removed (using Loupe) |

### Maintenance

```bash
flatpak update -y                          # update all apps
flatpak uninstall --unused -y             # clean unused runtimes
flatpak list --app --columns=name,runtime # check for EOL runtimes
```


> EOL runtimes don't cause crashes — they stop receiving security patches. Apps update their
> runtimes when developers release new versions.

---

## 5. Random Power-Off After System Update

**Issue**: After `rpm-ostree upgrade`, the new deployment boots to the desktop but powers off
cleanly 5–60 seconds later. Booting the previous deployment from the boot menu works fine.
**Status**: ✅ **Fixed** (2026-09-20, verified) — the September deployment's own
`/etc/UPower/UPower.conf` was edited to `CriticalPowerAction=Ignore` +
`AllowRiskyCriticalPowerAction=true`. Rebooted into the September deployment: the "considered
risky" warning appears at upowerd start, `GetCriticalAction` returns `('Ignore',)`, and the
system stays up (previously it powered off within 5–60 s).

### Root Cause

**Each ostree deployment has its own `/etc`** (mounted from the deployment's own `etc/` dir —
`findmnt /etc` shows the source is `<deployment>/etc`). `/etc` is **not** shared across
deployments. When the September deployment was created, its `/etc/UPower/UPower.conf` was
populated by the 3-way merge: the user's earlier edits (`NoPollBatteries=true`, `IgnoreLid=true`,
`UsePercentageForPolicy=false`) were carried over, but the critical-action keys kept the **old
defaults**:

- `CriticalPowerAction=HybridSleep`
- `AllowRiskyCriticalPowerAction=false`

The dead battery (BAT0, 0 Wh) reports 0% capacity, and the EC oscillates charging ↔ discharging
every ~10–20 s. In the September boots:

1. **UPower 1.91.4** computes percentage as `0%` (no `-nan` spam — 1.91.4 handles the missing
   `energy_full` differently than 1.91.3, which logged `-nan` every 5 s).
2. Whenever the battery reads as **discharging**, the warning level reaches **ACTION**
   (`PercentageAction=2%` / `TimeAction=120`).
3. `CriticalPowerAction=HybridSleep` + `AllowRiskyCriticalPowerAction=false` → no "risky" warning
   is logged (only `Suspend`/`Ignore` warn) → `up_backend_get_critical_action()` resolves
   `HybridSleep` → not available (no swap on Silverblue) → falls back to **PowerOff**.
4. **Who shuts down**: upowerd itself — 20 s after the ACTION warning it calls logind
   `PowerOffWithFlags` (`up_backend_take_action`). GNOME's gsd-power only shows the
   "This device is about to shutdown" notification; it never performs the action.

The fallback chain is documented in UPower.conf itself:
`Suspend → HybridSleep → Hibernate → PowerOff → Sleep → Ignore`.

**Why the earlier fix "didn't work"**: `AllowRiskyCriticalPowerAction=true` +
`CriticalPowerAction=Ignore` was applied to `/etc/UPower/UPower.conf` while booted into the
**August** deployment — which only edits the August deployment's `/etc`. The September deployment
kept its own unfixed copy, so its boots still powered off (and showed **zero** risky warnings,
which was the tell: the Sept upowerd was reading a config without `Ignore`). Running both
deployments' upowerd binaries directly confirmed both read `/etc` and log the warning — the
binary was never the problem.

### Fix

Edit the **September deployment's** `/etc/UPower/UPower.conf` (from any boot):

```bash
sudo mount -o remount,rw /sysroot
sudo sed -i 's/^AllowRiskyCriticalPowerAction=false/AllowRiskyCriticalPowerAction=true/' \
  /sysroot/ostree/deploy/fedora/deploy/<SEPT-DEPLOYMENT-ID>/etc/UPower/UPower.conf
sudo sed -i 's/^CriticalPowerAction=HybridSleep/CriticalPowerAction=Ignore/' \
  /sysroot/ostree/deploy/fedora/deploy/<SEPT-DEPLOYMENT-ID>/etc/UPower/UPower.conf
sudo mount -o remount,ro /sysroot
```

(`<SEPT-DEPLOYMENT-ID>` = the deployment dir under `/sysroot/ostree/deploy/fedora/deploy/`
that corresponds to the new version — check with `rpm-ostree status`.)

Safe because the battery is dead and the system always runs on AC. The gsd-power notification may
now read "about to hibernate" instead of "about to shutdown" — cosmetic, notification only.

### Verify

From the **September** deployment (after rebooting into it):

```bash
grep -E "^(AllowRiskyCriticalPowerAction|CriticalPowerAction)" /etc/UPower/UPower.conf
# Expected:
#   AllowRiskyCriticalPowerAction=true
#   CriticalPowerAction=Ignore

journalctl -b | grep -i risky
# Expected: the "considered risky" warning at upowerd start (proves the config is active)

gdbus call --system --dest org.freedesktop.UPower \
  --object-path /org/freedesktop/UPower \
  --method org.freedesktop.UPower.GetCriticalAction
# Expected: ('Ignore',)   ← was ('PowerOff',) before the fix
```

The system should stay up past the first minute (the previous failure window).

### Tradeoff

"Ignore" means that if the laptop ever runs on battery until exhaustion, it powers off abruptly
instead of hibernating (risk of data loss). Acceptable here: the battery is dead (0 Wh) and the
system always runs on AC.

### If the power-off persists after this fix

The kernel (7.1.12 → 7.2.5) is the next suspect. Pin the old kernel:

```bash
rpm-ostree override replace \
  https://kojipkgs.fedoraproject.org/packages/kernel/7.1.12/200.fc44/x86_64/kernel-7.1.12-200.fc44.x86_64.rpm \
  # ... plus kernel-core, kernel-modules, kernel-modules-core, kernel-modules-extra
rpm-ostree upgrade --reboot
```

### Revert (if battery is ever replaced)

```bash
sudo sed -i 's/^AllowRiskyCriticalPowerAction=true/AllowRiskyCriticalPowerAction=false/' /etc/UPower/UPower.conf
sudo sed -i 's/^CriticalPowerAction=Ignore/CriticalPowerAction=HybridSleep/' /etc/UPower/UPower.conf
sudo systemctl restart upower
```

Note: on Silverblue this must be done in **each** deployment's `/etc` (per-deployment), or
re-applied after the next `rpm-ostree upgrade` creates a new deployment.

---

## 6. Freeze / Update Follow-up (2026-10-08)

**Observation**: At the 2026-10-08 pre-update check, the booted deployment was Fedora `44.20261006.0`, kernel `7.2.8-200.fc44`, and UPower `1.91.4`. Fedora `44.20261008.0` was pending/cached and included kernel `7.2.9-200.fc44` and UPower `1.91.5`. The update transaction logged by GNOME Software began around 09:56 IST; the preceding boot's journal ended around 10:02 IST without a normal shutdown sequence. An earlier boot that morning also ended abruptly before that transaction.

**Interpretation**: An abrupt journal ending is consistent with a hard freeze followed by a forced power-off, but does not identify its cause. The later incident overlapped an update transaction, which is relevant timing but not proof the update caused the hang. No clear OOM kill, storage I/O/Btrfs error, or GPU-reset marker was found in the retained logs. A complete unresponsive freeze may prevent the final diagnostic message from being written.

**What to check after the user's `update` script and reboot**:

```bash
rpm-ostree status
uname -r
rpm -q upower
journalctl --list-boots
```

Record the booted deployment, kernel, and UPower version rather than assuming an ordinary restart applied a staged deployment. See [Lessons §7](lessons.md#7-silverblue-updates-are-staged-an-ordinary-restart-may-not-apply-them) for the update/reboot distinction and log commands.

No system or filesystem repair was performed as part of this check. A sudo password was unavailable, so privileged Btrfs scrub/device-stat checks were not run. Preserve incident journals before running journal vacuum or cleanup. See [Lessons §8](lessons.md#8-abrupt-freezerestart-a-missing-shutdown-message-does-not-diagnose-the-cause).

---

## 7. systemd-remount-fs Failure on Silverblue Composefs Root (2026-10-08)

**Symptom**: Every retained boot on 2026-10-08, including boots of Fedora `44.20261006.0` and `44.20261008.0`, logs:

```text
systemd-remount-fs.service: Failed with result 'exit-code'
mount: /: fsconfig() failed: overlay: No changes allowed in reconfigure.
```

The host `/etc/fstab` defines `/` as the physical Btrfs `subvol=root` with `compress=zstd:1,ro`. Fedora Silverblue uses OSTree's `ostree-prepare-root` during early boot to make the actual running `/` a **composefs overlay**. After switch-root, `systemd-remount-fs` reads `/etc/fstab` and attempts to apply the physical Btrfs root entry to `/`, now an overlay. The kernel rejects changing that overlay's mount configuration, so this early-boot unit fails on `/`.

**Evidence checked**:

- The error is the same before and after the Fedora 44.20261008 update; it is not new in kernel 7.2.9.
- The active root is `overlay`/`composefs`, read-only; `/etc` and `/sysroot` are the deployment's Btrfs-backed mounts. `ostree-prepare-root` reports `composefs: mounted successfully`.
- `/etc/fstab` and the booted deployment's `/etc/fstab` both contain the same root Btrfs entry. `systemd-fstab-generator` generates `-.mount` from it, while OSTree has already made `/` an overlay.
- OSTree's later `ostree-remount.service` succeeds; the system continues booting and the generated root mount unit reports the already-active composefs mount as mounted.
- `systemd-remount-fs` is the sole failed unit currently reported by `systemctl --failed`; no Btrfs corruption or device I/O error was observed in the reviewed boot logs.

**Assessment**: This is an early-boot mismatch between generic `/etc/fstab` remount handling and Silverblue/OSTree's composefs root, and is present across deployments. The message alone does **not** show damage to Btrfs, an incorrectly writable Silverblue root, or the cause of the laptop freezes. The deployed root is still read-only as designed, and OSTree finishes boot setup. Do not change the root fstab options, run a remount on `/`, mask `systemd-remount-fs.service`, or alter OSTree/bootc units as a speculative fix.

**Next step if seeking to eliminate the warning**: Confirm the expected Silverblue/bootc behavior for Fedora 44's bootc-generated fstab and composefs with the Fedora Silverblue/bootc maintainers. The `Updated by bootc-fstab-edit.service` comment in this fstab also warrants checking which installed component added that metadata. Make any corrective configuration only against Fedora's supported Silverblue/bootc guidance; preserve the working boot and rollback deployment meanwhile.
