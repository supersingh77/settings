import difflib


def read_existing(directory, names):
    existing = {}
    for name in names:
        path = directory / name
        existing[name] = path.read_text() if path.is_file() else None
    return existing


def unified(name, old, new):
    return "\n".join(
        difflib.unified_diff(
            (old or "").splitlines(),
            new.splitlines(),
            fromfile=f"a/{name}",
            tofile=f"b/{name}",
            lineterm="",
        )
    )


def sync_files(directory, files, check, say):
    existing = read_existing(directory, files)
    changed = sorted(name for name, text in files.items() if existing[name] != text)
    if not changed:
        say("0 changes")
        return 0
    for name in changed:
        say(unified(name, existing[name], files[name]))
    if check:
        say(f"{len(changed)} files differ from the live state")
        return 1
    directory.mkdir(parents=True, exist_ok=True)
    for name in changed:
        (directory / name).write_text(files[name])
    say(f"wrote {len(changed)} files: review `git diff`")
    return 0
