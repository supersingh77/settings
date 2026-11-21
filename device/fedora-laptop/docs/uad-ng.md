# UAD-NG

UAD-NG removes selected packages for Android user 0 over ADB; it does not require root. Its GUI runs on the host, while `adb` comes from `fedora-toolbox-44`. Initial installation is handled by `scripts/setup-user.sh`; use `update-uad` to update the binary.

## Connect Your Phone

1. **Settings → About phone** — tap **Build number** 7 times to unlock Developer Options
2. **Settings → Developer Options** — enable **USB Debugging**
3. Connect via USB → tap **Allow** on the phone's prompt
4. Select **File Transfer (MTP)** as the USB mode

---

## Launch

Search GNOME Activities for **UAD-NG**, or run `launch-uad` for a launcher that checks the ADB state first.

---

## ADB Troubleshooting

| Symptom | Fix |
|---------|-----|
| No devices listed | Check cable, try another USB port |
| `unauthorized` | Tap **Allow** on phone's USB debugging prompt |
| `offline` | Revoke all USB debugging authorizations on phone, re-authorize |
| GUI shows no device | Confirm `adb devices` runs inside the container, not the host |
| Permission error | Install `android-udev-rules` inside container (see below) |

**udev rules** (if ADB can't open the USB device):

Install `android-udev-rules` in the toolbox and reload host udev rules if ADB reports a USB permission error.

**ADB server conflict** (if host `adb` is also running):

If the launcher does not appear, verify its desktop entry under `~/.local/share/applications/`.
