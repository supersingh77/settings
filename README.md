# Personal configuration repository

This repository tracks configuration, inventories, maintenance tools, and reference notes for the owner's devices. Each device owns its scripts, declared state, checks, and device-specific documentation under [`device/`](device/).

## Source of truth

- Scripts define behavior; machine-readable files hold declared configuration where practical.
- Inventory scripts inspect the running device and report drift. Generated sections in device documentation are updated from those readings and reviewed through `git diff`.
- Keep explanations, recovery steps, and decisions in concise documentation. Avoid copying volatile inventories or repeating procedures across files.
- Use [`notes/`](notes/) for cross-device reference material.

## Working in the repository

Read [`AGENTS.md`](AGENTS.md) before making changes. Run the relevant device checks from that device's documentation. Checks should inspect or use temporary fixtures; they must not install packages, clean the host, or reboot it.

The Fedora laptop's inventory workflow is documented in [`device/fedora-laptop/README.md`](device/fedora-laptop/README.md). The Windows desktop's inventory and maintenance workflow is documented in [`device/desktop/README.md`](device/desktop/README.md).
