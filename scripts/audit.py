import ast
import io
import pathlib
import re
import shutil
import subprocess
import sys
import tokenize

ROOT = pathlib.Path(__file__).resolve().parents[1]
FEDORA = pathlib.Path("device/fedora-laptop")
IGNORED_PARTS = {".git", ".opencode", ".venv", "__pycache__"}
SHELL_COMMENT = re.compile(r"^\s*#(?!!)")
DOC_LINK = re.compile(r"\[[^]]+\]\(([^)]+)(?:#[^)]+)?\)")
BACKTICK_PATH = re.compile(r"`((?:device|notes|inbox|outbox)/[^`\s]*)`")
PLACEHOLDER = re.compile(r"[<>*{}\[\]…]")
FRESHNESS = re.compile(
    r"last verified|last checked|verified on|as of|last updated|current host|host queried",
    re.IGNORECASE,
)
DATE = re.compile(r"\b20\d{2}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])\b")
PYTHON_AREAS = (
    "scripts",
    "tests",
    "device/fedora-laptop/laptop",
    "device/fedora-laptop/tests",
)
TEST_SUITES = (".", "device/fedora-laptop")


def run(command, cwd=None):
    return subprocess.run(
        command, cwd=cwd or ROOT, text=True, capture_output=True, check=False
    )


def source_paths(pattern):
    return sorted(
        path
        for path in ROOT.rglob(pattern)
        if path.is_file() and not IGNORED_PARTS & set(path.relative_to(ROOT).parts)
    )


def in_area(path, areas):
    relative = path.relative_to(ROOT).as_posix()
    return any(relative.startswith(area + "/") for area in areas)


def python_files():
    return [path for path in source_paths("*.py") if in_area(path, PYTHON_AREAS)]


def shell_files():
    return [path for path in source_paths("*.sh") if "scripts" in path.parts]


def python_prose(text):
    lines = []
    for token in tokenize.generate_tokens(io.StringIO(text).readline):
        if token.type == tokenize.COMMENT and not token.string.startswith("#!"):
            lines.append((token.start[0], "comment"))
    for node in ast.walk(ast.parse(text)):
        if isinstance(
            node, ast.Module | ast.ClassDef | ast.FunctionDef | ast.AsyncFunctionDef
        ):
            body = node.body
            first = body[0] if body else None
            if (
                isinstance(first, ast.Expr)
                and isinstance(first.value, ast.Constant)
                and isinstance(first.value.value, str)
            ):
                lines.append((first.lineno, "docstring"))
    return sorted(lines)


def shell_prose(text):
    return [
        (number, "comment")
        for number, line in enumerate(text.splitlines(), 1)
        if SHELL_COMMENT.match(line)
    ]


def prose_issues(paths):
    issues = []
    for path in paths:
        text = path.read_text(errors="replace")
        found = python_prose(text) if path.suffix == ".py" else shell_prose(text)
        issues.extend(f"{path}:{number}: code {kind}" for number, kind in found)
    return issues


def orphan_issues():
    issues = []
    package = ROOT / FEDORA / "laptop"
    modules = sorted(package.glob("*.py")) if package.is_dir() else []
    texts = {path: path.read_text(encoding="utf-8") for path in modules}
    for path in modules:
        if path.stem in {"__init__", "__main__"}:
            continue
        pattern = re.compile(rf"\b{re.escape(path.stem)}\b")
        if not any(
            pattern.search(text) for other, text in texts.items() if other != path
        ):
            issues.append(f"{path}: module is never imported")
    declared = ROOT / FEDORA / "declared"
    for path in sorted(declared.glob("*.json")) if declared.is_dir() else []:
        needle = f'load("{path.stem}")'
        if not any(needle in text for text in texts.values()):
            issues.append(f"{path}: declared data is never loaded")
    docs = [p for p in source_paths("*.md") if in_area(p, ("device/fedora-laptop",))]
    for path in docs:
        if path.name == "README.md":
            continue
        if not any(
            path.name in other.read_text(encoding="utf-8")
            for other in docs
            if other != path
        ):
            issues.append(f"{path}: document is not linked from any other document")
    return issues


