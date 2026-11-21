# Lessons Learned — Fedora Silverblue

Hard-won knowledge from real incidents on this machine. Read this before debugging
anything config- or power-related on Silverblue.

---

## 1. Each ostree deployment has its own `/etc`

**The big one.** On Silverblue, `/etc` is **not** shared across deployments. Every
deployment has its own `etc/` directory, and when you boot a deployment, its `/etc` is
mounted over the root. A config change made while booted into deployment A only affects
deployment A — deployments B and the next `rpm-ostree upgrade` keep their own copies.

```bash
# Which deployment's /etc am I actually editing right now?
findmnt /etc
#   /etc  /dev/sdb3[/root/ostree/deploy/fedora/deploy/<ID>/etc]  btrfs ...
```

**Consequences:**
- A fix "applied and verified" in one boot may do nothing in another deployment.
- After every `rpm-ostree upgrade`, re-check critical configs in the new deployment
  (3-way merge carries over *modified* files, but keys you never touched keep the
  **old defaults** — which may be dangerous, e.g. `CriticalPowerAction`).
- To edit another deployment's `/etc` from the current boot:

  ```bash
  sudo mount -o remount,rw /sysroot
  sudo sed -i 's/^Key=Old/Key=New/' \
    /sysroot/ostree/deploy/fedora/deploy/<DEPLOYMENT-ID>/etc/<path>
  sudo mount -o remount,ro /sysroot
  ```

  (`rpm-ostree status` shows which deployment ID is which.)

---

## 2. UPower critical-action fallback chain

UPower resolves `CriticalPowerAction` through a fallback chain documented in
`UPower.conf`:

```
Suspend → HybridSleep → Hibernate → PowerOff → Sleep → Ignore
```

- `Ignore` and `Suspend` are treated as **"risky"** actions. Without
  `AllowRiskyCriticalPowerAction=true`, UPower **silently substitutes** the next
  available action instead — on a machine with no swap (typical Silverblue), that
  ends at **PowerOff**.
- The "considered risky" `g_warning` at upowerd start **only fires for `Suspend` or
  `Ignore`**. Its **absence** when you expect it is a diagnostic tell: the config
  being read is not the one you think (see lesson 1).
- upowerd's action signature: ~20 s between the ACTION warning and the logind
  `PowerOff` call (`up_backend_take_action`). GNOME's gsd-power only shows a
  notification — it never performs the action.

---

## 3. Dead battery quirks (BAT0, 0 Wh)

- The EC oscillates the battery state **charging ↔ discharging every ~10–20 s**
  (visible in `/var/lib/upower/history-rate-ASUS_Battery.dat`).
- When the state reads as *discharging* at 0%, UPower's warning level reaches
  **ACTION** — and with a PowerOff-resolving critical action, the system powers off
  cleanly ~20 s later ("The system will power off now!" in the journal).
- **UPower 1.91.3** computes percentage as `-nan` (missing `energy_full`) → logs
  `-nan` GLib errors every 5 s (cosmetic spam, no crash).
- **UPower 1.91.4** computes percentage as `0%` → no `-nan` spam, but the ACTION
  warning now fires on the discharging flips. Same battery, different behavior —
  always check the upower version when behavior changes between deployments.
- The udev rule `ENV{UPOWER_IGNORE_DEVICE}="1"` is **inert** — current UPower never
  reads it. Don't rely on it to hide the battery.

---

## 4. Journal forensics

- **RTC offset**: early boot entries are stamped with RTC time (~5.5 h ahead of IST
  here) until NTP sync. `journalctl --list-boots` shows first/last entries that can
  look time-traveling. Use the **post-sync (real-time)** timestamps for analysis.
- `logind: The system will power off now!` = a **clean, initiated** shutdown — someone
  (upowerd, a button, a command) asked for it. Not a crash, not a thermal event.
- **Absence of expected log lines is evidence.** Zero "risky" warnings across many
  boots told us the Sept deployment's upowerd was reading a different config than the
  Aug deployment's — that single observation cracked the case.
- Correlate the upower history file timestamps with journal poweroff times: the
  poweroff follows the last *discharging* entry by seconds.

---

## 5. Test deployment binaries directly

You can run another deployment's binary from the current boot to see what it would do:

```bash
timeout 4 /sysroot/ostree/deploy/fedora/deploy/<ID>/usr/libexec/upowerd 2>&1 | head
```

Config loading happens before D-Bus name acquisition, so the "risky" warning (or its
absence) prints immediately — a fast way to prove which config a binary reads, without
booting that deployment. (It will fail on the D-Bus name conflict afterwards; that's
fine.)

