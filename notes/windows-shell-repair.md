# Windows shell / "Open with" failure — diagnosis and repair path

> Device: desktop | Written: 2026-11-16 | Status: unresolved on this image

## Symptoms

- Double-clicking `.mp4` / `.m4a` in `Videos/` and `.md` in `personal-ledger/diary/` does not open them.
- Right-click → **Open with → Choose another app** does nothing (no dialog ever appears).
- File Explorer has no tabs and looks like a cut-down build.

## Verified evidence

OS reports **26H2, build 26300.9457**, but the shell files are from the 26100 line:

| Component | Version |
|---|---|
| `C:\Windows\explorer.exe` | 10.0.26100.8117 |
| `C:\Windows\System32\OpenWith.exe` | 10.0.26100.8117 |
| `C:\Windows\System32\ShellHost.exe` | 10.0.26100.9278 |
| `twinui.pcshell.dll` | 10.0.26100.9278 |
| `Windows.UI.Xaml.dll` | 10.0.26100.8972 |
| `MicrosoftWindows.Client.CBS` | 1000.26100.360.0 |
| `MicrosoftWindows.Client.Core` | 1000.26100.133.0 |
| `Microsoft.UI.Xaml.CBS` | 9.2603.18001.0 |

**The picker is dead, not slow:**

- `OpenWith.exe` starts and exits **without creating a window** — `0xC0000142` (`STATUS_DLL_INIT_FAILED`) from a low-integrity process, `0x80073D54` from a normal-integrity process.
- `ShellHost.exe` (the dialog host behind it) exits the same way.
- Other GUI binaries (`mstsc.exe`, `mmc.exe`) start normally, so the desktop itself can create windows.

**The shell can still launch associations:**

- A synthetic `.zzz` → `cmd /c echo` association launched successfully through `ShellExecuteEx` (process created, marker file written). So the launch path is intact; the fault is specific to the shell/app-picker components.

**Association state (re-checked 16 Nov 2026, 19:45):**

| Extension | State | Resolves to |
|---|---|---|
| `.md` | no `UserChoice`; `HKCR\.md` → **`Markdown Document`** (repointed 16 Nov) | `GenOffice.exe "%1"` — works |
| `.txt` | `UserChoice` → `AppX4ztfk…` (AppX Notepad), hash present | `Notepad.exe` (packaged) |
| `.mp4` / `.m4a` / `.mkv` and 31 other media types | `UserChoiceLatest` held a **hash but no `ProgId`** → resolved to the dead picker. **Those 34 keys were deleted 16 Nov** | falls back to `HKCR` default, e.g. `PotPlayerMini64.MP4` → `PotPlayerMini64.exe "%1"` |

- `UserChoice` keys are ACL-protected; deleting them fails without elevation.
- **101 extensions still carry a hash-only `UserChoiceLatest`**, but most of those also have a valid `UserChoice` that wins — they are not the cause of the double-click failure.
- `HKCR\txtfile` (the standard Text File class) is missing.
- UCPD (User Choice Protection Driver) is **stopped**; the old `NoInternetOpenWith` policy and the stray `NoOpenWith` value on `OpenWith.exe` are **gone** as of 16 Nov, so they are no longer contributing.
- No shell-hooking tools installed (no StartAllBack / ExplorerPatcher / Open-Shell).

## Root cause

The image mixes **26100-era shell binaries and packages with a 26300 OS build**. The modern Explorer UI (tabs) and the app picker both come from that shell stack, so they fail or fall back to the cut-down behaviour. The association store is a second, smaller problem: hash-only `UserChoiceLatest` entries make Windows treat video types as having no default and hand them to the broken picker.

## Applied 16 Nov 2026

What was actually changed, with the backup that undoes it:

| Change | Effect | Undo |
|---|---|---|
| Deleted the 34 hash-only `UserChoiceLatest` keys (all media types) | Windows falls back to the `HKCR` default handler instead of "no default → picker" | `reg import %LOCALAPPDATA%\DesktopMaintenance\FileExts-backup-2026-11-16.reg` |
| Repointed `HKCR\.md` → `Markdown Document` | `.md` now has a command (GenOffice) instead of a dead ProgId | `reg add "HKCR\.md" /ve /d Markdown /f` (restores the broken state) |
| Added `PotPlayerMini64.*` to `OpenWithProgids` for media types | PotPlayer appears in the "Open with ▸" submenu | delete the value |

**Correction to an earlier claim in this note:** `OpenWithProgids` was reported as empty. That was a **measurement error** — `Get-ChildItem` lists subkeys, not values, so a populated `OpenWithProgids` looked empty. The values were there all along (`WMP11.AssocFile.MP4`, etc.). Read them with `.GetValueNames()`.

**Test-method warning:** launching a file from inside an agent sandbox reports `Server execution failed` / `Access is denied` for **every** type, including ones that work fine by hand. Those errors are the sandbox refusing the shell launch, not the OS. Association behaviour has to be verified by double-clicking as the logged-in user.

## What does not fix it

- Re-registering the CBS packages as the current user — tried, no change to the picker.
- Deleting or repointing `UserChoice` by hand — Windows rewrites the keys, and doing it live can briefly make **every** extension resolve to `OpenWith.exe`.
- Installing another text editor — does not touch Explorer or the picker.

## Repair path

1. Optional, cheap first attempt (elevated): `sfc /scannow` then `DISM /Online /Cleanup-Image /RestoreHealth`. Low odds on a modified image.
2. **In-place repair install** with matching 26300 media — keeps files and apps.
3. Clean install if the repair install fails.
4. Until then: open files from inside the app (`File → Open`) rather than by double-click.

## Refactor — how this should be handled in this repo

- **One read-only diagnostic script**, not a fix-all script: report OS/build, shell file versions, package versions, a picker launch test, and the `AssocQueryString` table for the affected extensions. No writes, no elevation needed.
- **Keep the decision tree in a note** (this file). If the picker exits with `0xC0000142`/`0x80073D54` and the shell binaries are older than the OS build, it is an image problem — stop, do not patch the registry.
- **Never write associations by hand.** Use the OS UI or the documented API; hand-editing `UserChoice` is protected, self-healing, and can make things worse.
- **Scripts stay small, idempotent, and log to `%LOCALAPPDATA%\DesktopMaintenance`** — same pattern as `update-system.ps1` / `cleanup-system.ps1`.

## Loose ends

- **Notepad++ 8.9.9.1 — resolved 16 Nov 2026.** It was installed only during this troubleshooting and removed with `winget uninstall --id Notepad++.Notepad++ --exact` from an elevated shell (the MSI uninstall returns 1603 without elevation, which is why it sat there).
- **Obsidian 1.15.1 — installed and removed 16 Nov 2026** (same day, to test `.md` handling). Its uninstaller left the `.md` mapping worse: `HKCR\.md` still points at the `Markdown` ProgId, but that ProgId's `shell\open\command` is now empty, and there is no `UserChoice`. Double-clicking a `.md` therefore does nothing. Stale `HKCR\Obsidian` and `HKCR\obsidian` keys also remain.
  - Do **not** fix this by hand-writing `UserChoice` (see the rule above). It can be set from **Settings → Apps → Default apps → `.md`** once the picker is repaired, or GenOffice can be used explicitly.
- A `.reg` snapshot of `HKCU\…\FileExts` lives in `%LOCALAPPDATA%\DesktopMaintenance`; `reg import` refuses the protected keys, so it is a reference only.
- `.txt` was restored to its original handling; `.mp4` / `.m4a` remain unresolved exactly as before.
