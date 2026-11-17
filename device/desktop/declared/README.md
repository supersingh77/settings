# Declared state — desktop

Some of this machine can be expressed as intent and rebuilt from it. This folder holds that intent: small, hand-curated, reviewable files that describe **what the desktop should look like**, not what it currently looks like.

It is deliberately not a backup. Snapshots live in `device/desktop/backup/` (generated, never hand-edited). The distinction matters: a snapshot can be restored, an intent file can be *argued with*.

## What's here

| File | Describes | Applied by |
|---|---|---|
| `winget-export.json` | 40 installed packages with pinned versions | `winget import -i winget-export.json` |
| `obs.json` | OBS recording/audio settings that were deliberately chosen | manual, or `obs-websocket` (scripted in this repo's history) |
| `associations.json` | which handler each extension should fall back to, and which media types expose one in "Open with" | `pwsh tweaks.ps1` (needs admin), `-DryRun` to preview |
| `audit-targets.json` | what `audit-state.ps1` looks for: absent drive letters, the monitor model, Steam library paths, the not-an-install trap folders, the recordings policy and taskbar name aliases | `pwsh scripts/audit-state.ps1` (read-only) |
| `tweaks.ps1` | the algorithm that walks `associations.json` — contains no lists of its own | `pwsh tweaks.ps1` (needs admin), `-DryRun` to preview |

`tweaks.ps1` exits **1** if any write failed. A refused HKCR write used to print an error and still exit 0, which made a half-applied machine look converged; the summary now reports `change(s)` and `failure(s)` separately.

## Verify against reality

Intent rots the moment nothing checks it — this repo already lost three weeks to docs that said `E:`/`D:` on a machine with only `V:`/`Z:`.

```powershell
pwsh device/desktop/scripts/audit-state.ps1     # what the machine actually is
pwsh device/desktop/declared/tweaks.ps1 -DryRun # what this folder wants it to be
pwsh device/desktop/scripts/check-docs.ps1      # do the docs still say the same thing
pwsh device/desktop/tests/run-tests.ps1         # asserts the dry run reports 0 changes
```

There is still no `-Compare`. The test suite is a one-sided substitute: it fails when this folder and the machine disagree, but it cannot tell you *which* entry differs. Until a real comparison exists, treat these files as a checklist, not as enforcement.

## Deliberately not declared

| Thing | Why not |
|---|---|
| **Secrets** — OBS stream key, tokens, licences | `basic.ini` stores the stream key in plaintext; never copy it into git. `obs.json` carries settings only |
| **`UserChoice` default apps** | Hash-protected by Windows on purpose. Cannot be written by script; must be set through Settings |
| **Windows activation, BIOS, firmware, drivers** | Hardware/account-bound |
| **ReviOS playbook state** | The `.apbx` is password-protected and opaque; its changes are documented in prose, not code |
| **Per-user GUI state** (window positions, recent files) | Noise, changes constantly, no value after a rebuild |

## Scope of reproducibility

Realistically this covers **packages and a handful of registry choices** — call it 60–70% of a rebuild. Everything else lives in `device/desktop/*.md` as instructions, which is what the rest of this repo is for.

## The rules

1. **Hand-curated only.** If a machine can write it, it belongs in a snapshot, not here.
2. **Every entry is a decision.** If nobody chose it, don't declare it.
3. **No secrets, ever.** Redact before writing.
4. **Idempotent scripts.** Running twice must change nothing the second time; `-DryRun` must be safe.
