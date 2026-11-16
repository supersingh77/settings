# Laptop Software Documentation — Installed & Excluded Apps

> Documented: 12 August 2026 | Updated: 1 September 2026
> Device: ASUS ROG Strix G513QY (Laptop)
> Package Managers: **winget** ✅ (primary) | **scoop** ✅ (only innounp remains)
> Source: `scoop list`, registry uninstall keys, `winget list`

---

## Installed Software Inventory

### Scoop Installed (CLI & dev tools)

> Policy: **winget is now the primary package manager** — most CLI/dev tools migrated to winget (1 Sep 2026). Scoop kept only for tools without a good winget manifest.

| Software | Bucket | Notes / Purpose |
|---|---|---|
| **innounp** | main | Inno Setup unpacker |

### Winget / Manual Installed (GUI apps)

| Software | Notes |
|---|---|
| **Windows Terminal** | Modern terminal environment |
| **PowerShell 7** | Modern shell (moved from scoop) |
| **Git** | Dev tool / source control (moved from scoop) |
| **FFmpeg** | Media conversion framework (moved from scoop) |
| **MediaInfo-CLI** | Media metadata viewer (moved from scoop) |
| **UAD-NG** | Universal Android Debloater (moved from scoop — winget manifest now works) |
| **GitHub CLI** | Command-line GitHub client |
| **7-Zip** | Archive utility (moved from scoop) |
| **Google Chrome** | Browser |
| **Discord** | Chat and community voice (moved from scoop) |
| **ShareX** | Screenshot & screen capture (moved from scoop) |
| **OBS Studio** | Core streaming & screen recording (moved from scoop) |
| **HandBrake** | Video transcoder (moved from scoop) |
| **Audacity** | Audio editor (moved from scoop) |
| **PicoTorrent** | Lightweight BitTorrent client (moved from scoop) |
| **HWiNFO** | System hardware monitoring (moved from scoop) |
| **CPU-Z** | CPU / memory diagnostics (moved from scoop) |
| **Foxit PDF Reader** | PDF viewer (moved from scoop) |
| **LocalSend** | Local network file transfer (moved from scoop) |
| **Mozilla Firefox (en-GB)** | Backup browser |
| **Microsoft Edge** | Default browser |
| **Microsoft Office Professional Plus 2021** | Office suite |
| **Microsoft OneDrive** | Cloud file sync |
| **PDFgear** | PDF reader/editor |
| **VLC media player** | Media player |
| **PotPlayer (64-bit)** | Media player |
| **Cursor** | AI-first code editor |
| **MiniMax Code** | AI coding assistant |
| **Visual Studio (Community, 17.13)** | IDE components |
| **Windows SDK AddOn** | Dev SDK |
| **DroidCam Client** | Phone webcam over Wi-Fi/LAN |
| **Quick Share** | Nearby file sharing |
| **NoteBook FanControl** | Fan control utility |
| **Universal ADB Driver** | Android debugging |
| **OpenWork Cloud** | Agentic work app |
| **Steam** | Primary game launcher |
| **Antigravity** | AI cowork desktop app (GUI) |

### AI Tools

> Policy: **GUI / cowork desktop apps only** — no CLI agents (Kimi CLI, agy, codex) needed.

| Software | Notes |
|---|---|
| **Claude** (Anthropic) | Desktop AI assistant |
| **ChatGPT** (OpenAI) | Desktop AI assistant |
| **Kimi** (Moonshot AI) | AI assistant |
| **MiniMax Code** | AI coding assistant |
| **Antigravity** | AI cowork desktop app (GUI) |
| **ACE Studio** | Vocal synthesis / music |

### Games (Steam)

Installed titles: Celeste, DOOM, Hades, Hollow Knight, KovaaK's, Lethal Company, Shadow of the Tomb Raider, Undertale

---

## Excluded from Laptop (Cut the Crap)

Nothing was brought over from the desktop beyond what's already installed. The following desktop items are deliberately **not** on the laptop:

| Software / Script | Desktop Context | Reason Excluded on Laptop |
|---|---|---|
| **PXN SimRacing & vJoy** | Desktop steering wheel setup | Desktop-only peripheral |
| **AMD Ryzen Master** | Desktop CPU overclocking | Laptop handled by Armoury Crate / G-Helper |
| **Twinkle Tray** | External DDC/CI monitor brightness | Laptop uses native Fn key brightness |
| **autohotkey** | Desktop automation | No automation needs on laptop |
| **Streamlabs OBS** | Alternative streaming app | Redundant — OBS Studio already installed |
| **Assetto Corsa + Content Manager** | Desktop sim-racing setup | Tied to desktop wheel setup |
| **Guitar Pro 8** | Music tablature editor | Not needed on laptop |
| **Chrome Remote Desktop** | Remote access | Not needed on laptop |
| **DroidCam OBS Plugin** | OBS phone-webcam plugin | Not needed on laptop |
| **Desktop-only games** (Forza Horizon 6, Overwatch, Wallpaper Engine, Mixtape, MECCHA CHAMELEON, Keep Talking, Liftoff, Quake III, osu!) | Desktop game library | Not played on laptop |
| **Hardcoded `V:\` & `Z:\` Paths** | Desktop 3-drive layout | Laptop uses `C:\` + `D:\` |

---

## Maintenance & App Sync Workflow

Ongoing updates:
- `winget upgrade --all` — update all winget packages (primary)
- `scoop update *` — update remaining scoop packages (innounp only)

Current update candidates (from winget): none — all packages up to date as of 1 Sep 2026.

---

## Notes for the agent

- **Package consolidation (1 Sep 2026)**: winget is now the primary package manager. Migrated git, ffmpeg, mediainfo, pwsh, uad-ng, 7-Zip from scoop to winget. Removed speedtest + dark (no longer needed). Scoop now only holds innounp.
- **Maintenance Script:** `device/laptop/scripts/cleanup-system.ps1` (with `update` and `cleanup` PowerShell profile functions in `Documents\PowerShell\Microsoft.PowerShell_profile.ps1`).
- **Storage rules**: core tools/shells on `C:\`; Steam library, large mods, and OBS output on `D:\`.
- **Games** are installed via Steam; Riot Vanguard implies a Riot title (Valorant/League) is present.
- **ACE Studio** is a vocal-synthesis app — likely used for music/voice work.
- **DroidCam + Universal ADB Driver** suggest phone-as-webcam and Android debugging workflows.
- **AI tools are GUI/cowork desktop apps only** — no CLI agents (Kimi CLI, agy, codex) needed.
- This list is a snapshot; re-run the source commands to refresh it.