# Personal configuration repository

One Bun/TypeScript tool, `dev`, tracks configuration and state for these machines. Four folders hold everything:

- `src/` — the CLI; `bun run dev describe --json` is the contract
- `data/devices/` — per-device state (`state/*.jsonl`), device config and task lists
- `data/recipes/` — how to install things no package manager handles
- `data/fixtures/` — recorded command output and parsed golden files
- `notes/` — the knowledge code cannot derive
- `mail/inbox/`, `mail/outbox/` — agent drop folders (contents local and gitignored)

## Workflow

- `bun run dev drift` compares the live machine with the store and writes nothing.
- `bun run dev capture` records live state; review the diff and commit it.
- `bun run dev restore` plans changes that make the machine match the store; preview with `--dry-run`.
- `bun run dev update` and `cleanup` run the device's `tasks.json`.
- `bun run dev media` extracts, remuxes, joins, denoises, lists mics and measures audio levels; `shell` and `uad` cover the small utilities.
- `bun run dev check` runs schema, lint, fixture and note-reference checks.
- `bun run dev devices|state|recipes|notes|fixtures` read the store as JSON. The browser console (`bun run build`, then `bun run web`, at `http://127.0.0.1:4173`; `bun run web:dev` for hot reload) only calls these verbs through `POST /api/run`, and runs host-changing verbs only with `--dry-run`. Add a verb before adding a web feature.
- `bun run dev outbox source [name]` exports the tracked source at `HEAD` as a zip into `mail/outbox/`.

Run `bun install` once, then `bun run dev describe --json` for the contract. Machine knowledge lives in `notes/`; the Windows laptop is deferred until it boots again.
