---
refs: devices/desktop/tasks.json, volume:C:, volume:Z:
---

# Desktop maintenance tasks

> Device: desktop

[`devices/desktop/tasks.json`](../devices/desktop/tasks.json) is the proposed command list standing in for `device/desktop/scripts/update-system.ps1` and `cleanup-system.ps1`. `dev update` and `dev cleanup` are not implemented yet, so nothing executes this file today; it records the argv the verbs should run.

**update** refreshes winget sources and upgrades installed packages. **cleanup** clears user and system temp folders, the component store cache, the Recycle Bin and the Delivery Optimization cache, flushes the DNS cache, and reports recordings still under `Videos` instead of `Z:\Recordings` without deleting them.

## Safe cleanup

- Keep recordings on `Z:\Recordings`. Recordings left in `%USERPROFILE%\Videos` are out of policy: the cleanup task reports them so they can be moved, not deleted.
- Review `%TEMP%`, `C:\Windows\Temp`, Downloads, crash dumps, shader caches, browser caches and Steam shader caches before removing anything.
- Use Disk Cleanup for Windows Update staging and the Windows Installer cache. Do not delete `SoftwareDistribution` while updates are pending, and do not remove the Installer cache by hand.
- Run Disk Cleanup with system files (`cleanmgr /d C:`) rather than deleting component-store folders by hand.
- Remove WSL only when it is unused: `dism /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart`.
- Installer runs recreate files under `C:\AMD`, so inspect it before cleanup.

## Differences from the old scripts

- `winget-upgrade` runs a single `winget upgrade --all`. The old script looped over each available package and printed a per-package success/failure summary; that summary is gone. The old transcript logging to `%LOCALAPPDATA%\DesktopMaintenance\logs` is gone as well. A future `dev` verb should log.
- The old script excluded `Microsoft.PowerShell` because its MSI closes every PowerShell window it runs under and rolls back with 1603. `winget upgrade` has no `--exclude` option (Microsoft's winget upgrade docs, 2026), so the interim list upgrades it too. `powershell-upgrade` is the deliberate manual retry: run it from a Command Prompt window, not from PowerShell, and expect open PowerShell windows to close during the install.
- The old review-only step for installer leftovers (`C:\AMD`, `Downloads`) stays review-only and is not a task. Confirm the matching driver or app works, then delete by hand.
- Admin tasks are not auto-elevated by the tool. Run the host-mutating verbs from an elevated shell; a task with `needs: admin` otherwise fails there.
