# C: Drive — Cleanup Reference

> Updated: 18 Nov 2026 | C: **65.5 GB free** of 126.1 GB · V: 133.0 GB free · Z: 478.4 GB free
> Free space is a snapshot, not an invariant: re-run `pwsh device/desktop/scripts/audit-state.ps1` before quoting it.
> Evergreen checklist for the Windows desktop. Verify sizes before deleting anything.

## Drive Map

Measured 18 Nov 2026. The drive letters are deliberate (`V:` games, `Z:` archive) — see [hardware.md](hardware.md) for the map.

| Drive | Label | Size | Free | Purpose |
|-------|-------|------|------|---------|
| **C:** | _(System)_ | 126.1 GB | **65.5 GB** | OS + core apps |
| **V:** | Vacuum Drive | 350.0 GB | 133.0 GB | Games, streaming software |
| **Z:** | Mass Storage | 931.5 GB | 478.4 GB | Recordings, VODs, archives |

## Where C: Went (16 Nov 2026)

| Path | Size | Note |
|------|------|------|
| `C:\Windows` | 23.3 GB | Includes WinSxS; the recursive total double-counts hardlinks |
| `C:\pagefile.sys` | 11.0 GB | System-managed pagefile — leave it |
| `C:\Users\amar` | 12.5 GB | `AppData` is 10.0 GB of that |
| `C:\Program Files` | 5.9 GB | |
| `C:\Program Files (x86)` | 5.9 GB | |
| `%LOCALAPPDATA%\Google` | 3.1 GB | Chrome profile + cache |
| `C:\Users\amar\Videos` | 0 GB | **Cleaned 17 Nov 2026** — the 1.87 GB of OBS recordings moved to `Z:\Recordings`. OBS has written there directly since 16 Nov. |

## Safe Recurring Cleanup

| What | Where / How |
|------|-------------|
| Recordings parked on C: | `C:\Users\amar\Videos` — check it is empty of `.mp4`/`.mkv`/`.m4a`/`.mov`; OBS writes straight to `Z:\Recordings` since 16 Nov |
| User + Windows temp | `%TEMP%`, `C:\Windows\Temp` |
| Recycle Bin | `Clear-RecycleBin` or Disk Cleanup |
| Windows Update staging | Disk Cleanup → "Windows Update Cleanup"; don't delete `SoftwareDistribution` manually while updates are pending |
| Old installers | `%USERPROFILE%\Downloads` — keep only what you still need |
| AMD installer leftovers | `C:\AMD` — now only empty stub dirs + one log; safe to remove |
| AMD shader caches | `%LOCALAPPDATA%\AMD\DxCache`, `VkCache`, `OglCache`, `DX9Cache` |
| Discord / Chrome caches | In-app cache clearing; avoid deleting the whole profile |
| Steam shader cache | `steamapps\shadercache` — Steam rebuilds it; optional |
| Crash dumps | `%LOCALAPPDATA%\CrashDumps` |

## System-Level (admin)

| Task | Command |
|------|---------|
| Disk Cleanup incl. system files | `cleanmgr /d C:` → "Clean up system files" |
| Component store cleanup | `Dism.exe /Online /Cleanup-Image /StartComponentCleanup` |
| WSL removal (only if unused) | `dism /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart` |
| Windows Installer cache | **Do not delete manually** — use Disk Cleanup |

## Last Cleanup (23 Oct 2026)

| Target | Before | Result |
|--------|--------|--------|
| `C:\AMD` | 3.0 GB | Removed (dirs partially recreated by a later installer run, now empty) |
| `C:\Users\amar\Downloads\drivers-26h2` | 1.81 GB | Removed |
| `C:\Windows.old` | **38.0 GB** | Removed — old `puruhn` profile with Scoop reparse points |
| `C:\Windows\SoftwareDistribution\Download` | 2.42 GB | Cleared |
| `%LOCALAPPDATA%\Temp` | 0.27 GB | Cleared (2 in-use files remain, 0.7 MB) |

**Result:** C: went from **52.2 GB → 98.8 GB free** (46.6 GB reclaimed) at that moment.

> That 98.8 GB did not survive the app re-population and was never a reconciled figure — three weeks later C: sits at **65.5 GB free**. Use the measured table above, not the 23 Oct number.

## Prevention

- Keep big downloads off C: — installers/archives → `V:`, recordings → `Z:`.
- Empty Downloads of installers after each driver/app setup.
- Enable **Storage Sense** (Settings → System → Storage) for temp-file cleanup.
- Scoop is not installed, so there is no Scoop cache to clear.
- There are **no sized app-removal candidates** on this clean install.
