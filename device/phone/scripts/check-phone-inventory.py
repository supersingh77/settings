import argparse
import difflib
import pathlib
import re
import shlex
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
PHONE = ROOT / "device/phone"


def run(command):
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or f"Command failed: {shlex.join(command)}")
    return result.stdout.replace("\r", "").strip()


def adb_prefix():
    try:
        subprocess.run(["adb", "version"], capture_output=True, check=True)
        return ["adb"]
    except (OSError, subprocess.CalledProcessError):
        pass
    version = run(["rpm", "-E", "%fedora"])
    return ["toolbox", "run", "--container", f"fedora-toolbox-{version}", "adb"]


def adb(adb_command, serial, *arguments):
    return run([*adb_command, "-s", serial, *arguments])


def properties(adb_command, serial, names):
    return {
        name: adb(adb_command, serial, "shell", "getprop", name)
        for name in names
    }


def ram_visible(adb_command, serial):
    output = adb(adb_command, serial, "shell", "cat", "/proc/meminfo")
    match = re.search(r"^MemTotal:\s+(\d+) kB", output, re.MULTILINE)
    if not match:
        raise RuntimeError("Android did not report MemTotal")
    return f"{int(match.group(1)) / 1048576:.1f} GiB"


def property_table(title, properties):
    return [
        f"## {title}",
        "",
        "| Property | Value |",
        "|---|---|",
        *[f"| {key} | {value} |" for key, value in properties.items()],
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


def capture(serial, role):
    adb_command = adb_prefix()
    devices = run([*adb_command, "devices"])
    if not any(
        line.split()[:2] == [serial, "device"] for line in devices.splitlines()[1:]
    ):
        raise RuntimeError(f"Device {serial} is not connected and authorized")
    props = properties(
        adb_command,
        serial,
        (
            "ro.product.device",
            "ro.product.model",
            "ro.product.name",
            "ro.build.version.release",
            "ro.build.version.sdk",
            "ro.build.display.id",
            "ro.build.fingerprint",
            "ro.build.version.security_patch",
            "ro.miui.ui.version.name",
            "ro.boot.vbmeta.device_state",
            "ro.boot.verifiedbootstate",
        ),
    )
    if props["ro.product.device"] != "spes" or props["ro.product.model"] != "2201117TI":
        raise RuntimeError(
            "Unexpected device; expected Redmi Note 11 spes/2201117TI, "
            f"detected {props['ro.product.device']}/{props['ro.product.model']}"
        )
    hardware = {
        "Model": props["ro.product.model"],
        "Device / product": f"{props['ro.product.device']} / {props['ro.product.name']}",
        "RAM visible to Android": ram_visible(adb_command, serial),
        "Android": f"{props['ro.build.version.release']} (API {props['ro.build.version.sdk']})",
        "ROM/build": props["ro.build.display.id"],
        "Build fingerprint": props["ro.build.fingerprint"],
        "Security patch": props["ro.build.version.security_patch"],
        "MIUI version": props["ro.miui.ui.version.name"],
        "Bootloader": props["ro.boot.vbmeta.device_state"],
        "Verified boot": props["ro.boot.verifiedbootstate"],
    }
    return {"role": role, "hardware": hardware}


def proposed_documents(capture_data, role, documents):
    role_facts = capture_data["hardware"]
    if role == "personal":
        role_facts = {
            **role_facts,
            "Model": "2201117TI",
            "Device / product": "spes / spes_in",
        }
    readme = replace_section(
        documents["readme"],
        "Device state",
        property_table("Device state", role_facts),
    )
    return {f"{role}/README.md": readme}


def unified_diff(path, before, after):
    return list(
        difflib.unified_diff(
            before.splitlines(keepends=True),
            after.splitlines(keepends=True),
            fromfile=f"a/device/phone/{path}",
            tofile=f"b/device/phone/{path} (proposed)",
        )
    )


def main(arguments=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("role", choices=("personal", "work"))
    parser.add_argument("serial")
    options = parser.parse_args(arguments)
    try:
        capture_data = capture(options.serial, options.role)
        documents = {
            "readme": (PHONE / options.role / "README.md").read_text(),
        }
        proposed = proposed_documents(capture_data, options.role, documents)
    except (OSError, RuntimeError, ValueError, KeyError) as error:
        print(f"Phone inventory collection failed: {error}", file=sys.stderr)
        return 2
    originals = {
        f"{options.role}/README.md": documents["readme"],
    }
    diff = [
        line
        for path, content in proposed.items()
        for line in unified_diff(path, originals[path], content)
    ]
    if diff:
        sys.stdout.writelines(diff)
        return 1
    print(f"Live {options.role} phone inventory matches Markdown.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
