# Application Inventory — Fedora Silverblue 44

Current installed-app inventory. Re-query package managers after updates; this does not describe every package in Fedora's immutable base.

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
| Google Chrome | `com.google.Chrome` | 158.0.8127.36-1 | flathub |
| OBS Studio | `com.obsproject.Studio` | 32.2.2 | fedora |
| Sublime Text | `com.sublimehq.SublimeText` | 4215 | flathub |
| Celluloid | `io.github.celluloid_player.Celluloid` | 0.30 | flathub |
| Mission Center | `io.missioncenter.MissionCenter` | 1.2.0 | flathub |
| WebTorrent | `io.webtorrent.WebTorrent` | 0.24 | flathub |
| Fedora Media Writer | `org.fedoraproject.MediaWriter` | 5.3.2 | fedora |
| Flameshot | `org.flameshot.Flameshot` | 15.0.0 | flathub |
| Characters | `org.gnome.Characters` | 51.0 | flathub |
| Connections | `org.gnome.Connections` | 51.0 | fedora |
| Extensions | `org.gnome.Extensions` | 51.alpha | fedora |
| Logs | `org.gnome.Logs` | 50.0 | fedora |
| Image Viewer (Loupe) | `org.gnome.Loupe` | 51.rc | fedora |
| Sushi | `org.gnome.NautilusPreviewer` | 51.2 | fedora |
| Camera (Snapshot) | `org.gnome.Snapshot` | 51.0 | fedora |
| Disk Usage Analyzer | `org.gnome.baobab` | 50.0 | flathub |
| Clocks | `org.gnome.clocks` | 51.0 | fedora |
| Fonts | `org.gnome.font-viewer` | 50.0 | fedora |
| LocalSend | `org.localsend.localsend_app` | 1.18.2 | flathub |
| qBittorrent | `org.qbittorrent.qBittorrent` | 5.3.0 | flathub |
| VLC | `org.videolan.VLC` | 3.0.24 | flathub |
| LibreOffice | `org.libreoffice.LibreOffice` | _(not reported)_ | fedora |

---

## User Binaries (`~/.local/bin`)

| Binary / tracker | Version or status | Notes |
|------------------|-------------------|-------|
| `openwork` / `openwork.version` | 0.18.71 | AppImage extracted to `~/.local/lib/openwork`; see [OpenWork](docs/openwork.md) |
| `uad-ng` / `uad-ng.version` | 1.3.1 | Android debloater; launcher entry exists |
| `antigravity2` | 2.34.0-5887025308631040 | Launcher for Google Antigravity Hub tarball in `~/.local/lib/antigravity-hub/`; see below |
| `cursor.AppImage` | **Not verified as an installed application** | File exists, but its contents begin with an HTML Cursor website page, not an AppImage. Do not launch it as an application. Likely a mistaken download; remove only if you confirm you do not need the file. |

Versions above come from updater-managed tracker files. LibreOffice was present, but its Flatpak version was not reported.

---

## Toolbox Container

### `fedora-toolbox-44` — general (`fedora-toolbox:44`)

Packages are queried inside the container with the command below.

| Package | Installed version | Notes |
|---------|-------------------|-------|
| `android-tools` | 37.0.0p1-1.fc44 | adb/fastboot; used by UAD-NG |
| `ffmpeg-free` | 8.1.3-3.fc44 | Media tooling |
| `7zip`, `7zip-standalone` | 26.06-1.fc44 | Archive utility |
| `gh` | 2.97.0-2.fc44 | GitHub CLI |

---

## Inventory Scope

This inventory covers system Flatpaks; per-user Flatpaks, if installed, are not included.

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
