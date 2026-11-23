import importlib.util
import pathlib
import tempfile
import unittest

AUDIT_PATH = pathlib.Path(__file__).parents[1] / "scripts" / "audit.py"
SPEC = importlib.util.spec_from_file_location("repo_audit", AUDIT_PATH)
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class Workspace:
    def __init__(self, test):
        self.directory = tempfile.TemporaryDirectory()
        test.addCleanup(self.directory.cleanup)
        self.root = pathlib.Path(self.directory.name).resolve()
        self.original = AUDIT.ROOT
        AUDIT.ROOT = self.root
        test.addCleanup(setattr, AUDIT, "ROOT", self.original)

    def write(self, relative, text=""):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path


class ProseTests(unittest.TestCase):
    def test_python_comments_and_docstrings_are_found_but_shebang_is_not(self):
        text = '#!/usr/bin/env python3\n"""doc"""\n# note\n\ndef f():\n    """doc"""\n    return "# not a comment"\n'
        self.assertEqual(
            AUDIT.python_prose(text),
            [(2, "docstring"), (3, "comment"), (6, "docstring")],
        )

    def test_clean_python_has_no_findings(self):
        self.assertEqual(AUDIT.python_prose("x = 1\n"), [])

    def test_shell_comments_are_found_but_shebang_is_not(self):
        self.assertEqual(
            AUDIT.shell_prose("#!/bin/bash\n# why\necho hi\n"), [(2, "comment")]
        )

    def test_whole_files_are_checked_not_only_new_lines(self):
        workspace = Workspace(self)
        path = workspace.write("scripts/old.py", "# old\n")
        self.assertEqual(len(AUDIT.prose_issues([path])), 1)


class OrphanTests(unittest.TestCase):
    def test_unused_module_data_and_document_are_reported(self):
        workspace = Workspace(self)
        base = "device/fedora-laptop"
        workspace.write(f"{base}/laptop/__init__.py")
        workspace.write(f"{base}/laptop/used.py", "VALUE = 1\n")
        workspace.write(f"{base}/laptop/lonely.py", "VALUE = 2\n")
        workspace.write(f"{base}/laptop/cli.py", 'from . import used\nload("kept")\n')
        workspace.write(f"{base}/declared/kept.json", "{}")
        workspace.write(f"{base}/declared/dead.json", "{}")
        workspace.write(f"{base}/README.md", "[a](docs/linked.md)\n")
        workspace.write(f"{base}/docs/linked.md")
        workspace.write(f"{base}/docs/stray.md")
        issues = "\n".join(AUDIT.orphan_issues())
        self.assertIn("lonely.py: module is never imported", issues)
        self.assertIn("dead.json: declared data is never loaded", issues)
        self.assertIn("stray.md: document is not linked", issues)
        self.assertNotIn("used.py", issues)
        self.assertNotIn("kept.json", issues)
        self.assertNotIn("linked.md", issues)


class DocTests(unittest.TestCase):
    def test_freshness_links_and_backtick_paths(self):
        workspace = Workspace(self)
        workspace.write("device/real.md")
        source = workspace.write(
            "README.md",
            "Last verified: 2026-01-01\n[gone](missing.md)\n"
            "`device/real.md` `device/gone.md` `device/<role>/x`\n",
        )
        issues = AUDIT.doc_issues([source])
        self.assertEqual(len(issues), 3)
        self.assertTrue(any("missing path device/gone.md" in i for i in issues))

    def test_any_date_in_prose_is_a_dated_statement(self):
        workspace = Workspace(self)
        source = workspace.write(
            "README.md",
            "On 2026-10-08 the host was updated.\nUpdated 16 Nov 2026.\n"
            "| Security patch | 2026-02-01 |\n```\n2026-01-01\n```\nNo date here.\n",
        )
        issues = AUDIT.doc_issues([source])
        self.assertEqual(len(issues), 2)
        self.assertTrue(all("dated statement" in issue for issue in issues))

    def test_removed_script_paths_are_reported_and_relative_paths_resolve(self):
        workspace = Workspace(self)
        workspace.write("device/fedora-laptop/declared/apps.json", "{}")
        workspace.write("scripts/audit.py")
        source = workspace.write(
            "device/fedora-laptop/lessons.md",
            "`scripts/update-system.sh` `declared/apps.json` `scripts/audit.py`\n",
        )
        issues = AUDIT.doc_issues([source])
        self.assertEqual(len(issues), 1)
        self.assertIn("missing path scripts/update-system.sh", issues[0])

    def test_links_inside_code_fences_are_examples_not_references(self):
        workspace = Workspace(self)
        source = workspace.write("README.md", "```\n[x](nowhere.md)\n```\n")
        self.assertEqual(AUDIT.doc_issues([source]), [])

    def test_device_index_relative_links_are_checked(self):
        workspace = Workspace(self)
        source = workspace.write("device/README.md", "[phone apps](phone/apps/)\n")
        self.assertEqual(len(AUDIT.doc_issues([source])), 1)


class LintTests(unittest.TestCase):
    def test_a_missing_tool_is_a_failure_not_a_skip(self):
        original = AUDIT.tool_command
        AUDIT.tool_command = lambda tool, arguments: None
        self.addCleanup(setattr, AUDIT, "tool_command", original)
        issues = AUDIT.lint_issues([], [pathlib.Path("x.py")])
        self.assertTrue(issues)
        self.assertTrue(all("make setup-dev" in issue for issue in issues))

    def test_no_files_means_no_tool_is_needed(self):
        original = AUDIT.tool_command
        AUDIT.tool_command = lambda tool, arguments: None
        self.addCleanup(setattr, AUDIT, "tool_command", original)
        self.assertEqual(AUDIT.lint_issues([], []), [])


if __name__ == "__main__":
    unittest.main()
