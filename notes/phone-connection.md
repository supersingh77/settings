---
refs: devices/phone-personal/device.json, src/facets/android/android.ts, device:model, android:com.android.updater
---

# Connecting a phone

1. Settings, About phone: tap Build number seven times.
2. Settings, Developer options: enable USB debugging.
3. Connect by USB, choose File Transfer, tap Allow on the phone.
4. `adb` is the user-level platform-tools binary at `~/.local/lib/platform-tools/adb` on the host; there is no system package and no rpm-ostree layering.
5. Capture with `dev capture --device phone-personal` (or `phone-work`); the serial comes from the device's `match.serial`.

Both phones are Redmi Note 11 (`2201117TI`, device `spes`) and differ by RAM, so the serial, not the model, identifies the role. If adb cannot open the device, install `android-udev-rules` in the toolbox and reload udev on the host, or use wireless debugging.

UAD-NG is still installed and launched by the legacy `laptop` command; it needs the same adb access.
