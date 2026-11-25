# Fedora Silverblue laptop

Live state is captured by the `dev` tool into [devices/fedora-laptop](../../devices/fedora-laptop/): run `dev capture` and `dev drift` on the host. The [hardware.md](hardware.md) and [software.md](software.md) snapshots here belong to the legacy `laptop` command, which still owns phone, media, shell and maintenance helpers until they are ported.

## Legacy command

`make capture` updates the two snapshots and `make drift` compares them; review the diff before committing. `make setup-dev` and `make audit` still run the Python checks. Tests use fixtures and do not change the host.

## Procedures

- [Silverblue system behaviour](../../notes/silverblue-system.md)
- [UPower and the dead battery](../../notes/upower-battery.md)
- [Connecting a phone](../../notes/phone-connection.md)
- [Audio denoise](../../notes/audio-denoise.md)
- [Phone](../phone/README.md)
