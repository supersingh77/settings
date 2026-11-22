# Fedora Laptop Recovery

For freezes or unexpected power-offs, collect evidence from the previous boot before running `cleanup`:

```bash
journalctl --list-boots
journalctl -b -1 -k --no-pager
journalctl -b -1 -p warning..alert --no-pager
```

On this laptop, check the battery/UPower config and the active deployment before changing anything:

```bash
rpm-ostree status
findmnt /etc
grep -E '^(NoPollBatteries|IgnoreLid|UsePercentageForPolicy|CriticalPowerAction|AllowRiskyCriticalPowerAction)=' /etc/UPower/UPower.conf
journalctl -b -u upower --no-pager
```

The built-in battery is documented as dead. Silverblue deployments have separate `/etc` trees; validate a fix after booting an updated deployment. See [`hardware.md`](hardware.md) for the hardware caveat and [`lessons.md`](lessons.md) for the investigation details.

For host updates, `rpm-ostree status` distinguishes the booted deployment from a staged one. Reboot to activate staged host changes; Flatpak and user-installed app updates take effect separately.

To repair OpenWork after an update issue, remove the app directory, wrapper, and version file, then run `update-openwork`:

```bash
rm -rf ~/.local/lib/openwork ~/.local/bin/openwork ~/.local/bin/openwork.version
update-openwork
```

For non-boot issues, use the app's own repair/update command or inspect its journal before applying a broad cleanup. Avoid editing immutable-root mounts or masking core OSTree/systemd units without checking Fedora's supported guidance.
