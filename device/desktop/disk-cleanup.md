# Desktop storage cleanup

The live drive readings are generated in [`hardware.md`](hardware.md). Run [`audit-state.ps1`](scripts/audit-state.ps1) before deciding where space went.

## Recurring checks

- Keep recordings on `Z:\Recordings`. The live audit reports recordings left under `Videos` and checks OBS profile paths.
- Review `%TEMP%`, `C:\Windows\Temp`, Downloads, crash dumps, shader caches, browser caches, and Steam shader caches before removing files.
- Use Disk Cleanup for Windows Update staging and the Windows Installer cache. Do not delete `SoftwareDistribution` while updates are pending or remove the Installer cache manually.
- Inspect `C:\AMD` before cleanup; installer runs can recreate files there.

## System cleanup

- Component store: `Dism.exe /Online /Cleanup-Image /StartComponentCleanup`
- Disk Cleanup with system files: `cleanmgr /d C:`
- Remove WSL only when it is unused: `dism /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart`

Run [`cleanup-system.ps1`](scripts/cleanup-system.ps1) with `-DryRun` before using its cleanup actions.
