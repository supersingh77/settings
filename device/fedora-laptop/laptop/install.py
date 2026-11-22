import shutil
import struct
import tarfile
import tempfile
import urllib.error
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path

from . import apps
from .download import DownloadError
from .model import StepError


@dataclass(frozen=True)
class Ctx:
    home: Path
    toolbox: str
    dry_run: bool
    fetch_json: Callable
    download: Callable
    run: Callable
    say: Callable


def expander(spec, ctx):
    values = apps.paths(spec, ctx.home)

    def expand(template):
        return apps.expand(
            template, home=ctx.home, toolbox=ctx.toolbox, install=values["install"]
        )

    return expand


def ensure_bytes(path, data, mode, ctx):
    same = path.is_file() and path.read_bytes() == data
    if same and path.stat().st_mode & 0o777 == mode:
        return 0
    ctx.say(f"{'would write' if ctx.dry_run else 'write'} {path}")
    if not ctx.dry_run:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        path.chmod(mode)
    return 1


def ensure_text(path, text, mode, ctx):
    return ensure_bytes(path, text.encode(), mode, ctx)


def icon_data(icon, expand):
    if icon["kind"] == "file":
        source = Path(expand(icon["source"]))
        return source.read_bytes() if source.is_file() else None
    if icon["kind"] == "asar":
        source = Path(expand(icon["asar"]))
        if not source.is_file():
            return None
        with open(source, "rb") as handle:

            def read(offset, length):
                handle.seek(offset)
                return handle.read(length)

            try:
                return apps.asar_entry(read, icon["entry"])
            except (KeyError, ValueError, struct.error, OSError):
                return None
    return None


def ensure_icon(spec, ctx, expand, values):
    icon = spec.get("icon")
    if not icon:
        return 0
    target = Path(values["icon"])
    if icon["kind"] == "url":
        if target.is_file():
            return 0
        ctx.say(f"{'would download' if ctx.dry_run else 'download'} icon {target}")
        if not ctx.dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            try:
                ctx.download(icon["url"], target)
            except (DownloadError, OSError) as error:
                ctx.say(f"icon download skipped: {error}")
        return 1
    data = icon_data(icon, expand)
    if data is None:
        return 0
    return ensure_bytes(target, data, 0o644, ctx)


def integrate(spec, ctx):
    values = apps.paths(spec, ctx.home)
    expand = expander(spec, ctx)
    changed = 0
    launcher = spec.get("launcher")
    if launcher:
        env = [(name, expand(value)) for name, value in launcher["env"]]
        text = apps.render_launcher(env, expand(launcher["command"]))
        changed += ensure_text(Path(values["launcher"]), text, 0o755, ctx)
    desktop = spec.get("desktop")
    if desktop:
        entries = [(key, expand(value)) for key, value in desktop]
        text = apps.render_desktop(entries)
        changed += ensure_text(Path(values["desktop"]), text, 0o644, ctx)
    return changed + ensure_icon(spec, ctx, expand, values)


def put_appimage(spec, url, ctx, values):
    target = Path(values["install"])
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=target.parent) as scratch:
        image = Path(scratch) / "app.AppImage"
        ctx.download(url, image)
        image.chmod(0o755)
        result = ctx.run([str(image), "--appimage-extract"], cwd=scratch)
        extracted = Path(scratch) / "squashfs-root"
        if result.code != 0 or not extracted.is_dir():
            raise StepError(f"AppImage extraction failed: {result.err.strip()}")
        shutil.rmtree(target, ignore_errors=True)
        extracted.rename(target)


def put_binary(spec, url, ctx, values):
    target = Path(values["install"])
    target.parent.mkdir(parents=True, exist_ok=True)
    partial = target.with_name(target.name + ".part")
    try:
        ctx.download(url, partial)
        partial.chmod(0o755)
        partial.replace(target)
    finally:
        partial.unlink(missing_ok=True)


def put_tarball(spec, url, ctx, values):
    target = Path(values["install"])
    target.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=target) as scratch:
        archive = Path(scratch) / "payload.tar.gz"
        ctx.download(url, archive)
        shutil.rmtree(target / spec["install"]["replace"], ignore_errors=True)
        with tarfile.open(archive) as tar:
            tar.extractall(target, filter="data")
    if not (target / spec["install"]["verify"]).is_file():
        raise StepError("archive did not contain the expected binary")


FAILURES = (
    StepError,
    DownloadError,
    OSError,
    ValueError,
    KeyError,
    tarfile.TarError,
    urllib.error.URLError,
)
INSTALLERS = {"appimage": put_appimage, "binary": put_binary, "tarball": put_tarball}


def installed_version(spec, home):
    path = Path(apps.version_path(spec, home))
    return path.read_text().strip() if path.is_file() else ""


def refresh_caches(ctx):
    applications = ctx.home / ".local/share/applications"
    icons = ctx.home / ".local/share/icons/hicolor"
    ctx.run(["update-desktop-database", str(applications)])
    ctx.run(["gtk-update-icon-cache", "-f", "-t", str(icons)])


def install_app(name, spec, ctx, force=False):
    values = apps.paths(spec, ctx.home)
    version, url = apps.latest_release(spec, ctx.fetch_json)
    installed = installed_version(spec, ctx.home)
    present = Path(values["install"]).exists()
    changed = 0
    if apps.should_install(installed, version, present, force):
        changed += 1
        verb = "would install" if ctx.dry_run else "install"
        ctx.say(f"{verb} {name} {version} (installed: {installed or 'none'})")
        if not ctx.dry_run:
            INSTALLERS[spec["install"]["kind"]](spec, url, ctx, values)
            ensure_text(Path(values["version"]), version + "\n", 0o644, ctx)
    changed += integrate(spec, ctx)
    if changed and not ctx.dry_run:
        refresh_caches(ctx)
    return changed


def remove_app(name, spec, ctx):
    changed = 0
    for path in map(Path, apps.owned_paths(spec, ctx.home)):
        if path.is_symlink() or path.exists():
            changed += 1
            ctx.say(f"{'would remove' if ctx.dry_run else 'remove'} {path}")
            if not ctx.dry_run:
                if path.is_dir() and not path.is_symlink():
                    shutil.rmtree(path)
                else:
                    path.unlink()
    if changed and not ctx.dry_run:
        refresh_caches(ctx)
    return changed
