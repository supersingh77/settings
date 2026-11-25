# Personal configuration repository

One Bun/TypeScript tool, `dev`, tracks configuration and state for these machines:

- `data/devices/` — per-device state (`state/*.jsonl`), device config and task lists
- `data/recipes/` — how to install things no package manager handles
- `notes/` — the knowledge code cannot derive
- `data/fixtures/` — recorded command output and parsed golden files

## Workflow

- `bun run dev drift` compares the live machine with the store and writes nothing.
- `bun run dev capture` records live state; review the diff and commit it.
- `bun run dev restore` plans changes that make the machine match the store; preview with `--dry-run`.
- `bun run dev update` and `cleanup` run the device's `tasks.json`.
- `bun run dev media` extracts, remuxes, joins, denoises, lists mics and measures audio levels; `shell` and `uad` cover the small utilities.
- `bun run dev check` runs schema, lint, fixture and note-reference checks.

Run `bun install` once, then `bun run dev describe --json` for the contract. Machine knowledge lives in `notes/`; the Windows laptop is deferred until it boots again.
