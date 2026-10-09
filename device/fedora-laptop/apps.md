# Application Inventory — Fedora Silverblue 44

**Last verified**: 2026-10-08 (before the current `update` run completed)

**Host deployment at verification**: Fedora Silverblue `44.20261006.0`, kernel `7.2.8-200.fc44`
**Update available at verification**: `44.20261008.0`, including kernel `7.2.9-200.fc44` and UPower `1.91.5`; pending, not booted.

This is a point-in-time inventory, not a record of every package in Fedora's immutable base. The live system was checked with `rpm-ostree status`, `rpm -q`, `flatpak list`, `toolbox list`, and version tracker files. Run this inventory again after system updates or installs.

---

## rpm-ostree Layered Packages

| Package | Installed version | Notes |
|---------|-------------------|-------|
| `distrobox` | 1.8.2.5-1.fc44 | Container environments |
| `ghostty` | 1.3.1-1.202609262124.fc44 | GPU-accelerated terminal |
| `uhubctl` | 2.6.0-5.fc44 | USB hub per-port power control |

Firefox and Firefox language packs are removed from the base deployment, matching the setup documented in `README.md`.

---

## Flatpak Applications (system installation)

| Name | Application ID | Version | Remote |
|------|----------------|---------|--------|
| Google Chrome | `com.google.Chrome` | 154.0.8037.97-1 | flathub |
| OBS Studio | `com.obsproject.Studio` | 32.1.1 | fedora |
| Sublime Text | `com.sublimehq.SublimeText` | 4215 | flathub |
| Celluloid | `io.github.celluloid_player.Celluloid` | 0.30 | flathub |
| Mission Center | `io.missioncenter.MissionCenter` | 1.2.0 | flathub |
| WebTorrent | `io.webtorrent.WebTorrent` | 0.24 | flathub |
| Fedora Media Writer | `org.fedoraproject.MediaWriter` | 5.3.2 | fedora |
| Flameshot | `org.flameshot.Flameshot` | 14.0.0 | flathub |
| Characters | `org.gnome.Characters` | 51.0 | flathub |
| Connections | `org.gnome.Connections` | 50.0 | fedora |
| Extensions | `org.gnome.Extensions` | 50.2 | fedora |
| Logs | `org.gnome.Logs` | 50.0 | fedora |
| Image Viewer (Loupe) | `org.gnome.Loupe` | 50.0 | fedora |
| Sushi | `org.gnome.NautilusPreviewer` | 46.0 | fedora |
| Camera (Snapshot) | `org.gnome.Snapshot` | 50.0 | fedora |
| Disk Usage Analyzer | `org.gnome.baobab` | 50.0 | flathub |
| Clocks | `org.gnome.clocks` | 50.0 | fedora |
| Fonts | `org.gnome.font-viewer` | 50.0 | fedora |
| LocalSend | `org.localsend.localsend_app` | 1.18.2 | flathub |
| qBittorrent | `org.qbittorrent.qBittorrent` | 5.2.4 | flathub |
| VLC | `org.videolan.VLC` | 3.0.23 | flathub |

> Flatpak versions and installed runtimes can change independently of the booted Silverblue deployment. SVG-only icons may show as a gear in GNOME; see [Troubleshooting §2](docs/troubleshooting.md#2-missing-app-icons-gear-icon).

---

## User Binaries (`~/.local/bin`)

| Binary / tracker | Version or status | Notes |
|------------------|-------------------|-------|
| `openwork` / `openwork.version` | 0.18.56 | AppImage extracted to `~/.local/lib/openwork`; see [OpenWork](docs/openwork.md) |
| `uad-ng` / `uad-ng.version` | 1.2.0 | Android debloater; launcher entry exists |
| `antigravity2` | 2.19.1-6046815158665216 | Launcher for Google Antigravity Hub tarball in `~/.local/lib/antigravity-hub/`; see below |
| `cursor.AppImage` | **Not verified as an installed application** | File exists, but its contents begin with an HTML Cursor website page, not an AppImage. Do not launch it as an application. Likely a mistaken download; remove only if you confirm you do not need the file. |

The versions above come from updater-managed tracker files, not an independent check of each application's running binary. OpenWork can print a development-server port-in-use error when invoked for a version check while already running; it is not a reliable standalone version probe.

---

## Toolbox Container

### `fedora-toolbox-44` — general (`fedora-toolbox:44`)

The container exists and was **exited** at inventory time. Its installed packages were queried by running `rpm -q` inside the container.

| Package | Installed version | Notes |
|---------|-------------------|-------|
| `android-tools` | 37.0.0-4.fc44 | adb/fastboot; used by UAD-NG |
| `ffmpeg-free` | 8.1.3-1.fc44 | Media tooling |
| `7zip` | 26.03-1.fc44 | Archive utility |
| `7zip-standalone` | 26.03-1.fc44 | Archive utility |
| `gh` | 2.97.0-2.fc44 | GitHub CLI |

---

## Comparison with the Previous Inventory

### Previously documented with a different origin

- `org.gnome.baobab` (Disk Usage Analyzer) is still installed; its origin is now **flathub** rather than the previously documented Fedora remote.

### Present now, missing from the previous inventory

- OBS Studio (`com.obsproject.Studio`) — Fedora remote.
- Sublime Text (`com.sublimehq.SublimeText`) — Flathub.
- Connections (`org.gnome.Connections`) — Fedora remote.
- LocalSend (`org.localsend.localsend_app`) — Flathub.

### Apps that may look like removals but are still installed

- **Characters (`org.gnome.Characters`) is installed**, so do not treat it as removed; it changed from the Fedora remote to Flathub.
- The remaining previously documented Flatpak applications were present at verification. **No previously listed application was found removed.** The inventory is for the system installation; a different per-user Flatpak installation, if any, was not inventoried.

---

## Recheck Commands

```bash
rpm-ostree status
rpm -q distrobox ghostty uhubctl
flatpak list --app --columns=application,name,version,branch,origin,installation
toolbox list
toolbox run -c fedora-toolbox-44 rpm -q android-tools ffmpeg-free 7zip 7zip-standalone gh
cat ~/.local/bin/openwork.version ~/.local/bin/uad-ng.version ~/.local/lib/antigravity-hub/version
```
