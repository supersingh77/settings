import argparse
import difflib
import json
import pathlib
import re
import shlex
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
DEVICE = ROOT / "device/fedora-laptop"


def run(command):
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or f"Command failed: {shlex.join(command)}")
    return result.stdout.strip()


def read_text(path):
    try:
        return pathlib.Path(path).read_text().strip()
    except OSError:
        return None


def kibibytes(value):
    return f"{int(value) / 1024**2:.1f} GiB"


def pci_description(line):
    return re.sub(r"^\S+\s+[^:]+:\s+", "", line)


def detect_hardware():
    meminfo = {}
    for line in pathlib.Path("/proc/meminfo").read_text().splitlines():
        match = re.match(r"(MemTotal|SwapTotal):\s+(\d+) kB", line)
        if match:
            meminfo[match.group(1)] = match.group(2)
    os_release = {}
    for line in pathlib.Path("/etc/os-release").read_text().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            os_release[key] = value.strip('"')
    cpu = json.loads(run(["lscpu", "--json"]))
    cpu_fields = {
        entry["field"].rstrip(":"): entry["data"] for entry in cpu["lscpu"]
    }
    disks = json.loads(
        run(
            [
                "lsblk",
                "--json",
                "--bytes",
                "--output",
                "NAME,MODEL,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS",
            ]
        )
    )["blockdevices"]
    pci = run(["lspci", "-nn"])
    pci_lines = pci.splitlines()
    return {
        "model": " ".join(
            filter(
                None,
                [
                    read_text("/sys/class/dmi/id/sys_vendor"),
                    read_text("/sys/class/dmi/id/product_name"),
                ],
            )
        ),
        "firmware": " ".join(
            filter(
                None,
                [
                    read_text("/sys/class/dmi/id/bios_version"),
                    read_text("/sys/class/dmi/id/bios_date"),
                ],
            )
        ),
        "os": " ".join(
            filter(None, [os_release.get("PRETTY_NAME"), os_release.get("OSTREE_VERSION")])
        ),
        "cpu": cpu_fields.get("Model name", "unknown"),
        "cpu_cores_threads": (
            f"{cpu_fields.get('Core(s) per socket', 'unknown')} cores / "
            f"{cpu_fields.get('CPU(s)', 'unknown')} threads"
        ),
        "memory": kibibytes(meminfo["MemTotal"]) if "MemTotal" in meminfo else "unavailable",
        "swap": kibibytes(meminfo["SwapTotal"]) if "SwapTotal" in meminfo else "unavailable",
        "disks": disks,
        "network": [
            pci_description(line)
            for line in pci_lines
            if re.search(r"network controller|ethernet controller", line, re.IGNORECASE)
        ],
        "graphics": [
            pci_description(line)
            for line in pci_lines
            if re.search(
                r"vga compatible controller|3d controller|display controller",
                line,
                re.IGNORECASE,
            )
        ],
    }


def rpm_ostree_inventory():
    status = json.loads(run(["rpm-ostree", "status", "--json"]))
    booted = next((entry for entry in status["deployments"] if entry.get("booted")), {})
    return {
        "version": booted.get("version", "unknown"),
        "packages": booted.get("packages", []),
        "base_removals": booted.get("requested-base-removals", []),
    }


def detect_software():
    toolboxes = run(["toolbox", "list", "--containers"])
    return {
        "host": rpm_ostree_inventory(),
        "flatpaks": run(
            ["flatpak", "list", "--system", "--columns=application,version,origin"]
        ),
        "toolboxes": toolboxes,
        "user_local_apps": sorted(
            str(path.relative_to(pathlib.Path.home()))
            for directory in (
                pathlib.Path.home() / ".local/bin",
                pathlib.Path.home() / ".local/share/applications",
            )
            if directory.exists()
            for path in directory.iterdir()
            if path.is_file() or path.is_symlink()
        ),
    }


def disk_description(disk):
    model = (disk.get("model") or "").strip()
    size = f"{int(disk['size']) / 10**9:.0f} GB" if disk.get("size") else "unknown capacity"
    return f"{model} ({size})".strip()


def flatpak_rows(flatpaks):
    rows = sorted(line.split("\t") for line in flatpaks.splitlines() if line)
    return [f"| {row[0]} | {' — '.join(part for part in row[1:] if part)} |" for row in rows]


