# STYLE.md — how code in this repo is written

> Read this before writing or editing a script. It exists because this repo is read by agents as much as by its owner.

## The premise

Prose inside code is ambiguous. A comment describing a workaround looks identical to a comment describing intent, and a future reader — human or agent — cannot tell which it is. Worse, a stale comment reads as a requirement.

This repo already carries knowledge that took hours to establish (`OBS silently ignores h264_texture_amf`; `the Barracuda mic auto-sleeps and records nothing`). That knowledge must survive. It must not live in a `#` line.

**So: code carries no explanations, and no fact exists only in a comment.**

## Rules

1. **No comments in code.** `#` is only allowed for `#Requires` directives. If a line needs explaining, the line is wrong: rename it, split it, or move the explanation to Rule 2.
2. **Facts live in one place, and it is not code.**
   - *What should be true* → `device/*/declared/*.json`, using `_why` / `_note` keys.
   - *Why it is this way* → `device/*.md` or `notes/*.md`.
   - A fact repeated in two files is a bug; the copies will disagree.
3. **Functions are pure by default.** Input through parameters, output through the return value. No `$global:`, no hidden state, no `Write-Host` inside functions that compute.
4. **Side effects live at the edges.** One thin section — the `main` block at the bottom — performs every write, every external process call, every filesystem change.
5. **Data is not code.** Enumerations (which extensions, which packages, which paths) are JSON. A script contains the algorithm that walks the data, never the list itself.
6. **Anything that writes supports `-DryRun`**, and a dry run must be safe to run at any time, including when the machine already matches.
7. **Anything that writes is idempotent.** Second run changes nothing. `0 changes` is the success message.
8. **Exit codes are explicit.** Non-zero on failure, so a caller (or an agent) can tell without parsing text.
9. **Prefer boring.** An explicit `foreach` that reads top to bottom beats a clever pipeline that must be simulated.
10. **Names carry the meaning.** `Get-BrokenAssociation` not `$d` — this is how Rule 1 stays affordable.

## Layout

```
device/<device>/declared/     intent: data + a thin apply script
device/<device>/lib/          pure functions: no registry, no files, no processes
device/<device>/scripts/      operations: audit, maintenance, one-off tools
device/<device>/tests/        invariants that call lib/ and the scripts' exit codes
notes/                        prose: why, trade-offs, dead ends
```

Code and data are separated by directory, not by convention. A script that hardcodes a list is in the wrong shape.

## Tests are invariants, not unit tests

For scripts this size, the valuable checks are properties:

| Invariant | Why it earns its place | Enforced by |
|---|---|---|
| every script parses | catches syntax-only breakage before it runs | `verify.ps1` |
| no comments outside `#Requires` | Rule 1, enforced mechanically instead of by discipline | `verify.ps1` |
| no global state | Rule 3; a hidden variable is a second code path | `verify.ps1` |
| every writer exposes `-DryRun` | proves Rule 6 | `verify.ps1` |
| every writer sets an explicit exit code | Rule 8; a silent 0 on failure is worse than a crash | `verify.ps1` |
| every JSON in `declared/` is valid | those files are the source of truth; a typo silently disables a rule | `verify.ps1` |
| every JSON in `declared/` is named by a script or a doc | dead intent is indistinguishable from intent | `verify.ps1` |
| every script is listed in its folder's README | keeps the index honest as code is added | `verify.ps1` |
| `-DryRun` mutates nothing | proves Rule 6 for the scripts that touch the machine | `run-tests.ps1` |
| a converged machine reports 0 changes | proves Rule 7 — this is the check that would have caught the `Get-ChildItem` vs `GetValueNames` mistake | `run-tests.ps1` |
| a parser returns the rows it is given | the winget table is fixed-width text, and a format change looks exactly like "nothing to upgrade" | `run-tests.ps1` |

Two commands, both hard-failing, both runnable from any shell:

```powershell
pwsh device/desktop/scripts/verify.ps1      # repo shape: 16 scripts, 3 declared JSON files
pwsh device/desktop/tests/run-tests.ps1     # behaviour: 17 assertions
```

`verify.ps1`'s own rule list lives in code — the single exception to Rule 5, because the rules *are* the verifier's identity rather than data about the machine.

## Tooling reality on this machine

- `PSScriptAnalyzer` — **not installed**, and PSGallery is unreachable. Re-checked 2026-11-17: the TCP connection to `www.powershellgallery.com:443` opens and the TLS handshake then fails, with and without certificate validation. `Get-PSRepository` returns nothing. Treat any "just install the analyzer" plan as blocked, not as a step.
- `Pester` — only **3.4.0**, the version shipped in `C:\Program Files\WindowsPowerShell\Modules`. Its syntax predates Pester 5 and it buys nothing over the 40 lines of assertions in `tests/run-tests.ps1`.

Therefore: **write the checks with zero external dependencies.** PowerShell can parse itself (`[System.Management.Automation.Language.Parser]`), read JSON (`ConvertFrom-Json`), and assert. A 150-line verifier beats a dependency that cannot be installed — and it is why `verify.ps1` is the lint layer, not a wrapper around one.

## When to break these rules

Never silently. If a comment is genuinely unavoidable — a vendor bug that cannot be named in data, say — it goes in the relevant `.md` with a date, and the code gets no comment. The absence of an explanation in the code is the signal to go looking for the one in prose.
