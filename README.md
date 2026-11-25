# Personal configuration repository

This repository tracks configuration, maintenance tools, and reference notes for the owner's devices. The Bun/TypeScript [`dev`](src/cli/main.ts) tool and the captured state under [`devices/`](devices/) are the current workflow; remaining per-device scripts and guides live under [`device/`](device/).

## Source of truth

- `bun run dev drift` compares the running device with captured state and reports differences without writing anything.
- `bun run dev capture` records observed state and `bun run dev restore` plans host changes; review the plan before applying it.
- Scripts define behavior; machine-readable files hold declared configuration where practical.
- Keep explanations, recovery steps, and decisions in [`notes/`](notes/). Do not copy volatile inventories or repeat command/file maps.

## Working in the repository

Read [`AGENTS.md`](AGENTS.md) before making changes. Run `bun install` once, then `bun run check`, `bun test` and `bun run typecheck`. Checks inspect state or temporary fixtures; they must not install packages, clean the host, or reboot it.

The Fedora laptop's inventory workflow is documented in [`device/fedora-laptop/README.md`](device/fedora-laptop/README.md). Desktop knowledge is in [`notes/`](notes/).
