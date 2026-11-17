# Desktop Layout — Files, Folders & Shortcuts

> Device: Desktop PC | Updated: 17 Nov 2026
> Scope: the actual `C:\Users\amar\Desktop` folder. For taskbar/Start pins see [startmenu-taskbar.md](startmenu-taskbar.md).

## Current Contents

| Type | Items |
|------|-------|
| **Folders** | `accounts/` — finance/ID material, 85.7 MB (contents not enumerated) · `statements/` — bank/credit statements, 32.7 MB (contents not enumerated) · `personal-ledger/` — 2.6 MB, ledger app data + `diary/` · `settings/` — this repo (1.0 MB, re-measured 17 Nov) · `obsidian/` — see note below |
| **Shortcuts** | `Roblox Player.lnk` → `%LOCALAPPDATA%\Roblox\Versions\version-5a21b87bbc2641cf\RobloxPlayerBeta.exe` · `Roblox Studio.lnk` → `…\Roblox\Versions\RobloxStudioInstaller.exe` |
| **Files** | No user files at the desktop root; `desktop.ini` is hidden/system |

**Public desktop** (`C:\Users\Public\Desktop`) holds `Revision Tool.lnk` (ReviOS panel) — it shows on every user's desktop and is not duplicated here.

## The `obsidian/` folder

Created 16 Nov 2026 17:25 when Obsidian was launched to try it: it contains a default vault (`obsidian\Obsidian\` with `Welcome.md` and a `.obsidian\` config). Obsidian itself was uninstalled the same day. The folder is ~0 MB of default content — **candidate for deletion**; a second, empty `C:\Users\amar\Documents\Obsidian Vault` also exists.

Left in place deliberately: it is user data, not an install artifact.

## Conventions

- An app lives in exactly **one** place: taskbar for daily drivers, Start for everything else, desktop only for one-click shortcuts and active folders.
- Finance documents stay in `accounts/` and `statements/`; do not create a catch-all `Personal/` folder again.
- The desktop root should not hold installers, archives, or generated reports. Use Downloads, `V:`, or `Z:` instead.

## History

- **16 Nov 2026:** Obsidian installed, tried, and uninstalled (its taskbar pin and public-desktop shortcut vanished with it); Roblox shortcuts are now the only desktop shortcuts; `personal-ledger/` and `obsidian/` appeared.
- **23 Oct 2026 — 26H2 clean install:** desktop reset to `accounts/`, `statements/`, `settings/`, plus the three shortcuts of that era. Older shortcuts and folders were removed with the old install.
- Prior shortcut/finance-folder changes are preserved in Git history.
