import argparse
import shutil
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path

from . import (
    declared,
    executor,
    hooks,
    install,
    media,
    parse,
    phone,
    plan,
    probe,
    shell,
)
from .download import download
from .model import ProbeError, StepError
from .render import parse_software, render_hardware, render_software
from .sync import sync_files

DEVICE_DIR = declared.DECLARED_DIR.parent
USAGE_ERROR = 2


@dataclass(frozen=True)
class Env:
    root: Path
    home: Path
    device_dir: Path
    run: Callable
    run_live: Callable
    fetch_json: Callable
    download: Callable
    say: Callable
    which: Callable

    @property
    def phone_dir(self):
        return self.device_dir.parent / "phone"

    @property
    def repo_root(self):
        return self.device_dir.parents[1]


def system_env():
    return Env(
        root=Path("/"),
        home=Path.home(),
        device_dir=DEVICE_DIR,
        run=shell.run,
        run_live=shell.run_live,
        fetch_json=shell.fetch_json,
        download=download,
        say=shell.say,
        which=shutil.which,
    )


def install_ctx(env, dry_run):
    toolbox = f"fedora-toolbox-{probe.fedora_release(env.root)}"
    return install.Ctx(
        home=env.home,
        toolbox=toolbox,
        dry_run=dry_run,
        fetch_json=env.fetch_json,
        download=env.download,
        run=env.run,
        say=env.say,
    )


def require_target_device(env):
    probe.board(env.root, declared.load("tracked")["board"])


def live_software(env):
    return probe.collect_software(
        env.root, env.run, declared.load("tracked"), declared.load("apps"), env.home
    )


def cmd_capture(args, env):
    hardware = probe.collect_hardware(env.root, env.run, declared.load("tracked"))
    files = {
        "hardware.md": render_hardware(hardware),
        "software.md": render_software(live_software(env)),
    }
    return sync_files(env.device_dir, files, args.check, env.say)


def staged_notice(env):
    result = env.run(["rpm-ostree", "status", "--json"])
    if result.code == 0 and parse.has_staged_deployment(result.out):
        env.say("a deployment is staged: reboot to apply it")


def finish(env, failures, changed_hint):
    if failures:
        env.say(f"{len(failures)} steps failed: {', '.join(failures)}")
        return 1
    staged_notice(env)
    if changed_hint:
        env.say("run `make capture` and review `git diff`")
    return 0


def cmd_restore(args, env):
    require_target_device(env)
    path = env.device_dir / "software.md"
    if not path.is_file():
        raise ProbeError("software.md is missing: run `make capture` first")
    want = parse_software(path.read_text())
    unsafe = plan.unsafe_names(want)
    if unsafe:
        raise ProbeError(f"software.md holds unsafe names: {', '.join(unsafe)}")
    steps = plan.plan_restore(want, live_software(env), probe.fedora_release(env.root))
    if not steps:
        env.say("0 changes")
        return 0
    failures = executor.execute(
        steps, declared.load("apps"), install_ctx(env, args.dry_run), env.run_live
    )
    return 0 if args.dry_run else finish(env, failures, False)


def cmd_maintenance(group):
    def run_group(args, env):
        require_target_device(env)
        ctx = install_ctx(env, args.dry_run)
        steps = executor.maintenance_steps(
            declared.load("maintenance")[group], ctx.toolbox
        )
        failures = executor.execute(steps, declared.load("apps"), ctx, env.run_live)
        return 0 if args.dry_run else finish(env, failures, group == "update")

    return run_group


def cmd_apps(args, env):
    require_target_device(env)
    specs = declared.load("apps")
    names = args.names or sorted(specs)
    unknown = [name for name in names if name not in specs]
    if unknown:
        raise ProbeError(f"unknown apps: {', '.join(unknown)}")
    ctx = install_ctx(env, args.dry_run)
    changed = 0
    for name in names:
        changed += install.install_app(name, specs[name], ctx, force=args.force)
    env.say(f"{changed} changes")
    return 0


def cmd_uad(args, env):
    require_target_device(env)
    ctx = install_ctx(env, False)
    binary = env.home / ".local/bin/uad-ng"
    if not binary.is_file():
        env.say("uad-ng is not installed: run `laptop apps uad-ng`")
        return 1
    if env.which("adb"):
        env.run(["adb", "kill-server"])
    listing = env.run(["toolbox", "run", "-c", ctx.toolbox, "adb", "devices"])
    state = phone.adb_state(parse.parse_adb_devices(listing.out))
    if state != "ready" and not args.force:
        env.say(f"adb state: {state}; fix it or pass --force")
        return 1
    return env.run_live(["toolbox", "run", "-c", ctx.toolbox, str(binary)])


