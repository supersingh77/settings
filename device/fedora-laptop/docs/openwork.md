# OpenWork

OpenWork is distributed as a Linux AppImage. On Silverblue the updater extracts it under `~/.local/lib/openwork` and provides a wrapper, avoiding a host FUSE dependency.

## Normal use

- Launch with `openwork` or from GNOME Activities.
- Run `update-openwork` for only this app; `update` includes it.
- Installed version is recorded in `~/.local/bin/openwork.version`.

## Recovery

Check that the version file and extracted app directory exist before reinstalling. To rebuild the install, remove only the OpenWork app directory, wrapper, and version file, then run `update-openwork`:

```bash
rm -rf ~/.local/lib/openwork ~/.local/bin/openwork ~/.local/bin/openwork.version
update-openwork
```

User settings and extensions are stored separately under `~/.config/openwork` and `~/.opencode`; this procedure leaves them intact.
