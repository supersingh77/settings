# C: Drive — Cleanup Reference

> Updated: 23 Oct 2026 | Current map: C: **98.8 GB free** / E: 137.6 GB / D: 488.4 GB
> Evergreen checklist for the Windows desktop. Verify sizes before deleting anything.

## Drive Map

| Drive | Size | Free | Purpose |
|-------|------|------|---------|
| **C:** | 126.1 GB | **98.8 GB** | OS + core apps |
| **E:** | 350 GB | 137.6 GB | Games, streaming software |
| **D:** | 931.5 GB | 488.4 GB | Recordings, VODs, archives |

## Safe Recurring Cleanup

| What | Where / How |
|------|-------------|
| User + Windows temp | `%TEMP%`, `C:\Windows\Temp` |
| Recycle Bin | `Clear-RecycleBin` or Disk Cleanup |
| Windows Update staging | Disk Cleanup → "Windows Update Cleanup"; don't delete `SoftwareDistribution` manually while updates are pending |
| Old installers | `C:\Users\amar\Downloads` — keep only what you still need |
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
| `C:\AMD` | 3.0 GB | Removed |
| `C:\Users\amar\Downloads\drivers-26h2` | 1.81 GB | Removed |
| `C:\Windows.old` | **38.0 GB** | Removed — old `puruhn` profile with Scoop reparse points |
| `C:\Windows\SoftwareDistribution\Download` | 2.42 GB | Cleared |
| `%LOCALAPPDATA%\Temp` | 0.27 GB | Cleared (2 in-use files remain, 0.7 MB) |

**Result:** C: went from **52.2 GB → 98.8 GB free** (46.6 GB reclaimed). No outstanding measured targets remain.

## Prevention

- Keep big downloads off C: — installers/archives → E:, recordings → D:.
- Empty Downloads of installers after each driver/app setup.
- Enable **Storage Sense** (Settings → System → Storage) for temp-file cleanup.
- Scoop is not installed, so there is no Scoop cache to clear.
- There are **no sized app-removal candidates** on this clean install.
