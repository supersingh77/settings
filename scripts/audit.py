import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
CODE_SUFFIXES = {".sh", ".py"}
IGNORED_PARTS = {".git", ".opencode", "__pycache__"}
SHEBANG = re.compile(r"^#!")
COMMENT_MARKERS = {
    ".sh": re.compile(r"^\s*#(?!\!)"),
    ".py": re.compile(r"^\s*#(?!\!)"),
}
DATE = re.compile(r"\b(?:20\d{2})-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])\b")
DOC_LINK = re.compile(r"\[[^]]+\]\(([^)]+\.md)(?:#[^)]+)?\)")


def tracked_paths():
    output = subprocess.run(
        ["git", "-C", str(ROOT), "ls-files", "-z"],
        check=True,
        stdout=subprocess.PIPE,
    ).stdout
    return [ROOT / path.decode() for path in output.split(b"\0") if path]


def code_comment_issues(paths):
    issues = []
    for path in paths:
        if path.suffix not in CODE_SUFFIXES or not path.is_file():
            continue
        if "scripts" not in path.parts:
            continue
        if path.suffix == ".py" and "fedora-laptop" in path.parts:
            continue
        if path.suffix == ".sh" and (
            "fedora-laptop" not in path.parts or path.name != "test-shell.sh"
        ):
            continue
        for number, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
            if SHEBANG.match(line):
                continue
            if COMMENT_MARKERS[path.suffix].search(line):
                issues.append(f"{path.relative_to(ROOT)}:{number}: code comment")
    return issues


def new_code_comment_issues(paths):
    result = subprocess.run(
        [
            "git",
            "-C",
            str(ROOT),
            "diff",
            "--unified=0",
            "--",
            "device/fedora-laptop/scripts",
            "scripts",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    issues = []
    current = None
    for line in result.stdout.splitlines():
        if line.startswith("+++ b/"):
            current = ROOT / line[6:]
        elif line.startswith("@@"):
            continue
        elif (
            line.startswith("+")
            and not line.startswith("+++")
            and current
            and current.suffix in CODE_SUFFIXES
        ):
            if SHEBANG.match(line[1:]) or not COMMENT_MARKERS[current.suffix].search(
                line[1:]
            ):
                continue
            issues.append(f"{current.relative_to(ROOT)}: added code comment")
    return issues


def stale_date_issues(paths):
    issues = []
    for path in paths:
        if path.suffix != ".md" or not path.is_file():
            continue
        text = path.read_text(errors="replace")
        for line_number, line in enumerate(text.splitlines(), 1):
            if re.search(
                r"last verified|last checked|verified on|as of|last updated|current host|host queried",
                line,
                re.IGNORECASE,
            ):
                dates = DATE.findall(line)
                if dates:
                    issues.append(
                        f"{path.relative_to(ROOT)}:{line_number}: dated freshness claim(s): {', '.join(dict.fromkeys(dates))}"
                    )
    return issues


def current_claim_issues(paths):
    issues = []
    for path in paths:
        if path.suffix != ".md" or not path.is_file():
            continue
        for number, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
            if re.search(
                r"last verified|last checked|verified on|as of|last updated",
                line,
                re.IGNORECASE,
            ) and DATE.search(line):
                issues.append(f"{path.relative_to(ROOT)}:{number}: dated status claim")
    return issues


def broken_doc_link_issues(paths):
    issues = []
    for path in paths:
        if path.suffix != ".md" or not path.is_file():
            continue
        for link in DOC_LINK.findall(path.read_text(errors="replace")):
            if "://" in link:
                continue
            target = (
                (ROOT / link).resolve()
                if link.startswith("device/")
                else (path.parent / link).resolve()
            )
            if not target.exists():
                issues.append(f"{path.relative_to(ROOT)}: missing document {link}")
    return issues


def lint_issues(paths):
    commands = (
        (
            "shellcheck",
            "shellcheck",
            ["-x", "-P", str(ROOT / "device/fedora-laptop/scripts")],
            ".sh",
        ),
        ("ruff", "ruff", ["check"], ".py"),
        ("shfmt", "shfmt", ["-d", "-i", "4", "-ci"], ".sh"),
    )
    issues = []
    for tool, binary, arguments, suffix in commands:
        files = [
            str(path)
            for path in paths
            if path.suffix == suffix
            and "fedora-laptop" in path.parts
            and "scripts" in path.parts
        ]
        if not files:
            continue
        executable = shutil.which(tool)
        runner = [executable] if executable else None
        if not runner:
            toolbox = shutil.which("toolbox")
            if toolbox:
                runner = [toolbox, "run", "-c", "fedora-toolbox-44", binary]
        if not runner:
            issues.append(f"{tool} unavailable; install it to enable this check")
            continue
        result = subprocess.run(
            [*runner, *arguments, *files],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode:
            issues.extend(
                line for line in (result.stdout + result.stderr).splitlines() if line
            )
    return issues


def main():
    paths = tracked_paths()
    paths.extend(
        path
        for path in ROOT.rglob("*.py")
        if not any(part in IGNORED_PARTS for part in path.parts)
    )
    paths.extend(
        path
        for path in ROOT.rglob("*.sh")
        if not any(part in IGNORED_PARTS for part in path.parts)
    )
    selected = [path for path in paths if "fedora-laptop" in path.parts]
    checks = {
        "lint": lint_issues(selected),
        "new code comments": new_code_comment_issues(selected),
    }
    warnings = {
        "existing code comments to migrate": code_comment_issues(selected),
        "dated status claims": current_claim_issues(selected),
        "broken Markdown links to review": broken_doc_link_issues(selected),
    }
    checks["tests"] = []
    for test in sorted(ROOT.rglob("test_*.py")) + sorted(ROOT.rglob("test-*.py")):
        if any(part in IGNORED_PARTS for part in test.parts):
            continue
        result = subprocess.run(
            [sys.executable, "-m", "unittest", str(test.relative_to(ROOT))],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode:
            checks["tests"].append((result.stdout + result.stderr).strip())
    failures = 0
    for name, issues in checks.items():
        print(f"{'FAIL' if issues else 'PASS'} {name}")
        for issue in issues:
            print(f"  {issue}")
        failures += len(issues)
    for name, issues in warnings.items():
        print(f"INFO {name}: {len(issues)}")
        for issue in issues:
            print(f"  {issue}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
