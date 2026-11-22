import importlib.util
import pathlib
import unittest
from unittest.mock import patch

SCRIPT = pathlib.Path(__file__).parents[1] / "scripts" / "check-phone-inventory.py"
SPEC = importlib.util.spec_from_file_location("check_phone_inventory", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class PhoneInventoryTests(unittest.TestCase):
    def test_package_lists_are_sorted_and_deduplicated_by_call_source(self):
        output = "package:z.app\npackage:a.app\npackage:z.app\n"
        packages = sorted({
            line.removeprefix("package:").strip()
            for line in output.splitlines()
            if line.startswith("package:")
        })
        self.assertEqual(packages, ["a.app", "z.app"])

    def test_ram_converts_kibibytes_to_gibibytes(self):
        with patch.object(MODULE, "adb", return_value="MemTotal: 5767168 kB\n"):
            self.assertEqual(MODULE.ram_visible([], "serial"), "5.5 GiB")

    def test_section_replacement_preserves_following_prose(self):
        document = "# Phone\n\n## Device state\n\nold\n\n## Notes\n\nKeep this.\n"
        proposed = MODULE.replace_section(
            document,
            "Device state",
            MODULE.property_table("Device state", {"Android": "13"}),
        )
        self.assertIn("| Android | 13 |", proposed)
        self.assertIn("## Notes\n\nKeep this.", proposed)
        self.assertEqual(document, "# Phone\n\n## Device state\n\nold\n\n## Notes\n\nKeep this.\n")

    def test_diff_is_repeatable(self):
        first = MODULE.unified_diff("personal/README.md", "# Phone\n", "# Phone\n\n## State\n")
        second = MODULE.unified_diff("personal/README.md", "# Phone\n", "# Phone\n\n## State\n")
        self.assertEqual(first, second)


if __name__ == "__main__":
    unittest.main()
