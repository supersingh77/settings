MARKER = "device/fedora-laptop/shellrc"
PROFILE_LINE = "[ -f ~/.bashrc ] && source ~/.bashrc"


def bashrc_hook(repo_root):
    repo_root = repo_root.replace("'", "'\\''")
    return (
        f"export SETTINGS_ROOT='{repo_root}'\n"
        f'if [ -f "$SETTINGS_ROOT/{MARKER}" ]; then . "$SETTINGS_ROOT/{MARKER}"; fi\n'
    )


def with_bashrc_hook(text, repo_root):
    hook = bashrc_hook(repo_root)
    if MARKER in text:
        lines = text.splitlines(keepends=True)
        for index, line in enumerate(lines):
            if line.startswith("export SETTINGS_ROOT="):
                lines[index] = hook.splitlines(keepends=True)[0]
                return "".join(lines)
        return text
    separator = "" if not text or text.endswith("\n") else "\n"
    return f"{text}{separator}\n{hook}"


def with_profile_hook(text):
    if ".bashrc" in text:
        return text
    separator = "" if not text or text.endswith("\n") else "\n"
    return f"{text}{separator}\n{PROFILE_LINE}\n"


def is_retired_link(target):
    return "device/fedora-laptop/scripts" in target
