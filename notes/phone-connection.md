---
refs: devices/phone-personal/device.json, devices/phone-work/device.json, src/facets/android/android.ts, device:model, android:com.android.updater
---

# Redmi Note 11 phones

Both units are Xiaomi Redmi Note 11 (`2201117TI`, device `spes`, product `spes_in`): Qualcomm SM6225, 6.43-inch 1080x2400 AMOLED, 5000 mAh, USB-C. RAM differs: personal is the 6 GB model (5.5 GiB visible), work the 4 GB model (3.6 GiB visible). The work unit runs stock India MIUI `V816.0.6.0.TGCINXM` on Android 13 with a locked bootloader; do not flash a ROM without verified variant-specific recovery instructions.

## Capture

1. Settings, About phone: tap Build number seven times.
2. Settings, Developer options: enable USB debugging.
3. Connect by USB, choose File Transfer, tap Allow on the phone.
4. `adb` is the user-level platform-tools binary at `~/.local/lib/platform-tools/adb` on the host; there is no system package and no rpm-ostree layering.
5. Capture with `dev capture --device phone-personal` or `--device phone-work`; the serial lives in the device's `match.serial` (personal `6cbccfac`, work `d7587816`).
6. Both phones report the same model, so the serial, not the model, identifies the role.

USB debugging is normally off because of banking apps; enable it only while capturing or managing a phone. If adb cannot open a phone, install `android-udev-rules` in the toolbox and reload udev on the host, or use wireless debugging. UAD-NG launches with `bun run dev uad`, which starts it through its desktop entry and the same adb access.
