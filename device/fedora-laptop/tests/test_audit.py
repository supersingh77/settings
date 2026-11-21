import importlib.util
import os
import pathlib
import subprocess
import tempfile
import unittest

AUDIT_PATH = pathlib.Path(__file__).parents[3] / "scripts" / "audit.py"
SPEC = importlib.util.spec_from_file_location("repo_audit", AUDIT_PATH)
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class AuditTests(unittest.TestCase):
    def test_comment_scanner_allows_shebang_only(self):
        with tempfile.TemporaryDirectory() as directory:
            script = pathlib.Path(directory) / "example.py"
            script.write_text("#!/usr/bin/env python3\n# no\n")
            original_root = AUDIT.ROOT
            AUDIT.ROOT = pathlib.Path(directory)
            try:
                self.assertEqual(len(AUDIT.comment_issues([script])), 1)
            finally:
                AUDIT.ROOT = original_root

    def test_freshness_and_relative_markdown_links_are_detected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            source = root / "README.md"
            source.write_text("Last verified: 2026-01-01\n[missing](missing.md)\n")
            original_root = AUDIT.ROOT
            AUDIT.ROOT = root
            try:
                issues = AUDIT.doc_issues([source])
            finally:
                AUDIT.ROOT = original_root
            self.assertEqual(len(issues), 2)

    def test_device_index_relative_links_are_checked(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            source = root / "device" / "README.md"
            source.parent.mkdir()
            source.write_text("[phone apps](phone/apps/)\n")
            original_root = AUDIT.ROOT
            AUDIT.ROOT = root
            try:
                issues = AUDIT.doc_issues([source])
            finally:
                AUDIT.ROOT = original_root
            self.assertEqual(len(issues), 1)

    def test_user_setup_check_mode_does_not_write(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            bindir = root / "bin"
            home = root / "home"
            bindir.mkdir()
            home.mkdir()
            trace = root / "writes.log"
            for name, body in {
                "id": "#!/bin/sh\necho 1000\n",
                "rpm": "#!/bin/sh\necho 44\n",
            }.items():
                path = bindir / name
                path.write_text(body)
                path.chmod(0o755)
            result = subprocess.run(
                [
                    "bash",
                    str(AUDIT.ROOT / "device/fedora-laptop/scripts/setup-user.sh"),
                    "--check",
                ],
                env={
                    **os.environ,
                    "PATH": f"{bindir}:/usr/bin:/bin",
                    "HOME": str(home),
                    "TRACE": str(trace),
                },
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse((home / ".bashrc").exists())
            self.assertFalse(trace.exists())


if __name__ == "__main__":
    unittest.main()
