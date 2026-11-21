# Repository rules

- Keep docs short, actionable, and tied to current behavior. Remove stale guidance instead of preserving it as history; use Git history when old details are needed.
- No comments in code. Shebangs and required machine-readable metadata are allowed. Put user-facing instructions in concise docs.
- Prefer small, composable functions and explicit inputs/outputs. Use functional patterns where they clarify behavior; do not force pure-functional designs onto OS/package-manager side effects.
- Keep scripts idempotent where practical, fail clearly, and avoid hidden global state.
- Add automated checks for behavior that can be tested without modifying the host. Do not run install, cleanup, reboot, or other host-mutating actions as tests.
- Run the smallest relevant lint/test checks after changes and report anything unavailable.
- Run `python3 scripts/audit.py` to check Fedora script lint/tests, newly added code comments, dated status claims, and Fedora Markdown links. Existing cleanup debt is reported as informational output until migrated.
