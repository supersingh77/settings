# Fedora Silverblue Laptop — System Setup

> **Status:** Active Fedora laptop (this is the current Linux device; `device/laptop*` documents a separate Windows gaming laptop)
> **Current host:** Fedora Silverblue 44.20261119.1 (kernel 7.3.4-200.fc44)

## Quick Reference

| Area | Current setup |
|---|---|
| **Hardware** | ASUS VivoBook X505ZA; Ryzen 5 2500U (4C/8T), Radeon Vega 8 |
| **Memory** | 10 GiB visible to Linux; 8 GiB zram swap. Physical module inventory is documented separately and remains unverified. |
| **Storage** | 480 GB WD Green NVMe (Silverblue/Btrfs); internal 1 TB Seagate HDD is present but not mounted |
| **OS** | Fedora Silverblue 44.20261119.1; kernel 7.3.4-200.fc44; immutable OSTree deployments |
| **Host packages** | rpm-ostree layers: distrobox, Ghostty, uhubctl; Firefox removed from base |
| **App model** | Desktop apps via system Flatpak; CLI/media/ADB tools in `fedora-toolbox-44`; selected user apps under `~/.local` |
| **Maintenance** | `update` stages host OS updates (reboot to apply); `cleanup` runs slower filesystem/app maintenance |

## Documentation Map

