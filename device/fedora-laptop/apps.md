# Fedora Laptop Apps

Application sources are declared by the setup scripts:

- `scripts/setup-host.sh`: rpm-ostree layer packages.
- `scripts/setup-user.sh`: Toolbox packages and OpenWork setup.
- `scripts/update-system.sh`: Flatpak, Toolbox, and user-app updates.

For a live inventory:

```bash
flatpak list --app --columns=application,name
rpm-ostree status
toolbox list
```
