import hashlib
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

    def test_phone_capture_check_mode_does_not_write(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            bindir = root / "bin"
            bindir.mkdir()
            adb = bindir / "adb"
            adb.write_text(
                "#!/bin/sh\n"
                "if [ \"$1\" = devices ]; then printf 'List of devices attached\\nSERIAL device\\n'; exit; fi\n"
                'if [ "$1" = -s ]; then shift 2; fi\n'
                'if [ "$1" = shell ]; then shift; fi\n'
                'case "$1" in\n'
                ' getprop) case "$2" in ro.product.device) echo spes;; ro.product.model) echo 2201117TI;; ro.product.name) echo spes_in;; ro.build.version.release) echo 13;; ro.build.version.sdk) echo 33;; ro.build.display.id) echo V816;; ro.build.fingerprint) echo fingerprint;; ro.build.version.security_patch) echo 2025-02-01;; ro.miui.ui.version.name) echo V816;; ro.boot.vbmeta.device_state) echo locked;; ro.boot.verifiedbootstate) echo green;; esac;;\n'
                " cat) echo MemTotal: 6000000 kB;;\n"
                " pm) printf 'package:one\\npackage:two\\n';;\n"
                "esac\n"
            )
            adb.chmod(0o755)
            phone_dir = AUDIT.ROOT / "device/phone"
            script = phone_dir / "scripts/capture-phone.sh"
            target = phone_dir / "personal"
            before = {
                path.relative_to(target): hashlib.sha256(path.read_bytes()).hexdigest()
                for path in target.rglob("*")
                if path.is_file()
            }
            result = subprocess.run(
                ["bash", str(script), "personal", "SERIAL", "--check"],
                env={**os.environ, "PATH": f"{bindir}:/usr/bin:/bin"},
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Check only", result.stdout)
            after = {
                path.relative_to(target): hashlib.sha256(path.read_bytes()).hexdigest()
                for path in target.rglob("*")
                if path.is_file()
            }
            self.assertEqual(after, before)


if __name__ == "__main__":
    unittest.main()
