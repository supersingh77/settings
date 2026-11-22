import json
import re

BLOCK_KINDS = {"disk", "part", "lvm", "crypt"}
VIRTUAL_PREFIXES = ("zram",)
APP_ID = re.compile(r"^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)+$")
COPR_FILE = re.compile(
    r"^_copr:(?:copr\.fedorainfracloud\.org:)?(?P<owner>[^:]+):(?P<project>[^:]+)\.repo$"
)
GETPROP_LINE = re.compile(r"^\[(?P<key>[^\]]+)\]: \[(?P<value>.*)\]$")


def field(text, prefix):
    for line in text.splitlines():
        if line.startswith(prefix):
            return line.split(":", 1)[1].strip()
    return ""


def parse_cpuinfo(text):
    model = field(text, "model name")
    cores = field(text, "cpu cores")
    threads = sum(1 for line in text.splitlines() if line.startswith("processor"))
    if not model or not cores or not threads:
        raise ValueError("cpuinfo has no model, core count or processors")
    return model, int(cores), threads


def parse_meminfo_gib(text):
    kib = field(text, "MemTotal").split()[0]
    return round(int(kib) / 1048576)


def parse_lsblk(text):
    return tuple(walk_block_devices(json.loads(text)["blockdevices"]))


def walk_block_devices(devices):
    for device in devices:
        name = device["name"]
        if device.get("type") in BLOCK_KINDS and not name.startswith(VIRTUAL_PREFIXES):
            mounts = [m for m in device.get("mountpoints") or [] if m]
            yield (
                name,
                device["size"],
                (device.get("model") or "").strip(),
                device["type"],
                device.get("fstype") or "",
                device.get("label") or "",
                ", ".join(mounts),
            )
        yield from walk_block_devices(device.get("children") or [])


def parse_rpm_ostree(text):
    deployments = json.loads(text)["deployments"]
    booted = next((d for d in deployments if d.get("booted")), None)
    if booted is None:
        raise ValueError("rpm-ostree status has no booted deployment")
    requested = next((d for d in deployments if d.get("staged")), booted)
    required = {"requested-packages", "requested-base-removals"}
    missing = required - requested.keys()
    if missing:
        raise ValueError(
            "rpm-ostree status is missing requested state: " + ", ".join(sorted(missing))
        )
    return (
        booted["version"],
        tuple(sorted(requested.get("requested-packages", []))),
        tuple(sorted(requested.get("requested-base-removals", []))),
    )


def has_staged_deployment(text):
    return any(d.get("staged") for d in json.loads(text)["deployments"])


def parse_flatpaks(text):
    rows = []
    for line in text.splitlines():
        if not line.strip():
            continue
        cells = tuple(c.strip() for c in line.split("\t"))
        if cells == ("Application ID", "Version", "Branch", "Origin"):
            continue
        if len(cells) != 4 or not APP_ID.match(cells[0]):
            raise ValueError(f"unrecognized Flatpak inventory row: {line!r}")
        rows.append(cells)
    return tuple(sorted(rows))


def parse_rpm_versions(text, names):
    found = {}
    for line in text.splitlines():
        name, _, version = line.partition("\t")
        if version:
            found[name] = version.strip()
    return tuple((name, found.get(name, "")) for name in names)


def parse_os_release(text):
    values = {}
    for line in text.splitlines():
        key, sep, value = line.partition("=")
        if sep:
            values[key.strip()] = value.strip().strip('"')
    return values


def parse_key_values(text, keys):
    found = {}
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped[0] in "#;[":
            continue
        key, sep, value = stripped.partition("=")
        if sep and key.strip() in keys:
            found[key.strip()] = value.strip()
    return tuple((key, found.get(key, "unset")) for key in keys)


def parse_fstab(text):
    rows = []
    for line in text.splitlines():
        fields = line.split()
        if len(fields) >= 4 and not fields[0].startswith("#"):
            rows.append((fields[1], fields[0], fields[2], fields[3]))
    return tuple(sorted(rows))


def parse_lines(text):
    return tuple(line.strip() for line in text.splitlines() if line.strip())


def parse_copr_names(filenames):
    repos = []
    for name in filenames:
        match = COPR_FILE.match(name)
        if match:
            repos.append(f"{match['owner']}/{match['project']}")
    return tuple(sorted(repos))


def parse_adb_devices(text):
    rows = []
    for line in text.splitlines()[1:]:
        cells = line.split()
        if len(cells) >= 2:
            rows.append((cells[0], cells[1]))
    return tuple(rows)


def parse_getprop(text):
    props = {}
    for line in text.splitlines():
        match = GETPROP_LINE.match(line.strip())
        if match:
            props[match["key"]] = match["value"]
    return props