def table(title, headers, rows):
    return [
        f"## {title}",
        "",
        f"| {' | '.join(headers)} |",
        f"|{'|'.join('---' for _ in headers)}|",
        *rows,
        "",
    ]


def replace_section(document, title, replacement):
    lines = document.splitlines()
    start = next(
        (index for index, line in enumerate(lines) if line == f"## {title}"), None
    )
    if start is None:
        return "\n".join([*lines, "", *replacement]).rstrip() + "\n"
    end = next(
        (index for index in range(start + 1, len(lines)) if lines[index].startswith("## ")),
        len(lines),
    )
    return "\n".join([*lines[:start], *replacement, *lines[end:]]).rstrip() + "\n"


def hardware_sections(data):
    disks = [
        disk
        for disk in data["disks"]
        if disk.get("type") == "disk" and not disk["name"].startswith("zram")
    ]
    facts = [
        ("Model", data["model"]),
        ("OS", data["os"].replace("'", "")),
        ("CPU", f"{data['cpu']} ({data['cpu_cores_threads']})"),
        ("Memory", f"{data['memory']} visible to Linux; {data['swap']} swap"),
        ("Storage devices", "; ".join(disk_description(disk) for disk in disks)),
        ("Graphics", "; ".join(data["graphics"]) or "not detected"),
        ("Network", "; ".join(data["network"]) or "not detected"),
        ("Firmware", data["firmware"]),
    ]
    return table("Detected system", ["Property", "Value"], [f"| {name} | {value} |" for name, value in facts])


def software_sections(data):
    host = data["host"]
    flatpaks = [line for line in data["flatpaks"].splitlines() if line]
    toolboxes = [" ".join(line.split()) for line in data["toolboxes"].splitlines()[1:] if line.strip()]
    facts = [
        ("Booted deployment", host["version"]),
        ("Layered packages", ", ".join(host["packages"]) or "none reported"),
        ("Base package removals", ", ".join(host["base_removals"]) or "none reported"),
        ("Toolboxes", "; ".join(toolboxes) or "none detected"),
        ("System Flatpaks", f"{len(flatpaks)} applications and runtimes detected"),
    ]
    sections = [
        ("Detected software", table("Detected software", ["Property", "Value"], [f"| {name} | {value} |" for name, value in facts])),
        ("System Flatpak applications", table("System Flatpak applications", ["Application", "Version / origin"], flatpak_rows(data["flatpaks"]))),
    ]
    return sections


def proposed_documents(hardware, software, documents):
    hardware_doc = replace_section(
        documents["hardware"], "Detected system", hardware_sections(hardware)
    )
    software_doc = documents["software"]
    for title, replacement in software_sections(software):
        software_doc = replace_section(software_doc, title, replacement)
    return {"hardware.md": hardware_doc, "software.md": software_doc}


def unified_diff(path, before, after):
    return list(
        difflib.unified_diff(
            before.splitlines(keepends=True),
            after.splitlines(keepends=True),
            fromfile=f"a/{path}",
            tofile=f"b/{path} (proposed)",
        )
    )


def collect(device):
    hardware = detect_hardware()
    software = detect_software()
    documents = {
        "hardware": (device / "hardware.md").read_text(),
        "software": (device / "software.md").read_text(),
    }
    return proposed_documents(hardware, software, documents), documents


def changes(proposed, documents, device_rel):
    return [
        line
        for name in ("hardware.md", "software.md")
        for line in unified_diff(
            f"{device_rel}/{name}", documents[name.removesuffix(".md")], proposed[name]
        )
    ]


def apply_changes(proposed, device):
    (device / "hardware.md").write_text(proposed["hardware.md"])
    (device / "software.md").write_text(proposed["software.md"])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write proposed inventory directly to hardware.md and software.md.",
    )
    args = parser.parse_args()
    try:
        proposed, documents = collect(DEVICE)
    except (OSError, RuntimeError, ValueError, KeyError) as error:
        print(f"Inventory collection failed: {error}", file=sys.stderr)
        return 2
    diff = changes(proposed, documents, "device/fedora-laptop")
    if not diff:
        print("Live inventory matches Markdown.")
        return 0
    if args.apply:
        apply_changes(proposed, DEVICE)
        print("Applied. Review with: git diff device/fedora-laptop/hardware.md device/fedora-laptop/software.md")
        return 0
    sys.stdout.writelines(diff)
    return 1


if __name__ == "__main__":
    sys.exit(main())
