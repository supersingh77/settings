from . import apps, parse
from .model import Hardware, ProbeError, Software

DMI = "sys/class/dmi/id"
GIB = 2**30
MICRO = 1_000_000


def read(root, relative, required=False):
    path = root / relative
    if path.is_file():
        try:
            return path.read_text().strip()
        except OSError as err:
            if required:
                raise ProbeError(f"unreadable {path}") from err
            return ""
    if required:
        raise ProbeError(f"missing {path}")
    return ""


def execute(run, argv):
    result = run(argv)
    if result.code != 0:
        reason = (result.err.strip().splitlines() or ["no output"])[0]
        raise ProbeError(f"{' '.join(argv)} failed: {reason}")
    return result.out


def board(root, expected):
    name = read(root, f"{DMI}/board_name", True)
    if name != expected:
        raise ProbeError(f"board is {name!r}, expected {expected!r}: wrong machine")
    return f"{read(root, f'{DMI}/board_vendor', True)} {name}"


def firmware(root):
    vendor = read(root, f"{DMI}/bios_vendor", True)
    version = read(root, f"{DMI}/bios_version", True)
    date = read(root, f"{DMI}/bios_date", True)
    return f"{vendor} {version} ({date})"


def zram(root):
    sizes = []
    for path in sorted((root / "sys/block").glob("zram*/disksize")):
        sizes.append(f"{path.parent.name} {int(path.read_text()) / GIB:g} GiB")
    return ", ".join(sizes) or "none"


def battery(root):
    found = []
    for path in sorted((root / "sys/class/power_supply").glob("*")):
        if read(root, f"sys/class/power_supply/{path.name}/type") == "Battery":
            design = read(
                root, f"sys/class/power_supply/{path.name}/energy_full_design"
            )
            full = read(root, f"sys/class/power_supply/{path.name}/energy_full")
            if design and full:
                try:
                    found.append(
                        f"{path.name} {int(design) / MICRO:.1f} Wh design, "
                        f"{int(full) / MICRO:.1f} Wh full"
                    )
                except ValueError:
                    found.append(f"{path.name} capacity unreported")
            else:
                found.append(f"{path.name} capacity unreported")
    return ", ".join(found) or "none"


def interfaces(root):
    rows = []
    for path in sorted((root / "sys/class/net").glob("*")):
        if (path / "device").exists():
            kind = "wireless" if (path / "wireless").is_dir() else "ethernet"
            rows.append((path.name, kind))
    return tuple(rows)


def watched_config(root, watched):
    rows = []
    for entry in watched:
        relative = entry["path"].lstrip("/")
        if (root / relative).is_file():
            values = parse.parse_key_values(read(root, relative), entry["keys"])
        else:
            values = tuple((key, "file missing") for key in entry["keys"])
        rows.extend((entry["path"], key, value) for key, value in values)
    return tuple(rows)


def collect_hardware(root, run, tracked):
    model, cores, threads = parse.parse_cpuinfo(read(root, "proc/cpuinfo", True))
    memory = parse.parse_meminfo_gib(read(root, "proc/meminfo", True))
    lsblk = execute(
        run,
        [
            "lsblk",
            "--json",
            "--output",
            "NAME,SIZE,MODEL,TYPE,FSTYPE,LABEL,MOUNTPOINTS",
        ],
    )
    return Hardware(
        system=(
            ("Board", board(root, tracked["board"])),
            ("Firmware", firmware(root)),
            ("CPU", model),
            ("CPU topology", f"{cores}C/{threads}T"),
            ("Memory visible", f"{memory} GiB"),
            ("zram", zram(root)),
            ("Battery", battery(root)),
        ),
        disks=parse.parse_lsblk(lsblk),
        interfaces=interfaces(root),
        mounts=parse.parse_fstab(read(root, "etc/fstab")),
        config=watched_config(root, tracked["config"]),
    )


def toolbox_versions(run, container, packages):
    names = parse.parse_lines(
        execute(run, ["podman", "ps", "--all", "--format", "{{.Names}}"])
    )
    if container not in names:
        return "", tuple((name, "") for name in packages)
    result = run(
        [
            "toolbox",
            "run",
            "--container",
            container,
            "rpm",
            "-q",
            "--qf",
            "%{NAME}\t%{VERSION}-%{RELEASE}\n",
            *packages,
        ]
    )
    if result.code not in (0, 1):
        raise ProbeError(f"toolbox {container} rpm query failed: {result.err.strip()}")
    return container, parse.parse_rpm_versions(result.out, packages)


def app_versions(root, home, specs):
    rows = []
    for name, spec in sorted(specs.items()):
        path = root / apps.version_path(spec, home).lstrip("/")
        version = path.read_text().strip() if path.is_file() else ""
        if version:
            rows.append((name, version))
    return tuple(rows)


def fedora_release(root):
    release = parse.parse_os_release(read(root, "etc/os-release", True))
    return release["VERSION_ID"]


def collect_software(root, run, tracked, specs, home):
    release = parse.parse_os_release(read(root, "etc/os-release", True))
    deployment, layers, removals = parse.parse_rpm_ostree(
        execute(run, ["rpm-ostree", "status", "--json"])
    )
    flatpaks = execute(
        run,
        [
            "flatpak",
            "list",
            "--system",
            "--app",
            "--columns=application,version,branch,origin",
        ],
    )
    toolbox, packages = toolbox_versions(
        run, f"fedora-toolbox-{release['VERSION_ID']}", tracked["toolbox_packages"]
    )
    repos = sorted(p.name for p in (root / "etc/yum.repos.d").glob("_copr*"))
    return Software(
        os_name=release["PRETTY_NAME"],
        deployment=deployment,
        kernel=read(root, "proc/sys/kernel/osrelease", True),
        toolbox=toolbox,
        layers=layers,
        removals=removals,
        copr=parse.parse_copr_names(repos),
        flatpaks=parse.parse_flatpaks(flatpaks),
        toolbox_packages=packages,
        apps=app_versions(root, home, specs),
    )
