import unittest

from laptop.plan import plan_restore, unsafe_names
from tests.test_render import SOFTWARE


def variant(**changes):
    return type(SOFTWARE)(**{**SOFTWARE.__dict__, **changes})


class PlanTests(unittest.TestCase):
    def test_identical_state_needs_nothing(self):
        self.assertEqual(plan_restore(SOFTWARE, SOFTWARE, "44"), [])

    def test_versions_are_ignored(self):
        have = variant(
            deployment="44.2",
            toolbox_packages=(("gh", "9.9"), ("7zip", "")),
            apps=(("openwork", "9"),),
        )
        self.assertEqual(plan_restore(SOFTWARE, have, "44"), [])

    def test_extra_layer_is_removed_and_missing_one_installed(self):
        have = variant(layers=("distrobox", "extra"))
        argvs = [s.argv for s in plan_restore(SOFTWARE, have, "44")]
        self.assertIn(("rpm-ostree", "install", "--idempotent", "ghostty"), argvs)
        self.assertIn(("rpm-ostree", "uninstall", "--idempotent", "extra"), argvs)

    def test_base_removals_are_overridden_or_reset(self):
        have = variant(removals=("gnome-software",))
        argvs = [s.argv for s in plan_restore(SOFTWARE, have, "44")]
        self.assertIn(("rpm-ostree", "override", "remove", "firefox"), argvs)
        self.assertIn(("rpm-ostree", "override", "reset", "gnome-software"), argvs)

    def test_copr_is_added_with_release_specific_url(self):
        steps = plan_restore(SOFTWARE, variant(copr=()), "45")
        argv = steps[0].argv
        self.assertEqual(argv[:4], ("sudo", "curl", "-fsSL", "-o"))
        self.assertIn("alternateved/ghostty/repo/fedora-45/", argv[5])

    def test_flatpaks_install_from_recorded_origin(self):
        steps = plan_restore(SOFTWARE, variant(flatpaks=()), "44")
        self.assertEqual(
            steps[0].argv,
            ("flatpak", "install", "--system", "-y", "flathub", "org.gnome.Calculator"),
        )

    def test_missing_toolbox_is_created_then_packages_installed(self):
        have = variant(toolbox="", toolbox_packages=(("gh", ""), ("7zip", "")))
        labels = [s.label for s in plan_restore(SOFTWARE, have, "44")]
        self.assertEqual(labels[0], "create toolbox fedora-toolbox-44")
        self.assertEqual(labels[1], "toolbox install gh")

    def test_apps_follow_the_snapshot(self):
        have = variant(apps=(("uad-ng", "1"),))
        kinds = [(s.kind, s.name) for s in plan_restore(SOFTWARE, have, "44")]
        self.assertEqual(kinds, [("app-install", "openwork"), ("app-remove", "uad-ng")])

    def test_option_like_names_are_rejected(self):
        self.assertEqual(unsafe_names(variant(layers=("--force",))), ("--force",))
        self.assertEqual(unsafe_names(SOFTWARE), ())
