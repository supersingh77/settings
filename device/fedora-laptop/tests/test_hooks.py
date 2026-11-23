import unittest
from pathlib import Path

from laptop import hooks


class BashrcHookTests(unittest.TestCase):
    def test_accepts_a_path_and_quotes_embedded_apostrophes(self):
        hook = hooks.bashrc_hook(Path("/home/o'neil/settings"))
        self.assertIn("export SETTINGS_ROOT='/home/o'\\''neil/settings'", hook)

    def test_hook_is_idempotent_and_follows_a_moved_repository(self):
        once = hooks.with_bashrc_hook("alias a=b\n", Path("/one"))
        self.assertEqual(hooks.with_bashrc_hook(once, Path("/one")), once)
        moved = hooks.with_bashrc_hook(once, Path("/two"))
        self.assertIn("SETTINGS_ROOT='/two'", moved)
        self.assertNotIn("/one", moved)
        self.assertEqual(moved.count(hooks.MARKER), once.count(hooks.MARKER))


if __name__ == "__main__":
    unittest.main()
