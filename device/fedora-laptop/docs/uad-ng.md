# UAD-NG

**Version**: v1.2.0 | **Binary**: `~/.local/bin/uad-ng` | **ADB via**: `fedora-toolbox-44`

UAD-NG removes bloatware from non-rooted Android devices over ADB. On Silverblue the GUI binary lives on the host; ADB is provided by `android-tools` inside `fedora-toolbox-44`.

> Initial setup is handled by `scripts/setup-user.sh`. Use the steps below only for manual reinstall.

---

## Install (manual)

```bash
# 1. Binary
curl -L -C - \
  "https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/releases/download/v1.2.0/uad-ng-linux" \
  -o ~/.local/bin/uad-ng && chmod +x ~/.local/bin/uad-ng

# 2. Icon + cache
mkdir -p ~/.local/share/icons/hicolor/128x128/apps
curl -fsSL "https://raw.githubusercontent.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/main/resources/assets/logo-light.png" \
  -o ~/.local/share/icons/hicolor/128x128/apps/uad-ng.png
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor/

# 3. Desktop entry
cp ~/Desktop/settings/device/fedora-laptop/scripts/uad-ng.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/
```

---

## Connect Your Phone

1. **Settings → About phone** — tap **Build number** 7 times to unlock Developer Options
2. **Settings → Developer Options** — enable **USB Debugging**
3. Connect via USB → tap **Allow** on the phone's prompt
4. Select **File Transfer (MTP)** as the USB mode

---

## Launch

```bash
# Via GNOME Activities — search "UAD-NG"

# Via launcher script (checks for device first)
bash ~/Desktop/settings/device/fedora-laptop/scripts/launch-uad.sh

# Direct
toolbox run -c fedora-toolbox-44 ~/.local/bin/uad-ng
```

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

```bash
toolbox run -c fedora-toolbox-44 sudo dnf install -y android-udev-rules
sudo udevadm control --reload-rules && sudo udevadm trigger
```

**ADB server conflict** (if host `adb` is also running):

```bash
adb kill-server 2>/dev/null || true
```

---

## Update

UAD-NG auto-fetches the latest bloatware package lists on every launch. To update the binary:

```bash
update-uad
```

Or update it as part of the full system update:

```bash
update
```

---

## Files

| Path | Purpose |
|------|---------|
| `~/.local/bin/uad-ng` | Binary |
| `~/.local/share/applications/uad-ng.desktop` | GNOME launcher entry |
| `~/.local/share/icons/hicolor/128x128/apps/uad-ng.png` | Icon |
| `scripts/uad-ng.desktop` | Desktop entry source (this repo) |
| `scripts/launch-uad.sh` | Launcher with ADB checks |

If the launcher entry does not appear, verify the generated desktop file under `~/.local/share/applications/` and refresh the GNOME session.
