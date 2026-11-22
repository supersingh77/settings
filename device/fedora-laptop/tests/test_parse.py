import json
import unittest

from laptop import parse
from tests import support


class ParseTests(unittest.TestCase):
    def test_cpuinfo(self):
        self.assertEqual(
            parse.parse_cpuinfo(support.CPUINFO),
            ("AMD Ryzen 5 2500U with Radeon Vega Mobile Gfx", 4, 8),
        )
        with self.assertRaises(ValueError):
            parse.parse_cpuinfo("")

    def test_meminfo_rounds_to_gib(self):
        self.assertEqual(parse.parse_meminfo_gib("MemTotal:  10485760 kB\n"), 10)

    def test_lsblk_flattens_children_and_skips_zram(self):
        rows = parse.parse_lsblk(support.LSBLK)
        self.assertEqual([row[0] for row in rows], ["nvme0n1", "nvme0n1p3"])
        self.assertEqual(rows[1][4:], ("btrfs", "fedora", "/, /var"))

    def test_rpm_ostree_prefers_staged_requests(self):
        text = json.dumps(
            {
                "deployments": [
                    {
                        "staged": True,
                        "requested-packages": ["b", "a"],
                        "requested-base-removals": [],
                    },
                    {
                        "booted": True,
                        "version": "44.1",
                        "requested-packages": ["a"],
                        "requested-base-removals": ["firefox"],
                    },
                ]
            }
        )
        self.assertEqual(parse.parse_rpm_ostree(text), ("44.1", ("a", "b"), ()))
        self.assertTrue(parse.has_staged_deployment(text))
        self.assertFalse(parse.has_staged_deployment(support.OSTREE))

    def test_rpm_ostree_rejects_an_unrecognized_state_shape(self):
        with self.assertRaisesRegex(ValueError, "missing requested state"):
            parse.parse_rpm_ostree(
                '{"deployments":[{"booted":true,"version":"44.1"}]}'
            )

    def test_flatpaks_ignore_headers_and_keep_empty_versions(self):
        text = "Application ID\tVersion\tBranch\tOrigin\n" + support.FLATPAKS
        rows = parse.parse_flatpaks(text)
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0], ("org.gnome.Calculator", "", "stable", "flathub"))

    def test_flatpaks_reject_an_unrecognized_output_format(self):
        with self.assertRaisesRegex(ValueError, "unrecognized Flatpak inventory row"):
            parse.parse_flatpaks("Application ID Version Branch Origin\n")

    def test_rpm_versions_mark_missing(self):
        text = "gh\t2.60-1\npackage x is not installed\n"
        self.assertEqual(
            parse.parse_rpm_versions(text, ["gh", "x"]), (("gh", "2.60-1"), ("x", ""))
        )

    def test_key_values_ignore_comments_and_sections(self):
        text = "[UPower]\n#IgnoreLid=true\nIgnoreLid = false\n"
        self.assertEqual(
            parse.parse_key_values(text, ["IgnoreLid", "Other"]),
            (("IgnoreLid", "false"), ("Other", "unset")),
        )

    def test_fstab_skips_comments(self):
        text = "# c\nUUID=1 /data btrfs defaults 0 0\n"
        self.assertEqual(
            parse.parse_fstab(text), (("/data", "UUID=1", "btrfs", "defaults"),)
        )

    def test_copr_names_support_both_file_layouts(self):
        names = [
            "_copr:copr.fedorainfracloud.org:alternateved:ghostty.repo",
            "_copr:owner:project.repo",
            "fedora.repo",
        ]
        self.assertEqual(
            parse.parse_copr_names(names), ("alternateved/ghostty", "owner/project")
        )

    def test_adb_devices_and_getprop(self):
        text = "List of devices attached\nSERIAL\tdevice\nOTHER\tunauthorized\n"
        self.assertEqual(
            parse.parse_adb_devices(text),
            (("SERIAL", "device"), ("OTHER", "unauthorized")),
        )
        props = parse.parse_getprop("[ro.a]: [1]\r\n[ro.b]: []\n")
        self.assertEqual(props, {"ro.a": "1", "ro.b": ""})
