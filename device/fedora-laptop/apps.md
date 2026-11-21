# Fedora Laptop Apps

Applications are intentionally split by use, not because Toolbox is a temporary workaround:

- GUI applications use system Flatpak.
- Host-specific integrations use rpm-ostree layers (`distrobox`, Ghostty, `uhubctl`).
- CLI/development utilities (`adb`/`fastboot`, FFmpeg, 7-Zip, `gh`) stay in `fedora-toolbox-44`.
- `scripts/setup-host.sh` and `scripts/setup-user.sh` declare the host and Toolbox package sets.
- `scripts/update-system.sh` updates Flatpak, Toolbox, and user-installed apps.

For a live inventory:

```bash
flatpak list --app --columns=application,name
rpm-ostree status
toolbox list
```
