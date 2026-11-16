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

**Association state:**

| Extension | State | Resolves to |
|---|---|---|
| `.md` | no `UserChoice`; `HKCR\.md` → `Markdown` (Obsidian) | GenOffice (via the `Markdown Document` OpenWithProgid) |
| `.txt` | `UserChoice` → `AppX4ztfk…` (AppX Notepad), hash present | `Notepad.exe` (packaged) |
| `.mp4` / `.m4a` | `UserChoiceLatest` with a `Hash` but **no `ProgId`** | `OpenWith.exe` — i.e. "no default" → the broken picker |

- `UserChoice` keys are ACL-protected; deleting them fails without elevation.
- `HKCR\txtfile` (the standard Text File class) is missing.
- `HKLM\…\Policies\Explorer\NoInternetOpenWith = 1`; a stray `NoOpenWith` value sits on `HKCR\Applications\OpenWith.exe`.
- UCPD (User Choice Protection Driver) is disabled.
- No shell-hooking tools installed (no StartAllBack / ExplorerPatcher / Open-Shell).

## Root cause

The image mixes **26100-era shell binaries and packages with a 26300 OS build**. The modern Explorer UI (tabs) and the app picker both come from that shell stack, so they fail or fall back to the cut-down behaviour. The association store is a second, smaller problem: hash-only `UserChoiceLatest` entries make Windows treat video types as having no default and hand them to the broken picker.

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

- Notepad++ 8.9.9.1 was installed during troubleshooting and is **still installed**; removal needs elevation (MSI uninstall returned 1603 without it).
- A `.reg` snapshot of `HKCU\…\FileExts` lives in `%LOCALAPPDATA%\DesktopMaintenance`; `reg import` refuses the protected keys, so it is a reference only.
- `.md` and `.txt` were restored to their original handling; `.mp4` / `.m4a` remain unresolved exactly as before.
