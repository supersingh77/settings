# Repository rules

- Keep docs short, actionable, and tied to current behavior. Remove stale guidance instead of preserving it as history; use Git history when old details are needed.
- No comments in code. Shebangs and required machine-readable metadata are allowed. Put user-facing instructions in concise docs.
- Prefer small, composable functions and explicit inputs/outputs. Use functional patterns where they clarify behavior; do not force pure-functional designs onto OS/package-manager side effects.
- Keep scripts idempotent where practical, fail clearly, and avoid hidden global state.
- Add automated checks for behavior that can be tested without modifying the host. Do not run install, cleanup, reboot, or other host-mutating actions as tests.
- Run the smallest relevant checks after changes and report anything unavailable.
- Run `bun install` once, then `bun run check`, `bun test` and `bun run typecheck` after any change under `src/`, `devices/`, `notes/`, `recipes/` or `fixtures/`. Start with `bun run dev describe --json`.
- On the Windows desktop, run those checks plus the read-only live `bun run dev drift`.
- On the Fedora laptop, run live verbs on the host: `flatpak-spawn --host --directory=$PWD $HOME/.bun/bin/bun src/cli/main.ts <verb>`. Host `sudo` needs a password; never run a host-mutating verb from an agent session.
- Phone capture uses the user-level `adb` at `~/.local/lib/platform-tools/adb` on the host; pass `--device phone-personal` or `--device phone-work`.
- The Windows laptop is deferred until it boots again; its old scripts live only in git history. Every reachable device is on `dev`.

## Editing workflow

- Prefer `git diff`/`sed` to inspect the exact target before editing. Apply one small logical change at a time, then immediately inspect `git diff -- <path>` and run its narrow check.
- Use the patch tool for short, stable hunks. For structural rewrites or repeated mechanical changes, use a short script that asserts its expected input before writing; never use broad search/replace without checking the match count.
- Do not mix commands into a patch call or assume a failed call changed nothing: inspect file/status after any tool error.
- Before committing, review the full staged diff and status. Do not commit or alter unrelated pre-existing changes.
- Keep each topic's current facts in one canonical place. Supporting docs should cover procedures, risks, or explanations, not repeat inventories or file maps.
- Prefer read-only inventory scripts over manually maintained volatile facts. Treat program output and configuration as the source of truth; docs may explain interpretation, risks, or where the output lives, but must not mirror changing values or repeat command/file maps.
