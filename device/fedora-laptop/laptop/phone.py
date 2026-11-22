from . import parse
from .tables import table

LISTS = {
    "installed": "installed-user-0.txt",
    "third_party": "third-party-user-0.txt",
    "everything": "all-user-0-including-uninstalled.txt",
    "removed": "not-installed-user-0.txt",
}


class PhoneError(Exception):
    pass


def package_names(text):
    names = (line.strip().removeprefix("package:") for line in text.splitlines())
    return sorted({name for name in names if name})


def validate_model(props, expected):
    model = props.get("ro.product.model", "")
    device = props.get("ro.product.device", "")
    if model != expected["model"] or device != expected["device"]:
        raise PhoneError(
            f"unexpected device: model={model!r} device={device!r}, "
            f"expected model={expected['model']!r} device={expected['device']!r}"
        )


def render_phone(props, meminfo):
    ram = int(parse.field(meminfo, "MemTotal").split()[0]) / 1048576
    sdk = props.get("ro.build.version.sdk", "")
    rows = (
        ("Model", props.get("ro.product.model", "")),
        (
            "Device",
            f"{props.get('ro.product.device', '')} ({props.get('ro.product.name', '')})",
        ),
        ("RAM visible to Android", f"{ram:.1f} GiB"),
        ("Android", f"{props.get('ro.build.version.release', '')} (API {sdk})"),
        ("ROM/build", props.get("ro.build.display.id", "")),
        ("Build fingerprint", props.get("ro.build.fingerprint", "")),
        ("Security patch", props.get("ro.build.version.security_patch", "")),
        ("MIUI version", props.get("ro.miui.ui.version.name", "")),
        ("Bootloader", props.get("ro.boot.vbmeta.device_state", "")),
        ("Verified boot", props.get("ro.boot.verifiedbootstate", "")),
    )
    return ["## Device state", "", *table(("Property", "Value"), rows)]


def replace_section(document, title, replacement):
    lines = document.splitlines()
    heading = f"## {title}"
    start = next((index for index, line in enumerate(lines) if line == heading), None)
    if start is None:
        return "\n".join([*lines, "", *replacement]).rstrip() + "\n"
    end = next(
        (index for index in range(start + 1, len(lines)) if lines[index].startswith("## ")),
        len(lines),
    )
    return "\n".join([*lines[:start], *replacement, *lines[end:]]).rstrip() + "\n"


def lines_text(names):
    return "".join(f"{name}\n" for name in names)


def phone_files(
    role, props, meminfo, installed, third_party, everything, existing_readme=""
):
    removed = sorted(set(everything) - set(installed))
    readme = existing_readme or f"# Redmi Note 11 — {role}\n"
    return {
        "README.md": replace_section(
            readme, "Device state", render_phone(props, meminfo)
        ),
        LISTS["installed"]: lines_text(installed),
        LISTS["third_party"]: lines_text(third_party),
        LISTS["everything"]: lines_text(everything),
        LISTS["removed"]: lines_text(removed),
    }


def changed_files(existing, files):
    return sorted(name for name, text in files.items() if existing.get(name) != text)


def adb_state(devices):
    if not devices:
        return "none"
    for _serial, state in devices:
        if state != "device":
            return state
    return "ready"