def cmd_phone(args, env):
    spec = declared.load("phone")
    ctx = install_ctx(env, False)
    adb = ["adb"] if env.which("adb") else ["toolbox", "run", "-c", ctx.toolbox, "adb"]
    devices = parse.parse_adb_devices(env.run([*adb, "devices"]).out)
    if (args.serial, "device") not in devices:
        env.say(f"device {args.serial} is not connected and authorized")
        return 1

    def query(*arguments):
        result = env.run([*adb, "-s", args.serial, "shell", *arguments])
        if result.code != 0:
            raise ProbeError(f"adb {' '.join(arguments)} failed: {result.err.strip()}")
        return result.out

    props = parse.parse_getprop(query("getprop"))
    phone.validate_model(props, spec)
    packages = [
        phone.package_names(query("pm", "list", "packages", *flags, "--user", "0"))
        for flags in ((), ("-3",), ("-u",))
    ]
    files = phone.phone_files(
        args.role,
        props,
        query("cat", "/proc/meminfo"),
        *packages,
        existing_readme=(env.phone_dir / args.role / "README.md").read_text()
        if (env.phone_dir / args.role / "README.md").is_file()
        else "",
    )
    return sync_files(env.phone_dir / args.role, files, args.check, env.say)


def ffmpeg_command(env):
    toolbox = f"fedora-toolbox-{probe.fedora_release(env.root)}"
    return media.ffmpeg_prefix(bool(env.which("ffmpeg")), toolbox)


def run_media(env, arguments, dry_run):
    argv = [*ffmpeg_command(env), *arguments]
    env.say(" ".join(argv))
    return 0 if dry_run else env.run_live(argv)


def cmd_denoise_extract(args, env):
    _output, arguments = media.extract_audio(args.video)
    return run_media(env, arguments, args.dry_run)


def cmd_denoise_merge(args, env):
    bitrate = declared.load("media")["audio_bitrate"]
    _output, arguments = media.merge_audio(args.video, args.audio, bitrate)
    return run_media(env, arguments, args.dry_run)


def cmd_join(args, env):
    settings = declared.load("media")
    folder = Path(args.folder)
    output = args.output or settings["default_join_output"]
    clips = media.select_clips(
        (path.name for path in folder.iterdir() if path.is_file()),
        set(settings["video_extensions"]),
        output,
    )
    if len(clips) < 2:
        env.say(f"need at least 2 clips in {folder}, found {len(clips)}")
        return 1
    listing = media.concat_list(folder.resolve(), clips)
    if args.dry_run:
        env.say(listing.rstrip("\n"))
        return run_media(env, media.join_arguments("LIST", folder / output), True)
    list_path = folder / f".{output}.list"
    list_path.write_text(listing)
    try:
        return run_media(env, media.join_arguments(list_path, folder / output), False)
    finally:
        list_path.unlink(missing_ok=True)


def cmd_shell(args, env):
    require_target_device(env)
    changed = 0
    for relative, edit in (
        (".bashrc", lambda text: hooks.with_bashrc_hook(text, env.repo_root)),
        (".bash_profile", hooks.with_profile_hook),
    ):
        path = env.home / relative
        old = path.read_text() if path.is_file() else ""
        if relative == ".bash_profile" and not path.is_file():
            continue
        new = edit(old)
        if new != old:
            changed += 1
            env.say(f"{'would update' if args.dry_run else 'update'} {path}")
            if not args.dry_run:
                path.write_text(new)
    for name in declared.load("tracked")["retired_commands"]:
        link = env.home / ".local/bin" / name
        if link.is_symlink() and hooks.is_retired_link(str(link.readlink())):
            changed += 1
            env.say(f"{'would remove' if args.dry_run else 'remove'} {link}")
            if not args.dry_run:
                link.unlink()
    env.say(f"{changed} changes")
    return 0


def build_parser():
    parser = argparse.ArgumentParser(prog="laptop")
    commands = parser.add_subparsers(dest="command", required=True)

    def command(name, handler):
        sub = commands.add_parser(name)
        sub.set_defaults(handler=handler)
        return sub

    capture = command("capture", cmd_capture)
    capture.add_argument("--check", action="store_true")
    for name, handler in (
        ("restore", cmd_restore),
        ("update", cmd_maintenance("update")),
        ("cleanup", cmd_maintenance("cleanup")),
        ("shell", cmd_shell),
    ):
        command(name, handler).add_argument("--dry-run", action="store_true")
    apps = command("apps", cmd_apps)
    apps.add_argument("--dry-run", action="store_true")
    apps.add_argument("--force", action="store_true")
    apps.add_argument("names", nargs="*")
    command("uad", cmd_uad).add_argument("--force", action="store_true")
    handset = command("phone", cmd_phone)
    handset.add_argument("role", choices=declared.load("phone")["roles"])
    handset.add_argument("serial")
    handset.add_argument("--check", action="store_true")
    extract = command("denoise-extract", cmd_denoise_extract)
    extract.add_argument("video")
    extract.add_argument("--dry-run", action="store_true")
    merge = command("denoise-merge", cmd_denoise_merge)
    merge.add_argument("video")
    merge.add_argument("audio")
    merge.add_argument("--dry-run", action="store_true")
    join = command("join", cmd_join)
    join.add_argument("folder")
    join.add_argument("output", nargs="?")
    join.add_argument("--dry-run", action="store_true")
    return parser


def main(argv=None, env=None):
    args = build_parser().parse_args(argv)
    env = env or system_env()
    try:
        return args.handler(args, env)
    except (ProbeError, phone.PhoneError, StepError, ValueError) as error:
        env.say(f"error: {error}")
        return USAGE_ERROR
