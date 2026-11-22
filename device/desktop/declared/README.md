# Declared state — desktop

Some of this machine can be expressed as intent and rebuilt from it. This folder holds that intent: small, hand-curated, reviewable files that describe **what the desktop should look like**, not what it currently looks like.

It is deliberately not a backup. Snapshots — `.reg` exports of `FileExts` and friends — live in `%LOCALAPPDATA%\DesktopMaintenance`, outside the repo, generated and never hand-edited. They stay out of git on purpose: a registry export is machine state that goes stale and carries personal paths. The distinction matters: a snapshot can be restored, an intent file can be *argued with*.

## What's here

| File | Describes | Applied by |
|---|---|---|
| `winget-export.json` | Selected packages and requested versions | `winget import -i winget-export.json` |
| `obs.json` | OBS recording/audio settings that were deliberately chosen | manual, or `obs-websocket` (scripted in this repo's history) |
| `associations.json` | which handler each extension should fall back to, and which media types expose one in "Open with" | `pwsh tweaks.ps1` (needs admin), `-DryRun` to preview |
| `audit-targets.json` | Paths and labels used by the live audit | `pwsh scripts/audit-state.ps1` (read-only) |
| `tweaks.ps1` | the algorithm that walks `associations.json` — contains no lists of its own | `pwsh tweaks.ps1` (needs admin), `-DryRun` to preview |

`tweaks.ps1` exits **1** if any write fails and reports proposed changes separately from failures.

## Compare intent and inventory

`tweaks.ps1 -DryRun` shows how declared registry intent differs from the desktop. A difference is a reviewable proposal; it does not mean the machine should be changed automatically.

```powershell
pwsh device/desktop/declared/tweaks.ps1 -DryRun
pwsh device/desktop/scripts/update-inventory.ps1 -DryRun
pwsh device/desktop/scripts/check-docs.ps1
```

`update-inventory.ps1 -Apply` refreshes generated sections in `hardware.md`, `software.md`, and `startmenu-taskbar.md`. Review `git diff` and keep or revert the documentation changes.

## Deliberately not declared

| Thing | Why not |
|---|---|
| **Secrets** — OBS stream key, tokens, licences | `basic.ini` stores the stream key in plaintext; never copy it into git. `obs.json` carries settings only |
| **`UserChoice` default apps** | Hash-protected by Windows on purpose. Cannot be written by script; must be set through Settings |
| **Windows activation, BIOS, firmware, drivers** | Hardware/account-bound |
| **ReviOS playbook state** | The `.apbx` is password-protected and opaque; its changes are documented in prose, not code |
| **Per-user GUI state** (window positions, recent files) | Noise, changes constantly, no value after a rebuild |

## Scope

Declared files hold deliberate rebuild intent. Live hardware and software readings are generated in the device inventory docs; those observations are not settings to apply.

## The rules

1. **Intent only.** Use this folder for choices the owner wants applied, not observations from the current machine.
2. **Every entry is a decision.** If nobody chose it, don't declare it.
3. **No secrets, ever.** Redact before writing.
4. **Idempotent scripts.** Running twice must change nothing the second time; `-DryRun` must be safe.
