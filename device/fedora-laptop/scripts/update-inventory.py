#!/usr/bin/env python3
import argparse
import json
import pathlib
import re
import shlex
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
DEVICE = ROOT / "device/fedora-laptop"
sys.path.insert(0, str(DEVICE / "lib"))

from inventory_docs import (
    changes,
    kibibytes,
    pci_description,
    proposed_documents,
)


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


def detect_gnome_favorites():
    try:
        raw = run(["gsettings", "get", "org.gnome.shell", "favorite-apps"])
        return re.findall(r"'([^']+)'", raw)
    except (RuntimeError, OSError):
        return []


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
        "favorites": detect_gnome_favorites(),
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


def collect(device):
    hardware = detect_hardware()
    software = detect_software()
    documents = {
        "hardware": (device / "hardware.md").read_text(),
        "software": (device / "software.md").read_text(),
    }
    return proposed_documents(hardware, software, documents), documents


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
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview proposed changes without writing to repository files.",
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
    if args.apply and not args.dry_run:
        apply_changes(proposed, DEVICE)
        print("Applied. Review with: git diff device/fedora-laptop/hardware.md device/fedora-laptop/software.md")
        return 0
    sys.stdout.writelines(diff)
    return 1


if __name__ == "__main__":
    sys.exit(main())
