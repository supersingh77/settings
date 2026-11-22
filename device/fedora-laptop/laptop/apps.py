import json
import struct

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def expand(template, **values):
    for key, value in values.items():
        template = template.replace("{" + key + "}", str(value))
    return template


def match_asset(assets, rule):
    for asset in assets:
        name = asset["name"]
        if "name" in rule:
            matched = name == rule["name"]
        else:
            matched = name.startswith(rule["prefix"]) and name.endswith(rule["suffix"])
        if matched:
            return asset["browser_download_url"]
    return ""


def github_latest(release, rule):
    version = release.get("tag_name", "").removeprefix("v")
    url = match_asset(release.get("assets", []), rule)
    if not version or not url:
        raise ValueError("release has no version or no matching asset")
    return version, url


def antigravity_latest(releases, url_template):
    if not releases:
        raise ValueError("release list is empty")
    newest = releases[0]
    version = f"{newest['version']}-{newest['execution_id']}"
    url = expand(
        url_template, version=newest["version"], execution=newest["execution_id"]
    )
    return version, url


def latest_release(spec, fetch_json):
    source = spec["source"]
    if source["kind"] == "github":
        release = fetch_json(
            f"https://api.github.com/repos/{source['repo']}/releases/latest"
        )
        return github_latest(release, source["asset"])
    if source["kind"] == "antigravity":
        return antigravity_latest(fetch_json(source["api"]), source["download"])
    raise ValueError(f"unknown release source {source['kind']!r}")


def should_install(installed, latest, present, force):
    return force or not present or installed != latest


def render_launcher(env, command):
    lines = ["#!/bin/bash"]
    lines.extend(f"export {name}={value}" for name, value in env)
    lines.append(f'exec {command} "$@"')
    return "\n".join(lines) + "\n"


def render_desktop(entries):
    lines = ["[Desktop Entry]"]
    lines.extend(f"{key}={value}" for key, value in entries)
    return "\n".join(lines) + "\n"


def asar_entry(read, name):
    head = read(0, 16)
    header_size, json_length = struct.unpack("<II", head[4:8] + head[12:16])
    node = {"files": json.loads(read(16, json_length))["files"]}
    for part in name.split("/"):
        node = node["files"][part]
    return read(8 + header_size + int(node["offset"]), node["size"])


def png_size(data):
    if data[:8] != PNG_SIGNATURE:
        raise ValueError("not a PNG")
    return struct.unpack(">II", data[16:24])


def paths(spec, home):
    values = {"home": str(home)}
    return {key: expand(value, **values) for key, value in spec["paths"].items()}


def version_path(spec, home):
    return paths(spec, home)["version"]


def owned_paths(spec, home):
    return tuple(sorted(set(paths(spec, home).values())))
