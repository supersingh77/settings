---
refs: devices/phone-personal/device.json, devices/phone-personal/state/android.jsonl, src/facets/android/android.ts, device:model, android:com.android.updater
---

# Android capture

`android` is observed. It runs the user-level `adb` at `~/.local/lib/platform-tools/adb` on the host, against the serial recorded in the device's `match.serial`, and reads `getprop`, `/proc/meminfo` and three `pm list packages --user 0` variants in one device shell call.

Items are `android:<package>` with `a.installed` and `a.thirdParty`. The all-including-uninstalled list is the source, so not-installed packages are derivable and the four old Markdown lists are not needed. Device facts are `device:*` items plus `mem:total` (GiB visible to Android, one decimal).

Phones are captured with `--device phone-personal` or `--device phone-work`; `via: fedora-laptop` records that the laptop reaches them over adb. The facet stays observed because the old tool only captured too, and rewriting phone packages is not safe to automate.

The personal phone (6 GB model, 5.5 GiB visible, serial `6cbccfac`) is captured. The work phone (4 GB) still needs its serial and a capture once it is plugged in.
