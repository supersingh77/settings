# C: Drive — Disk Cleanup Reference

> Evergreen reference for freeing space on the Windows desktop. Distilled from the
> 03 Aug 2026 cleanup (freed ~13 GB). The original one-off report is gone; this is
> the reusable knowledge.

---

## 1. Junk — Safe to Delete (recurring)

| What | Where |
|------|-------|
| Temp files / mod zips | `C:\Users\<user>\AppData\Local\Temp\` |
| Game demos/recordings | `C:\Users\<user>\AppData\Local\VALORANT\Saved\Demos\` |
| Recycle Bin | `C:\$Recycle.Bin\` |
| Windows Update staging | `C:\$WinREAgent\` (restart first, then Disk Cleanup handles it) |
| App updater leftovers | `...\AppData\Local\kimi-desktop-updater\`, `@openworkdesktop-updater\`, `obsidian-updater\`, `notion-updater\` |
| Old installers in Downloads | `C:\Users\<user>\Downloads\` |
| Crash dumps | `C:\Users\<user>\AppData\Local\CrashDumps\` |

## 2. Caches — Safe to Clear (rebuild over time)

| What | Where / How |
|------|-------------|
| Spotify offline/cache | In-app: Settings → Storage → Clear cache / remove downloads |
| Chrome caches | In Chrome: Settings → Privacy → Clear browsing data → Cached images/files |
| Kimi desktop app data | `...\AppData\Roaming\kimi-desktop\` (close app first) |
| Codex runtime cache | `C:\Users\<user>\.cache\codex-runtimes\` (re-downloads on demand) |
| AMD shader caches | `C:\Users\<user>\AppData\Local\AMD\` (DxCache/VkCache/OglCache/DX9Cache) |
| Edge / Discord caches | `...\AppData\Local\Microsoft\Edge\`, `...\AppData\Roaming\discord\` |
| uv + npm caches | `uv cache clean`, `npm cache clean --force` |

## 3. System-Level (admin)

| What | Command |
|------|---------|
| Disk Cleanup (system files) | `cleanmgr /d C:` → "Clean up system files" |
| WinSxS component cleanup | `Dism.exe /Online /Cleanup-Image /StartComponentCleanup` (frees 2–5 GB) |
| WSL (if unused) | `dism /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart` |
| Windows Installer cache | Do NOT delete manually — use Disk Cleanup "system files" |

## 4. Prevention Habits

- **Keep big downloads off C:** — mods/archives → `Z:\`, videos/recordings → `Z:\` (OBS output drive).
- **Scoop caching:** run `scoop cache rm` occasionally.
- **Weekly habit:** empty Downloads of installers, clear Spotify offline songs when done.
- **Storage Sense:** Settings → System → Storage → enable Storage Sense (auto-clean temp files).

## 5. Drive Map (as of Aug 2026)

| Drive | Purpose |
|-------|---------|
| C: (126 GB NVMe) | OS + apps — keep lean |
| V: (350 GB) | Games (Steam, Riot, Liftoff) — was nearly full, watch this |
| Z: (1 TB HDD) | Mods, media, recordings — the overflow target |
