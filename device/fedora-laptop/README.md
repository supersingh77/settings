# Fedora Silverblue laptop

The `laptop` command captures live hardware and software state into the tracked
[`hardware.md`](hardware.md) and [`software.md`](software.md) snapshots. It also
reconciles declared software, runs maintenance tasks, and provides device
utilities. Run commands from the repository root with `make` or from this
directory with `PYTHONPATH=. python3 -m laptop`.

## Capture and restore

On the Fedora laptop, run `make drift` to check the snapshots and `make capture`
to update them. Review the resulting diff before committing. `make restore
ARGS=--dry-run` previews software changes needed to match the committed
snapshot; run `make capture` first so the snapshot reflects the intended state.
Restore does not revert hardware or arbitrary `/etc` settings.

## Checks and setup

On Fedora, run `make setup-dev` once and then `make audit`. The audit checks
code, docs, tests, and live device state. Both phones share one model, so the
audit cannot infer a phone's role: set `AUDIT_PHONE=<role>:<serial>` to include a
connected phone. Tests use fixtures and do not change the host. The inventory is specific to this laptop and must not be used as a
Windows check.

## Procedures

- [Workflows](docs/workflows.md) — phone connection and audio denoising
- [Troubleshooting](troubleshooting.md) — recovery guidance
- [Lessons learned](lessons.md) — durable Silverblue-specific lessons
- [Phone](../phone/README.md) — shared phone procedures