- **[Hardware](hardware.md)** — machine details, verified memory caveat, storage and power quirks
- **[Applications](apps.md)** — current Flatpak, rpm-ostree, toolbox, and user-binary inventory
- **[Setup and daily workflow](#-fresh-install--start-here)** — bootstrap and phased installation
- **[Shell reference](docs/shell.md)** — aliases and shell configuration
- **[Troubleshooting](docs/troubleshooting.md)** — symptoms and recovery steps
- **[Lessons learned](docs/lessons.md)** — Silverblue-specific deployment and incident lessons

> Current-state notes and fresh-install steps are separate; review setup scripts before reusing them.

---

## 🚀 Fresh Install — Start Here

On a brand-new Silverblue install, run the bootstrap script. It handles everything to get you from zero to a cloned repo with apps installed:

```bash
curl -fsSL https://raw.githubusercontent.com/supersingh77/settings/main/device/fedora-laptop/scripts/bootstrap.sh | bash
```

**What bootstrap does:**
1. Generates an SSH key and guides you to add it to GitHub
2. Clones this repo to `~/Desktop/settings/device/fedora-laptop`
3. Installs Phase 1 Flatpak apps (Chrome, VLC, etc.)
4. Downloads UAD-NG and installs its GNOME launcher entry
5. Adds shell aliases (`docs`, `update`, `update-openwork`, `update-uad`, `uad`)
6. Prints next steps for Phase 2 and Phase 3

After bootstrap, continue with the phases below.

---

## 📦 Setup Phases

### Phase 2 — RPM Layers (requires reboot)

Installs: **distrobox**, **ghostty**, **uhubctl**. Removes: **Firefox**.

```bash
bash ~/Desktop/settings/device/fedora-laptop/scripts/setup-phase2.sh
```

Reboot when prompted, then run Phase 3.

---

### Phase 3 — Containers + OpenWork (after Phase 2 reboot)

Creates the general toolbox container and installs OpenWork:

```bash
bash ~/Desktop/settings/device/fedora-laptop/scripts/setup-phase3.sh
```

| What | Notes |
|------|-------|
| `fedora-toolbox-44` | General — adb, ffmpeg, 7zip, gh |
| OpenWork | AI IDE at `~/.local/bin/openwork` (wrapper to `~/.local/lib/openwork`) |

After Phase 3 completes:

```bash
source ~/.bashrc   # activate aliases in current shell

openwork           # launch OpenWork AI IDE
```

---

## ⚡ Daily Commands

```bash
# Repository quality audit (lint, tests, comments, dates, local links)
python3 ~/Desktop/settings/scripts/audit.py

# Fast daily update (Flatpaks + OpenWork + UAD-NG + Antigravity + toolbox + rpm-ostree)
update

# The script stages rpm-ostree changes; they take effect only after reboot.
rpm-ostree status          # inspect the booted and pending deployments
sudo systemctl reboot      # boot the staged deployment

# Slow maintenance — run occasionally (btrfs scrub, flatpak cleanup, journal vacuum, DNS flush, trash empty)
cleanup

# OpenWork only
update-openwork

# UAD-NG only
update-uad

# Antigravity 2.0 only
update-antigravity

# Manual update steps
rpm-ostree upgrade          # stage system update (reboot to apply)
flatpak update              # update Flatpak apps (no reboot)

# Check system status
rpm-ostree status

# Android debloating
uad
```

---

## 🐳 Containers Quick Reference

```bash
# General container (adb, ffmpeg, gh)
toolbox enter fedora-toolbox-44

# List all containers
toolbox list
```

---

## 🖥️ GNOME Layout (Coordination Rule)

Same principle as the Windows desktop: an app lives in exactly **one** place — no redundancy.

| Place | Role | Example |
|-------|------|---------|
| **Favorites bar** (dock) | Daily drivers only | Chrome, Files, Terminal, OpenWork |
| **App grid** (Activities) | Everything else | VLC, UAD-NG, Ghostty, Antigravity |

- Keep the favorites bar short — if you haven't opened it this week, unpin it.
- GNOME has no desktop icons by default; don't add extensions just to recreate them.
- Search (Super key) reaches any app instantly — the grid is a fallback, not a filing system.

---

## 🔑 GitHub SSH (Multi-Account)

Two SSH identities configured in `~/.ssh/config`. **`supersingh77` is the default** — plain `git@github.com:...` uses it. The `gameb30232` account is accessed explicitly via its alias.

| Host | Account | Key |
|------|---------|-----|
| `github.com` (default) | supersingh77 | `~/.ssh/id_ed25519_supersingh77` |
| `github.com-gameb30232` | gameb30232 | `~/.ssh/id_ed25519_gameb30232` |

```bash
# Default (supersingh77) — plain URL, no alias needed
git clone git@github.com:supersingh77/some-repo.git

# gameb30232 — use the explicit alias
git clone git@github.com-gameb30232:gameb30232/some-repo.git

# Test connections
ssh -T git@github.com
ssh -T git@github.com-gameb30232

# Daily git workflow
git status
git add -A
git commit -m "message"
git push

# GitHub CLI (inside toolbox)
toolbox run -c fedora-toolbox-44 gh repo view
toolbox run -c fedora-toolbox-44 gh auth status
```

SSH keys live at `~/.ssh/`. The private keys (`id_ed25519_supersingh77`, `id_ed25519_gameb30232`) are **never** committed.

---

## 📱 Android Debloating (UAD-NG)

UAD-NG runs via `fedora-toolbox-44` (which has `adb` installed). Setup is handled by `bootstrap.sh`.

```bash
bash ~/Desktop/settings/device/fedora-laptop/scripts/launch-uad.sh  # launch with device checks
toolbox run -c fedora-toolbox-44 adb devices                  # check ADB manually
```

Search **UAD-NG** in GNOME Activities to launch from the app grid. See **[`docs/uad-ng.md`](docs/uad-ng.md)** for USB debugging steps, ADB troubleshooting, and update instructions.

---

## Troubleshooting

Use [`docs/troubleshooting.md`](docs/troubleshooting.md) for current recovery guidance. The longer [`docs/lessons.md`](docs/lessons.md) file is retained for the Silverblue deployment and battery quirks documented there.

---

## 📂 Repository Structure

```
device/fedora-laptop/
├── README.md                        ← You are here
├── hardware.md                      ← Hardware specs + Btrfs filesystem details
├── apps.md                          ← Full app inventory (Flatpak, toolbox, host binaries)
├── docs/
│   ├── shell.md                     ← Shell config (~/.bashrc, aliases reference)
│   ├── uad-ng.md                    ← Android debloating guide (UAD-NG v1.2.0)
│   ├── openwork.md                  ← OpenWork architecture + update guide
│   ├── audio-denoise.md             ← Audio extraction/merging guide (Adobe Podcast)
│   ├── lessons.md                   ← Hard-won lessons (per-deployment /etc, UPower fallbacks, journal forensics)
│   └── troubleshooting.md          ← All known issues and fixes
└── scripts/
    ├── _lib.sh                      ← Shared functions (colors, logging, download_file)
    ├── bootstrap.sh                 ← 🌟 START HERE on a fresh install
    ├── setup-phase2.sh              ← Phase 2: RPM repos + layered packages + reboot
    ├── setup-phase3.sh              ← Phase 3: toolbox container + OpenWork AppImage
    ├── install-links.sh             ← Symlink runtime scripts into ~/.local/bin
    ├── update-system.sh             ← Fast daily update (alias: update)
    ├── cleanup-system.sh            ← Slow maintenance: btrfs scrub, flatpak cleanup, DNS flush, trash (alias: cleanup)
    ├── update-openwork.sh           ← OpenWork AppImage update (alias: update-openwork)
    ├── update-uad.sh                ← UAD-NG binary update (alias: update-uad)
    ├── update-antigravity.sh        ← Antigravity 2.0 Hub update
    ├── launch-uad.sh                ← UAD-NG launcher with ADB device checks
    ├── join-videos.sh               ← Lossless concat of video clips (ffmpeg)
    ├── uad-ng.desktop               ← GNOME desktop entry for UAD-NG
    ├── parallel-download.py         ← Multi-connection downloader (used by setup scripts)
    ├── audio-denoise.sh             ← Automate audio extraction and merging
    └── 99-ignore-dead-battery.rules ← udev rule to silence dead battery errors
```

---

## 🤖 AI Agents

| Agent | Source | Install | Alias |
|-------|--------|---------|-------|
| **OpenWork** | AppImage (`~/.local/lib/openwork/`) | `update-openwork` | (in PATH) |
| **Antigravity 2.0** | Tarball (`~/.local/lib/antigravity-hub/`) | `update-antigravity` | `antigravity2` |

**Update OpenWork:**
```bash
update-openwork
```

**Update Antigravity 2.0:**
```bash
update-antigravity
```

**Antigravity 2.0** is a standalone Electron app installed at `~/.local/lib/antigravity-hub/`. Launch with:
```bash
antigravity2
```

> **Note**: The old `antigravity` RPM package (1.x) is no longer used. Antigravity 2.x is distributed as a self-contained tarball from the [download page](https://antigravity.google/download). To update, download the latest tarball and extract it over the existing `~/.local/lib/antigravity-hub/` directory.

---

*"The best way to predict the future is to document it."*
