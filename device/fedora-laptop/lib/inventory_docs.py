import difflib
import re


def kibibytes(value):
    return f"{int(value) / 1024**2:.1f} GiB"


def pci_description(line):
    return re.sub(r"^\S+\s+[^:]+:\s+", "", line)


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
    ]
    favorites = data.get("favorites", [])
    if favorites:
        fav_rows = [f"| {idx} | {app} |" for idx, app in enumerate(favorites, 1)]
        sections.append(
            ("Favorite applications (GNOME Dash)", table("Favorite applications (GNOME Dash)", ["#", "Application ID"], fav_rows))
        )
    sections.append(
        ("System Flatpak applications", table("System Flatpak applications", ["Application", "Version / origin"], flatpak_rows(data["flatpaks"])))
    )
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


def changes(proposed, documents, device_rel):
    return [
        line
        for name in ("hardware.md", "software.md")
        for line in unified_diff(
            f"{device_rel}/{name}", documents[name.removesuffix(".md")], proposed[name]
        )
    ]