---

## 6. Debugging checklist for "it worked before the update"

1. `rpm-ostree status` — which deployment is booted, which is pending.
2. `findmnt /etc` — whose `/etc` is live.
3. Diff the deployment's `/etc/<config>` vs `/usr/etc/<config>` (package default) and
   vs the other deployment's copy.
4. Check the journal for expected startup warnings — absence is a clue.
5. Run the deployment's binary directly (lesson 5) to test config reading.
6. Only then suspect the kernel/package diff.

---

## 7. Silverblue updates are staged; an ordinary restart may not apply them

The `update` alias runs `scripts/update-system.sh`. Its `rpm-ostree upgrade` step stages a new immutable deployment; the script then tells you to reboot. Staging is **not** the same as booting the new deployment. GNOME's ordinary **Restart** restarts the selected/booted deployment; the update takes effect only after booting the staged deployment (for example, choosing **Restart & Update** when Software offers it, or restarting after checking `rpm-ostree status`).

Use `rpm-ostree status` after running `update` and again after reboot:

```bash
rpm-ostree status
uname -r
```

Confirm that the desired new version is the booted deployment (`●`) and check that `uname -r` matches its kernel. A pending or cached update by itself does not mean it has been applied, and an ordinary desktop restart is not evidence that an update transaction failed.

On 2026-10-08, before the user's current `update` run, the booted deployment was `44.20261006.0` with kernel `7.2.8-200.fc44`. A system update to `44.20261008.0` was cached/pending, including kernel `7.2.9-200.fc44` and UPower `1.91.5`; it was not yet booted. Treat these as a dated observation, not the current state after that update run.

The update script also updates Flatpaks, OpenWork, UAD-NG, Antigravity, and toolbox packages before `rpm-ostree upgrade`. Those user-app/container changes can take effect immediately; host base-system changes require booting the new deployment. See `scripts/update-system.sh` and `apps.md`.

---

## 8. Abrupt freeze/restart: a missing shutdown message does not diagnose the cause

A hard power-button shutdown can stop the journal without a clean poweroff sequence. Treat a previous boot's abruptly ending logs as consistent with forced power-off or a crash, **not** proof of which process, update, device, or component caused it. Preserve the preceding boot's journal until investigation is complete; avoid journal vacuum/cleanup before collecting it.

For a recent incident, identify the boot and review its kernel and system logs:

```bash
journalctl --list-boots
journalctl -b -1 -k --no-pager
journalctl -b -1 -p warning..alert --no-pager
```

Replace `-1` with the matching boot index if necessary. If the machine becomes completely unresponsive, a forced shutdown may be the only practical recovery; no command can retrieve unsaved logs after power is lost. If only the graphical session is stuck and the keyboard still responds, `Ctrl+Alt+F3` may switch to a text console; if that works, log in and run `sudo systemctl reboot`. This is an optional attempt, not a requirement to wait indefinitely. Keep regular backups of important files.

---

## 9. Inventory RAM using the live OS and firmware; do not equate it to installed modules

On 2026-10-08, the documentation listed 12GB of physical memory modules, but Fedora reported 10GiB usable and an 8GiB zram swap device. Usable memory, memory reserved by firmware/hardware, installed DIMM capacity, and zram swap are different measures. This discrepancy alone does not establish a changed or failing module. Check firmware setup or run `sudo dmidecode --type memory`, and update the inventory only after verifying physical modules.

---

## 10. Silverblue composefs root is not the Btrfs root in `/etc/fstab`

On this Fedora Silverblue 44 host, `/etc/fstab` contains a Btrfs root entry, but OSTree's early-boot `ostree-prepare-root` mounts the active system root as a read-only composefs **overlay**. The subsequent `systemd-remount-fs.service` tries to apply the fstab root settings to `/` and the kernel rejects reconfiguring the overlay (`overlay: No changes allowed in reconfigure`). This recurs on multiple deployments and is not the same as a Btrfs filesystem failure. OSTree's later `ostree-remount.service` succeeds, and the machine reaches the normal desktop.

Confirm the actual mount types before drawing conclusions:

```bash
findmnt --mountpoint / --output TARGET,SOURCE,FSTYPE,OPTIONS
findmnt --mountpoint /etc --output TARGET,SOURCE,FSTYPE,OPTIONS
systemctl --failed --no-pager
journalctl -b -u systemd-remount-fs.service --no-pager
```

Do not try to repair this by changing `/` mount flags, remounting the immutable root, or masking core remount/OSTree units. Check Fedora's supported Silverblue/bootc guidance first; this warning does not explain the unrelated freeze without additional evidence.
