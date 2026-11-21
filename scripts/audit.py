import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
PYTHON_FILES = ("*.py",)
SHELL_FILES = ("*.sh",)
IGNORED_PARTS = {".git", ".opencode", "__pycache__"}
COMMENT_MARKERS = {".sh": re.compile(r"^\s*#(?!\!)"), ".py": re.compile(r"^\s*#(?!\!)")}
DOC_LINK = re.compile(r"\[[^]]+\]\(([^)]+\.md)(?:#[^)]+)?\)")
FRESHNESS = re.compile(
    r"last verified|last checked|verified on|as of|last updated|current host|host queried",
    re.IGNORECASE,
)
DATE = re.compile(r"\b(?:20\d{2})-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])\b")


def run(command, **options):
    return subprocess.run(
        command, cwd=ROOT, text=True, capture_output=True, check=False, **options
    )


def source_paths(pattern):
    return sorted(
        path
        for path in ROOT.rglob(pattern)
        if path.is_file()
        and not any(part in IGNORED_PARTS | {".venv"} for part in path.parts)
    )


def changed_code_paths():
    issues = []
    errors = []
    for command in (
        ["git", "diff", "--unified=0", "HEAD", "--"],
        ["git", "diff", "--cached", "--unified=0", "--"],
    ):
        result = run(command)
        if result.returncode:
            errors.append(result.stderr.strip() or "Unable to inspect diff")
            continue
        issues.extend(added_comment_lines(result.stdout))
    untracked = run(["git", "ls-files", "--others", "--exclude-standard"])
    if untracked.returncode:
        errors.append(untracked.stderr.strip() or "Unable to inspect untracked files")
    else:
        for name in untracked.stdout.splitlines():
            path = ROOT / name
            if path.suffix in COMMENT_MARKERS and (
                "scripts" in path.parts or "tests" in path.parts
            ):
                issues.extend(comment_issues([path]))
    return issues, errors


def added_comment_lines(diff):
    issues = []
    current = None
    for line in diff.splitlines():
        if line.startswith("+++ b/"):
            current = ROOT / line[6:]
        elif (
            line.startswith("+")
            and not line.startswith("+++")
            and current
            and current.suffix in COMMENT_MARKERS
            and ("scripts" in current.parts or "tests" in current.parts)
        ):
            code = line[1:]
            if code.startswith("#!"):
                continue
            if COMMENT_MARKERS[current.suffix].search(code):
                issues.append(f"{current.relative_to(ROOT)}: newly added code comment")
    return issues


def comment_issues(paths):
    issues = []
    for path in paths:
        for number, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
            if line.startswith("#!"):
                continue
            if COMMENT_MARKERS[path.suffix].search(line):
                issues.append(f"{path}:{number}: code comment")
    return issues


def doc_issues(paths):
    issues = []
    for path in paths:
        text = path.read_text(errors="replace")
        for number, line in enumerate(text.splitlines(), 1):
            if FRESHNESS.search(line) and DATE.search(line):
                issues.append(f"{path}:{number}: dated freshness claim")
            for target in DOC_LINK.findall(line):
                if "://" in target:
                    continue
                linked = (
                    (ROOT / target).resolve()
                    if target.startswith("device/")
                    else (path.parent / target).resolve()
                )
                if not linked.exists():
                    issues.append(f"{path}:{number}: missing document {target}")
    readme = ROOT / "device/fedora-laptop/README.md"
    if readme.exists():
        setup_refs = re.findall(r"scripts/([A-Za-z0-9_.-]+\.sh)", readme.read_text())
        if any(
            not (ROOT / "device/fedora-laptop/scripts" / name).exists()
            for name in setup_refs
        ):
            issues.append(f"{readme}: setup script reference does not exist")
    return issues


def lint_issues(shell_files, python_files):
    issues = []
    checks = ("shellcheck", "shfmt", "ruff")
    for tool in checks:
        files = shell_files if tool in {"shellcheck", "shfmt"} else python_files
        if not files:
            continue
        options = {
            "shellcheck": ["-x", "-P", str(ROOT / "device/fedora-laptop/scripts")],
            "shfmt": ["-d", "-i", "4", "-ci"],
            "ruff": ["check"],
        }[tool]
        executable = shutil.which(tool)
        if executable:
            command = [executable, *options, *(str(path) for path in files)]
        elif tool == "ruff" and (ROOT / ".venv/bin/ruff").exists():
            command = [
                str(ROOT / ".venv/bin/ruff"),
                *options,
                *(str(path) for path in files),
            ]
        else:
            print(f"INFO {tool} unavailable; skipped")
            continue
        result = run(command)
        if result.returncode:
            issues.extend((result.stdout + result.stderr).splitlines())
    return issues


def tests():
    test_files = sorted((ROOT / "device/fedora-laptop/tests").glob("test_*.py"))
    issues = []
    for path in test_files:
        result = run([sys.executable, "-m", "unittest", str(path.relative_to(ROOT))])
        if result.returncode:
            issues.append((result.stdout + result.stderr).strip())
    return issues


def syntax_issues(shell_files):
    issues = []
    for path in shell_files:
        result = run(["bash", "-n", str(path)])
        if result.returncode:
            issues.append((result.stdout + result.stderr).strip())
    return issues


def main():
    shell_files = [path for path in source_paths("*.sh") if "scripts" in path.parts]
    python_files = [
        path
        for path in source_paths("*.py")
        if ("scripts" in path.parts or "tests" in path.parts)
        and ("device/fedora-laptop" in path.parts or path == ROOT / "scripts/audit.py")
    ]
    changed, changed_errors = changed_code_paths()
    checks = {
        "lint": lint_issues(shell_files, python_files),
        "shell syntax": syntax_issues(shell_files),
        "tests": tests(),
        "new code comments": changed,
        "documentation": doc_issues(
            path
            for path in source_paths("*.md")
            if "fedora-laptop" in path.parts or path == ROOT / "README.md"
        ),
    }
    for issue in changed_errors:
        checks["new code comments"].append(issue)
    failed = False
    for name, issues in checks.items():
        print(f"{'FAIL' if issues else 'PASS'} {name}")
        for issue in issues:
            print(f"  {issue}")
        failed |= bool(issues)
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
