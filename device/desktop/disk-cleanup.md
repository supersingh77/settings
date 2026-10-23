# C: Drive — Cleanup Reference

> Updated: 23 Oct 2026 | Current map: C: **52.2 GB free** / E: 137.6 GB / D: 488.4 GB
> Evergreen checklist for the Windows desktop. Verify sizes before deleting anything.

## Drive Map

| Drive | Size | Free | Purpose |
|-------|------|------|---------|
| **C:** | 126.1 GB | **52.2 GB** | OS + core apps |
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

## Measured Opportunities (23 Oct 2026)

| Target | Size | Notes |
|--------|------|-------|
| `C:\AMD` | **3.0 GB** | Extracted AMD chipset/GPU installers. Safe after Device Manager is clean and no AMD installer is running; keep if you want offline reinstall files. |
| `C:\Users\amar\Downloads\drivers-26h2` | **1.81 GB** | AMD, Realtek, MSI, PXN installers. Keep the PXN setup until the wheel is fully configured; the rest can go after validation. |
| `C:\Windows\SoftwareDistribution\Download` | **2.42 GB** | Use Disk Cleanup / DISM, not manual deletion. |
| `%LOCALAPPDATA%\Temp` | **0.26 GB** | Safe to clear; some files may be in use. |
| `C:\Windows.old` | **0.03 GB** | Remove via Disk Cleanup if present. |

## Prevention

- Keep big downloads off C: — installers/archives → E:, recordings → D:.
- Empty Downloads of installers after each driver/app setup.
- Enable **Storage Sense** (Settings → System → Storage) for temp-file cleanup.
- Scoop is not installed, so there is no Scoop cache to clear.
- There are **no sized app-removal candidates** on this clean install.