def doc_issues(paths):
    issues = []
    for path in paths:
        for number, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
            if FRESHNESS.search(line) and DATE.search(line):
                issues.append(f"{path}:{number}: dated freshness claim")
            for target in DOC_LINK.findall(line):
                if "://" in target:
                    continue
                file_target = target.partition("#")[0] or path.name
                base = ROOT if file_target.startswith("device/") else path.parent
                if not (base / file_target).resolve().exists():
                    issues.append(f"{path}:{number}: missing document {target}")
            for claim in BACKTICK_PATH.findall(line):
                if not PLACEHOLDER.search(claim) and not (ROOT / claim).exists():
                    issues.append(f"{path}:{number}: missing path {claim}")
    return issues


def doc_paths():
    scoped = {
        ROOT / name for name in ("README.md", "CONTEXT.md", "AGENTS.md", "STYLE.md")
    }
    scoped |= {ROOT / "device/README.md", ROOT / "device/phone/README.md"}
    return [
        path
        for path in source_paths("*.md")
        if path in scoped or in_area(path, ("device/fedora-laptop",))
    ]


def tool_command(tool, arguments):
    executable = shutil.which(tool)
    local = ROOT / ".venv/bin" / tool
    if executable:
        return [executable, *arguments]
    if local.exists():
        return [str(local), *arguments]
    return None


def lint_issues(shell, python):
    issues = []
    checks = (
        ("shellcheck", ["-x"], shell),
        ("shfmt", ["-d", "-i", "4", "-ci"], shell),
        ("ruff", ["check"], python),
        ("ruff", ["format", "--check"], python),
    )
    for tool, arguments, files in checks:
        if not files:
            continue
        command = tool_command(tool, [*arguments, *map(str, files)])
        if command is None:
            print(f"INFO {tool} unavailable; skipped")
            continue
        result = run(command)
        if result.returncode:
            issues.extend((result.stdout + result.stderr).splitlines())
    return issues


def test_issues():
    issues = []
    for suite in (".", "device/fedora-laptop"):
        directory = ROOT / suite
        if not (directory / "tests").is_dir():
            continue
        result = run(
            [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-t", "."],
            cwd=directory,
        )
        if result.returncode:
            issues.append((result.stdout + result.stderr).strip())
    return issues


def live_inventory_issues():
    directory = ROOT / FEDORA
    result = run([sys.executable, "-m", "laptop", "capture", "--check"], cwd=directory)
    issues = [] if result.returncode == 0 else (result.stdout + result.stderr).splitlines()
    release = run(["rpm", "-E", "%fedora"])
    if release.returncode:
        return issues
    phone_serial = run(
        [
            "toolbox",
            "run",
            "--container",
            f"fedora-toolbox-{release.stdout.strip()}",
            "adb",
            "devices",
        ]
    )
    personal_serials = [
        line.split()[0]
        for line in phone_serial.stdout.splitlines()[1:]
        if len(line.split()) > 1
        and line.split()[1] == "device"
        and "model:2201117TI" in line
    ]
    if phone_serial.returncode == 0 and len(personal_serials) == 1:
        phone_result = run(
            [
                sys.executable,
                "-m",
                "laptop",
                "phone",
                "personal",
                personal_serials[0],
                "--check",
            ],
            cwd=directory,
        )
        if phone_result.returncode:
            issues.extend((phone_result.stdout + phone_result.stderr).splitlines())
    return issues


def syntax_issues(shell_files):
    issues = []
    for path in shell_files:
        result = run(["bash", "-n", str(path)])
        if result.returncode:
            issues.append((result.stdout + result.stderr).strip())
    return issues


def main():
    shell = shell_files()
    python = python_files()
    checks = {
        "lint": lint_issues(shell, python),
        "shell syntax": syntax_issues(shell),
        "tests": test_issues(),
        "code comments and docstrings": prose_issues([*python, *shell]),
        "orphans": orphan_issues(),
        "documentation": doc_issues(doc_paths()),
        "live inventory": live_inventory_issues(),
    }
    failed = False
    for name, issues in checks.items():
        print(f"{'FAIL' if issues else 'PASS'} {name}")
        for issue in issues:
            print(f"  {issue}")
        failed |= bool(issues)
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
