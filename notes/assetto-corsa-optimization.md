# 02 — Assetto Corsa Optimization

> Goal: Higher FPS for smoother gameplay + streaming
> Hardware: Ryzen 7 5700X | RX 7600 8GB | 16GB RAM | 1080p @ 120Hz

---

## Will changing settings affect my brother?

### Per-user settings (safe — only affects `C:\Users\amar\`)
| File | Location | Shared? |
|------|----------|---------|
| `video.ini` | `%USERPROFILE%\Documents\Assetto Corsa\cfg\` | ✅ **Per-user** |
| All in `%USERPROFILE%\Documents\Assetto Corsa\cfg\` | Controllers, audio, assists, etc. | ✅ **Per-user** |
| Content Manager config | `%LOCALAPPDATA%\AcTools Content Manager\` | ✅ **Per-user** |
| CSP state (Lua scripts cache) | `%USERPROFILE%\Documents\Assetto Corsa\cfg\extension\` | ✅ **Per-user** |

### Shared settings (affects ALL Windows users on this PC)
| File | Location | Shared? |
|------|----------|---------|
| CSP configs (lighting, weather, etc.) | `V:\Games\...\assettocorsa\extension\config\` | ⚠️ **Shared** |
| AC car/track content | `V:\Games\...\assettocorsa\content\` | ⚠️ **Shared** |

**Bottom line:** AC video settings (resolution, world detail, shadows, AA) are per-user. CSP visual mod configs are shared in the game folder. If your brother uses different CSP settings, you'd need separate game installs or manually swap configs.

---

## 💡 How to modify AC settings safely (verified 01 Jul 2026)

1. **Close Content Manager** before editing files directly — otherwise it can overwrite your changes on exit
2. **Per-user files** (`%USERPROFILE%\Documents\Assetto Corsa\cfg\`) can be edited freely — brother unaffected
3. **Shared CSP files** (`V:\Games\...\assettocorsa\extension\config\`) affect all Windows users — edit only if brother agrees
4. **CM loads the .ini files on startup** — no special deploy step needed, just edit and relaunch CM
5. **Content Manager .cmpreset presets** (`%LOCALAPPDATA%\AcTools Content Manager\Presets\`) are JSON-wrapped .ini strings — can be created manually for persistent preset switching

## Current Settings (01 Jul 2026)

Current live settings after testing. Also saved in `Assetto Corsa Settings/Documents_Assetto_Corsa_cfg/video.ini`.

### `video.ini` — Current ✅

| Setting | Value | Notes |
|---------|-------|-------|
| **World Detail** | 5 (Ultra) | Maxed out |
| **Shadow Map Size** | **2048** | ⬆️ Increased from 1024 — cleaner shadows, less aliasing |
| **MSAA** | **4x** | ⬆️ Increased from 2x — smoother edges on trees & track |
| **Anisotropic Filtering** | 16x | Maxed out for sharp distant textures |
| **Smoke** | **2** | ⬆️ From 1 — more visible tire smoke |
| **Post-Processing** | **ON** (default_bright filter) | Brighter exposure helps see corners |
| **Saturation** | 100 | Default |
| **VSync** | OFF | Reduces input lag |
| **FPS Cap** | ~240 (4.16ms) | Auto-detected by CM |
| **FPS Benchmark** | **Avg 210 / Min 198** | Massive headroom for 120Hz |

### Folder structure

All AC config files organized in `Assetto Corsa Settings/`:
- `Documents_Assetto_Corsa_cfg/` → copy to `%USERPROFILE%\Documents\Assetto Corsa\cfg\`
- `CM_Presets/` → Content Manager presets (`%LOCALAPPDATA%\AcTools Content Manager\Presets\`)
- `Backup_Original/` → Original untouched files before any edits

### Content Manager tips

- **Quick Drive** → Only enable cars you're racing against, not all 185
- **Settings → Assetto Corsa → Video** → Reduce "Maximum visible cars" to 10-15
- **Settings → CSP → Performance** → Use the performance presets as a baseline

### While streaming (OBS running)

- Close Chrome/Firefox (browsers eat VRAM and RAM)
- Set OBS encoder to **AMD AMF Hardware (H.264)** — offloads encoding to GPU
- Don't run other GPU-heavy apps
