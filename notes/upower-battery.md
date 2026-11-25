---
refs: battery:BAT0, conf:/etc/UPower/UPower.conf#CriticalPowerAction, conf:/etc/UPower/UPower.conf#AllowRiskyCriticalPowerAction, data/devices/fedora-laptop/state/config-file.jsonl
---

# UPower and the dead battery

`CriticalPowerAction` resolves through a fallback chain: Suspend, HybridSleep, Hibernate, PowerOff, Sleep, Ignore. `Ignore` and `Suspend` are risky; without `AllowRiskyCriticalPowerAction=true` UPower silently substitutes the next available action, which on a no-swap Silverblue install ends at PowerOff.

The "risky action" warning at startup is emitted only for Suspend or Ignore. Its absence when expected means the config being read is not the one you think, usually because deployments have separate `/etc` trees.

## Dead battery symptoms

The EC oscillates BAT0 between charging and discharging every 10 to 20 seconds. When the state reads discharging at 0%, UPower reaches its ACTION level and the machine powers off cleanly about 20 seconds later (GNOME only notifies; upowerd acts). upowerd actions show as `logind: The system will power off now!`.

UPower 1.91.3 reports percentage as `-nan` because `energy_full` is missing and logs GLib errors every few seconds. UPower 1.91.4 reports 0% instead, so the ACTION warning now fires on the discharge flips. Check the upower version before comparing behaviour across deployments. The `UPOWER_IGNORE_DEVICE` udev rule is inert; do not rely on it.

## Journal forensics

Before cleanup or vacuum, capture the previous boot:

```sh
journalctl --list-boots
journalctl -b -1 -k --no-pager
journalctl -b -1 -p warning..alert --no-pager
journalctl -b -u upower --no-pager
```

Early-boot journal entries can be stamped with RTC time (roughly 5.5 hours ahead here) until NTP sync; analyse with post-sync timestamps. The upower history under `/var/lib/upower/` correlates the last discharging entry with the poweroff. An abruptly ending journal is consistent with a forced power-off or crash, not proof of the cause.
