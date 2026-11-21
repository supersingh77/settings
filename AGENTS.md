# Repository rules

- Keep docs short, actionable, and tied to current behavior. Remove stale guidance instead of preserving it as history; use Git history when old details are needed.
- No comments in code. Shebangs and required machine-readable metadata are allowed. Put user-facing instructions in concise docs.
- Prefer small, composable functions and explicit inputs/outputs. Use functional patterns where they clarify behavior; do not force pure-functional designs onto OS/package-manager side effects.
- Keep scripts idempotent where practical, fail clearly, and avoid hidden global state.
- Add automated checks for behavior that can be tested without modifying the host. Do not run install, cleanup, reboot, or other host-mutating actions as tests.
- Run the smallest relevant lint/test checks after changes and report anything unavailable.
- Run `make audit` for reproducible lint, tests, changed-code comment checks, and repository-wide Markdown checks. Run `make setup-dev` once to create the local Python tool environment.

## Editing workflow

- Prefer `git diff`/`sed` to inspect the exact target before editing. Apply one small logical change at a time, then immediately inspect `git diff -- <path>` and run its narrow check.
- Use the patch tool for short, stable hunks. For structural rewrites or repeated mechanical changes, use a short script that asserts its expected input before writing; never use broad search/replace without checking the match count.
- Do not mix commands into a patch call or assume a failed call changed nothing: inspect file/status after any tool error.
- Before committing, review the full staged diff and status. Do not commit or alter unrelated pre-existing changes.
- Keep each topic's current facts in one canonical place. Supporting docs should cover procedures, risks, or explanations—not repeat inventories or file maps. For device pairs, put shared facts in the parent README and only differences in per-device notes.
