import importlib.util
import pathlib
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


if __name__ == "__main__":
    unittest.main()
