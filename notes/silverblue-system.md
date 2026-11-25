---
refs: os:fedora, kernel:7.3.4-200.fc44.x86_64, data/devices/fedora-laptop/state/hardware.jsonl, data/devices/fedora-laptop/state/rpm-ostree.jsonl
---

# Silverblue system behaviour

## Each deployment has its own /etc

`/etc` is not shared across OSTree deployments. A change made in one deployment only affects that deployment, and a fix verified in one boot can do nothing after switching. After an upgrade, re-check critical files: a 3-way merge carries modified files, but untouched keys keep the previous defaults. Which live `/etc` you are editing:

```sh
findmnt /etc
```

To edit another deployment's copy, remount `/sysroot` read-write, edit under `/sysroot/ostree/deploy/<deploy>/deploy/<id>/etc/`, then remount read-only. `rpm-ostree status` names the deployments.

## Updates are staged, not applied

`rpm-ostree upgrade` stages a new deployment. An ordinary restart may boot the old one; use Restart & Update or check `rpm-ostree status` and boot the staged deployment, then confirm the kernel with `uname -r`. A pending deployment alone does not mean the update applied.

## composefs root vs fstab

`/etc/fstab` still lists a Btrfs root, but ostree mounts the live root as a read-only composefs overlay. `systemd-remount-fs.service` then fails to reconfigure it (`overlay: No changes allowed in reconfigure`); `ostree-remount.service` succeeds and the system is fine. Do not repair this by changing root mount flags, remounting the immutable root, or masking the units.

## Run another deployment's binary

Config loading happens before D-Bus name acquisition, so a binary from another deployment can prove which config it reads without booting it:

```sh
timeout 4 /sysroot/ostree/deploy/fedora/deploy/<id>/usr/libexec/upowerd
```

## Debugging "it worked before the update"

Check `rpm-ostree status`, then `findmnt /etc`, then diff the file against `/usr/etc/<config>` and the other deployment's copy; check journal startup warnings because absence is evidence; run that deployment's binary; only then suspect kernel or package differences.

## RAM measurement

Visible memory, firmware-reserved memory, installed DIMM capacity and zram swap are different numbers. A visible figure below the installed capacity does not prove a bad module; confirm with `sudo dmidecode --type memory` before changing inventory.
