import importlib.util
import pathlib
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = pathlib.Path(__file__).parents[3]
DEVICE = ROOT / "device/fedora-laptop"
sys.path.insert(0, str(DEVICE / "lib"))
import inventory_docs as DOCS

SCRIPT = DEVICE / "scripts" / "update-inventory.py"
SPEC = importlib.util.spec_from_file_location("update_inventory", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class InventoryTests(unittest.TestCase):
    def test_detected_hardware_comes_from_live_interfaces(self):
        command_results = [
            '{"lscpu":[{"field":"Model name:","data":"Example CPU"},{"field":"Core(s) per socket:","data":"4"},{"field":"CPU(s):","data":"8"}]}',
            '{"blockdevices":[{"name":"sda","model":"Example disk","size":1000000000,"type":"disk","children":[]}]}',
            "00:00.0 Network controller: Example Wi-Fi\n00:01.0 VGA compatible controller: Example Graphics\n",
        ]

        def command_output(command):
            if command[:2] == ["lscpu", "--json"]:
                return command_results[0]
            if command[0] == "lsblk":
                return command_results[1]
            return command_results[2]

        def proc_text(path):
            values = {
                "/proc/meminfo": "MemTotal: 10485760 kB\nSwapTotal: 8388608 kB\n",
                "/etc/os-release": 'ID=fedora\nPRETTY_NAME="Fedora Linux"\nOSTREE_VERSION=44.1\n',
                "/sys/class/dmi/id/sys_vendor": "ASUS",
                "/sys/class/dmi/id/product_name": "Laptop",
                "/sys/class/dmi/id/bios_version": "BIOS1",
                "/sys/class/dmi/id/bios_date": "2026-01-01",
            }
            return values[str(path)]

        with (
            patch.object(MODULE, "run", side_effect=command_output),
            patch.object(MODULE.pathlib.Path, "read_text", autospec=True, side_effect=lambda self: proc_text(self)),
            patch.object(MODULE, "read_text", side_effect=lambda path: {
                "/sys/class/power_supply/BAT0/type": "Battery",
                "/sys/class/power_supply/BAT0/status": "Charging",
                "/sys/class/power_supply/BAT0/capacity": "0",
                "/sys/class/power_supply/BAT0/energy_full": None,
                "/sys/class/power_supply/BAT0/energy_full_design": "42157000",
            }.get(str(path))),
            patch.object(MODULE.pathlib.Path, "glob", return_value=[pathlib.Path("/sys/class/power_supply/BAT0")]),
        ):
            observed = MODULE.detect_hardware()
        self.assertEqual(observed["cpu"], "Example CPU")
        self.assertEqual(observed["memory"], "10.0 GiB")
        self.assertEqual(observed["network"], ["Example Wi-Fi"])
        self.assertEqual(observed["graphics"], ["Example Graphics"])

    def test_detected_software_uses_live_package_managers(self):
        outputs = {
            "rpm-ostree": '{"deployments":[{"booted":true,"version":"44.1","packages":["ghostty"],"requested-base-removals":["firefox"]}]}',
            "flatpak": "org.example.App\t1.0\tflathub\n",
            "toolbox": "CONTAINER ID  CONTAINER NAME\n123  fedora-toolbox-44\n",
            "gsettings": "['org.example.App.desktop']",
        }

        def command_output(command):
            executable = command[0]
            if executable == "rpm-ostree":
                return outputs[executable]
            if executable == "flatpak":
                return outputs[executable]
            if executable == "gsettings":
                return outputs[executable]
            if command[:2] == ["toolbox", "list"]:
                return outputs["toolbox"]
            raise AssertionError(command)

        with (
            patch.object(MODULE, "run", side_effect=command_output),
            patch.object(MODULE.pathlib.Path, "home", return_value=pathlib.Path("/missing-home")),
        ):
            observed = MODULE.detect_software()
        self.assertEqual(observed["host"]["packages"], ["ghostty"])
        self.assertEqual(observed["host"]["base_removals"], ["firefox"])
        self.assertIn("org.example.App", observed["flatpaks"])
        self.assertIn("fedora-toolbox-44", observed["toolboxes"])
        self.assertEqual(observed["favorites"], ["org.example.App.desktop"])

    def test_proposal_replaces_inventory_without_mutating_input(self):
        original = "# Hardware\n\n## Detected system\n\nold\n\n## Caveats\n\nKeep this.\n"
        data = {
            "model": "New laptop",
            "os": "Fedora",
            "cpu": "Example CPU",
            "cpu_cores_threads": "4 cores / 8 threads",
            "memory": "8.0 GiB",
            "swap": "4.0 GiB",
            "disks": [],
            "graphics": [],
            "network": [],
            "firmware": "BIOS 1",
        }
        proposed = DOCS.replace_section(original, "Detected system", DOCS.hardware_sections(data))
        self.assertIn("| Model | New laptop |", proposed)
        self.assertIn("## Caveats\n\nKeep this.", proposed)
        self.assertEqual(original, "# Hardware\n\n## Detected system\n\nold\n\n## Caveats\n\nKeep this.\n")

    def test_proposed_documents_preserve_non_inventory_content(self):
        hardware = {
            "model": "New laptop",
            "os": "Fedora",
            "cpu": "Example CPU",
            "cpu_cores_threads": "4 cores / 8 threads",
            "memory": "8.0 GiB",
            "swap": "4.0 GiB",
            "disks": [],
            "graphics": [],
            "network": [],
            "firmware": "BIOS 1",
        }
        software = {
            "host": {"version": "44.1", "packages": [], "base_removals": []},
            "flatpaks": "org.example.App\t1.0\tflathub",
            "toolboxes": "CONTAINER ID NAME\n123 fedora-toolbox-44",
            "favorites": ["org.example.App.desktop"],
            "user_local_apps": [],
        }
        documents = {
            "hardware": "# Hardware\n\n## Detected system\n\nold\n\n## Caveats\n\nKeep hardware note.\n",
            "software": "# Software\n\n## Detected software\n\nold\n\n## Caveats\n\nKeep software note.\n",
        }
        proposed = DOCS.proposed_documents(hardware, software, documents)
        self.assertIn("Keep hardware note.", proposed["hardware.md"])
        self.assertIn("Keep software note.", proposed["software.md"])
        self.assertIn("org.example.App", proposed["software.md"])
        self.assertIn("Favorite applications (GNOME Dash)", proposed["software.md"])
        self.assertIn("org.example.App.desktop", proposed["software.md"])

    def test_proposal_diff_is_repeatable(self):
        before = "# Inventory\n"
        after = "# Inventory\n\n## Detected system\n"
        first = DOCS.unified_diff("inventory.md", before, after)
        self.assertEqual(first, DOCS.unified_diff("inventory.md", before, after))

    def test_section_replacement_preserves_explanatory_prose(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "hardware.md"
            path.write_text(
                "## Detected system\n\n| Property | Value |\n|---|---|\n| Model | Laptop |\n\n"
                "## Caveats\n\n| Model | prose-only duplicate |\n"
            )
            document = path.read_text()
            proposal = DOCS.replace_section(
                document,
                "Detected system",
                DOCS.table("Detected system", ["Property", "Value"], ["| Model | Updated laptop |"]),
            )
            self.assertIn("| Model | Updated laptop |", proposal)
            self.assertIn("| Model | prose-only duplicate |", proposal)


if __name__ == "__main__":
    unittest.main()
