import unittest

from laptop import tables
from laptop.model import Software
from laptop.render import parse_software, render_software

SOFTWARE = Software(
    os_name="Fedora Linux 44 (Silverblue)",
    deployment="44.1",
    kernel="7.2.9",
    toolbox="fedora-toolbox-44",
    layers=("distrobox", "ghostty"),
    removals=("firefox",),
    copr=("alternateved/ghostty",),
    flatpaks=(("org.gnome.Calculator", "", "stable", "flathub"),),
    toolbox_packages=(("gh", "2.60-1"), ("7zip", "")),
    apps=(("openwork", "1.2.3"),),
)


class TableTests(unittest.TestCase):
    def test_rejects_cells_that_would_break_the_table(self):
        with self.assertRaises(ValueError):
            tables.cell("a|b")

    def test_sections_round_trip_with_empty_cells(self):
        text = "\n".join(tables.section("S", ("a", "b"), [("x", ""), ("y", "z")]))
        self.assertEqual(
            tables.parse_sections(text)["S"],
            [{"a": "x", "b": ""}, {"a": "y", "b": "z"}],
        )


class SoftwareRenderTests(unittest.TestCase):
    def test_render_then_parse_is_identity(self):
        parsed = parse_software(render_software(SOFTWARE))
        self.assertEqual(parsed.layers, SOFTWARE.layers)
        self.assertEqual(parsed.flatpaks, SOFTWARE.flatpaks)
        self.assertEqual(parsed.toolbox_packages, SOFTWARE.toolbox_packages)
        self.assertEqual(parsed, SOFTWARE)

    def test_absent_toolbox_round_trips(self):
        absent = Software(**{**SOFTWARE.__dict__, "toolbox": ""})
        self.assertEqual(parse_software(render_software(absent)).toolbox, "")

    def test_render_is_deterministic(self):
        self.assertEqual(render_software(SOFTWARE), render_software(SOFTWARE))
