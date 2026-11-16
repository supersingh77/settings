# Laptop scripts — ASUS ROG Strix G513QY

Windows laptop scripts. Not run on the desktop; paths and installed tools differ.

| Script | Purpose | Status |
|---|---|---|
| `cleanup-system.ps1` | Slow maintenance: Scoop cache and old versions, user + system temp, DISM component cleanup, Recycle Bin, DNS cache, Delivery Optimization cache. Each section continues on failure; DISM is skipped when not elevated. Supports `-DryRun`, which reports without deleting. | Active — untested on the laptop since the `-DryRun` switch was added 2026-11-17 |

## Running it

```powershell
pwsh device/laptop/scripts/cleanup-system.ps1 -DryRun   # report only
pwsh device/laptop/scripts/cleanup-system.ps1           # elevated, for the DISM step
```

The `-DryRun` path was exercised on the desktop; the deleting path is unchanged from the version that was last run on the laptop, so treat the first real run after 2026-11-17 as a verification.

See [`../README.md`](../README.md) for the laptop's setup rules and [`../software.md`](../software.md) for its inventory.
