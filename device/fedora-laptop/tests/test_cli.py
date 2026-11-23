import tempfile
import unittest
from pathlib import Path

from laptop import apps, declared, hooks
from laptop.cli import main
from laptop.render import parse_software
from tests.support import FakeSystem


class CaptureTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.system = FakeSystem(self.tmp.name)
        self.env = self.system.env()

    def capture(self, *flags):
        return main(["capture", *flags], self.env)

    def test_capture_writes_both_snapshots(self):
        self.assertEqual(self.capture(), 0)
        hardware = (self.system.device_dir / "hardware.md").read_text()
        software = (self.system.device_dir / "software.md").read_text()
        self.assertIn("| Board | ASUSTeK COMPUTER INC. X505ZA |", hardware)
        self.assertIn("| CPU topology | 4C/8T |", hardware)
        self.assertIn("| Memory visible | 10 GiB |", hardware)
        self.assertIn("| zram | zram0 8 GiB |", hardware)
        self.assertIn("| wlan0 | wireless |", hardware)
        self.assertNotIn("podman0", hardware)
        self.assertIn("| /etc/UPower/UPower.conf | IgnoreLid | unset |", hardware)
        self.assertIn("| ghostty |", software)
        self.assertIn("| 7zip-standalone | not installed |", software)

    def test_capture_is_idempotent(self):
        self.capture()
        before = {p.name: p.read_text() for p in self.system.device_dir.glob("*.md")}
        self.system.output.clear()
        self.assertEqual(self.capture(), 0)
        self.assertEqual(self.system.output, ["0 changes"])
        after = {p.name: p.read_text() for p in self.system.device_dir.glob("*.md")}
        self.assertEqual(before, after)

    def test_check_reports_drift_without_writing(self):
        self.capture()
        self.system.flatpaks += "org.videolan.VLC\t3.0\tstable\tflathub\n"
        committed = (self.system.device_dir / "software.md").read_text()
        self.assertEqual(self.capture("--check"), 1)
        self.assertIn(
            "+| org.videolan.VLC | 3.0 | stable | flathub |", self.system.text
        )
        self.assertEqual(
            (self.system.device_dir / "software.md").read_text(), committed
        )

    def test_wrong_machine_is_refused_and_nothing_is_written(self):
        other = FakeSystem(self.tmp.name + "/other", board="B550")
        self.assertEqual(main(["capture"], other.env()), 2)
        self.assertIn("wrong machine", other.text)
        self.assertEqual(list(other.device_dir.iterdir()), [])

    def test_capture_handles_battery_capacity_unreported(self):
        (self.system.root / "sys/class/power_supply/BAT0/energy_full").unlink()
        self.assertEqual(self.capture(), 0)
        hardware = (self.system.device_dir / "hardware.md").read_text()
        self.assertIn("| Battery | BAT0 capacity unreported |", hardware)

    def test_failing_probe_command_aborts_capture(self):
        original = self.system.run

        def broken(argv, cwd=None):
            if argv[0] == "flatpak":
                from laptop.model import Result

                return Result(127, "", "flatpak: not found")
            return original(argv, cwd)

        self.system.run = broken
        self.assertEqual(main(["capture"], self.system.env()), 2)
        self.assertIn("flatpak", self.system.text)
        self.assertEqual(list(self.system.device_dir.iterdir()), [])

    def test_snapshot_round_trips_through_the_parser(self):
        self.capture()
        parsed = parse_software((self.system.device_dir / "software.md").read_text())
        self.assertEqual(parsed.layers, ("distrobox", "ghostty", "uhubctl"))
        self.assertEqual(parsed.copr, ("alternateved/ghostty",))
        self.assertEqual(parsed.toolbox, "fedora-toolbox-44")


class RestoreTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.system = FakeSystem(self.tmp.name)
        self.env = self.system.env()
        main(["capture"], self.env)
        self.system.output.clear()

    def test_matching_device_has_nothing_to_restore(self):
        self.assertEqual(main(["restore"], self.env), 0)
        self.assertEqual(self.system.output, ["0 changes"])
        self.assertEqual(self.system.live, [])

    def test_drift_is_reverted_on_the_device(self):
        self.system.flatpaks += "org.videolan.VLC\t3.0\tstable\tflathub\n"
        self.assertEqual(main(["restore"], self.env), 0)
        self.assertIn(
            ["flatpak", "uninstall", "--system", "-y", "org.videolan.VLC"],
            self.system.live,
        )

    def test_dry_run_runs_nothing(self):
        spec = declared.load("apps")["openwork"]
        relative = apps.version_path(spec, self.system.home).lstrip("/")
        version = self.system.root / relative
        version.parent.mkdir(parents=True, exist_ok=True)
        version.write_text("1.0.0\n")
        main(["capture"], self.env)
        version.unlink()
        self.system.output.clear()
        self.system.flatpaks = ""
        self.assertEqual(main(["restore", "--dry-run"], self.env), 0)
        self.assertEqual(self.system.live, [])
        self.assertIn(
            "flatpak install --system -y flathub org.gnome.Calculator", self.system.text
        )
        self.assertIn("install openwork from its declared release", self.system.text)

    def test_failed_step_is_reported_and_exit_is_non_zero(self):
        self.system.flatpaks = ""
        self.system.live_code = 1
        self.assertEqual(main(["restore"], self.env), 1)
        self.assertIn("steps failed", self.system.text)

    def test_missing_snapshot_is_an_error(self):
        (self.system.device_dir / "software.md").unlink()
        self.assertEqual(main(["restore"], self.env), 2)
        self.assertIn("make capture", self.system.text)

    def test_unsafe_names_in_snapshot_are_refused(self):
        path = self.system.device_dir / "software.md"
        path.write_text(path.read_text().replace("| ghostty |", "| --force |"))
        self.assertEqual(main(["restore"], self.env), 2)
        self.assertEqual(self.system.live, [])

    def test_restore_refuses_a_different_board(self):
        (self.system.root / "sys/class/dmi/id/board_name").write_text("B550\n")
        self.assertEqual(main(["restore"], self.env), 2)
        self.assertEqual(self.system.live, [])


class MaintenanceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.system = FakeSystem(self.tmp.name)

    def test_update_runs_every_declared_command_and_continues_after_failure(self):
        self.system.live_code = 1
        self.assertEqual(main(["update"], self.system.env()), 1)
        expected = len(
            [s for s in declared.load("maintenance")["update"] if "apps" not in s]
        )
        self.assertEqual(len(self.system.live), expected)

    def test_dry_run_lists_without_executing(self):
        self.assertEqual(main(["cleanup", "--dry-run"], self.system.env()), 0)
        self.assertEqual(self.system.live, [])
        self.assertIn("btrfs scrub start -B /var", self.system.text)

    def test_update_wraps_toolbox_commands_with_the_live_release(self):
        main(["update", "--dry-run"], self.system.env())
        self.assertIn(
            "toolbox run --container fedora-toolbox-44 sudo dnf upgrade",
            self.system.text,
        )


class ShellTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.system = FakeSystem(self.tmp.name)

    def test_shell_hook_is_added_once(self):
        env = self.system.env()
        main(["shell"], env)
        first = (self.system.home / ".bashrc").read_text()
        self.assertIn("device/fedora-laptop/shellrc", first)
        self.system.output.clear()
        main(["shell"], env)
        self.assertEqual((self.system.home / ".bashrc").read_text(), first)
        self.assertEqual(self.system.output, ["0 changes"])

    def test_shell_hook_updates_a_moved_repository_path(self):
        old = hooks.bashrc_hook("/old/repo")
        updated = hooks.with_bashrc_hook(old, "/new/repo")
        self.assertIn("SETTINGS_ROOT='/new/repo'", updated)
        self.assertNotIn("/old/repo", updated)

    def test_retired_symlinks_are_removed_but_foreign_files_are_kept(self):
        bin_dir = self.system.home / ".local/bin"
        bin_dir.mkdir(parents=True)
        (bin_dir / "update-system").symlink_to(
            "/repo/device/fedora-laptop/scripts/update-system.sh"
        )
        (bin_dir / "launch-uad").symlink_to("/somewhere/else")
        main(["shell"], self.system.env())
        self.assertFalse((bin_dir / "update-system").is_symlink())
        self.assertTrue((bin_dir / "launch-uad").is_symlink())

    def test_dry_run_changes_nothing(self):
        main(["shell", "--dry-run"], self.system.env())
        self.assertFalse((self.system.home / ".bashrc").exists())


class PhoneTests(unittest.TestCase):
    PROPS = (
        "[ro.product.device]: [spes]\n[ro.product.model]: [2201117TI]\n"
        "[ro.product.name]: [spes_in]\n[ro.build.version.release]: [13]\n"
        "[ro.build.version.sdk]: [33]\n[ro.boot.verifiedbootstate]: [green]\n"
    )

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.system = FakeSystem(self.tmp.name)
        original = self.system.run

        def adb(argv, cwd=None):
            tail = argv[argv.index("shell") + 1 :] if "shell" in argv else []
            if tail == ["getprop"]:
                from laptop.model import Result

                return Result(0, self.PROPS, "")
            if tail == ["cat", "/proc/meminfo"]:
                from laptop.model import Result

                return Result(0, "MemTotal: 3774464 kB\r\n", "")
            if tail[:3] == ["pm", "list", "packages"]:
                from laptop.model import Result

                flag = tail[3]
                body = {
                    "-3": "package:b\r\n",
                    "-u": "package:a\r\npackage:b\r\npackage:c\r\n",
                }.get(flag, "package:a\r\npackage:b\r\n")
                return Result(0, body, "")
            return original(argv, cwd)

        self.system.run = adb
        self.system.device_dir = Path(self.tmp.name) / "device/fedora-laptop"
        self.target = Path(self.tmp.name) / "device/phone/work"

    def test_capture_writes_role_folder_and_derives_removed_packages(self):
        self.assertEqual(main(["phone", "work", "SERIAL"], self.system.env()), 0)
        self.assertEqual((self.target / "not-installed-user-0.txt").read_text(), "c\n")
        self.assertEqual((self.target / "installed-user-0.txt").read_text(), "a\nb\n")
        readme = (self.target / "README.md").read_text()
        self.assertIn("| RAM visible to Android | 3.6 GiB |", readme)
        self.assertIn("| Verified boot | green |", readme)

    def test_capture_preserves_existing_phone_notes(self):
        self.target.mkdir(parents=True)
        (self.target / "README.md").write_text(
            "# Work phone\n\nHuman setup note.\n\n## Device state\n\nold\n"
        )
        self.assertEqual(main(["phone", "work", "SERIAL"], self.system.env()), 0)
        readme = (self.target / "README.md").read_text()
        self.assertIn("Human setup note.", readme)
        self.assertIn("## Device state", readme)
        self.assertNotIn("old", readme)

    def test_check_does_not_write(self):
        self.assertEqual(
            main(["phone", "work", "SERIAL", "--check"], self.system.env()), 1
        )
        self.assertFalse(self.target.exists())

    def test_unauthorized_device_is_rejected(self):
        self.system.adb_devices = "List of devices attached\nSERIAL\tunauthorized\n"
        self.assertEqual(main(["phone", "work", "SERIAL"], self.system.env()), 1)

    def test_other_phone_models_are_rejected(self):
        self.PROPS = self.PROPS.replace("2201117TI", "OTHER")
        self.assertEqual(main(["phone", "work", "SERIAL"], self.system.env()), 2)
        self.assertFalse(self.target.exists())


class UadTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.system = FakeSystem(self.tmp.name)
        binary = self.system.home / ".local/bin/uad-ng"
        binary.parent.mkdir(parents=True)
        binary.write_text("")

    def test_launches_inside_toolbox_when_device_is_ready(self):
        self.assertEqual(main(["uad"], self.system.env()), 0)
        self.assertEqual(
            self.system.live[-1][:5],
            [
                "toolbox",
                "run",
                "-c",
                "fedora-toolbox-44",
                str(self.system.home / ".local/bin/uad-ng"),
            ][:5],
        )

    def test_refuses_without_device_unless_forced(self):
        self.system.adb_devices = "List of devices attached\n"
        self.assertEqual(main(["uad"], self.system.env()), 1)
        self.assertEqual(self.system.live, [])
        self.assertEqual(main(["uad", "--force"], self.system.env()), 0)
        self.assertEqual(len(self.system.live), 1)


class MediaTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.system = FakeSystem(self.tmp.name)

    def test_join_orders_by_name_and_skips_previous_output(self):
        folder = Path(self.tmp.name) / "clips"
        folder.mkdir()
        for name in ("b.mp4", "a.mp4", "joined.mp4", "notes.txt"):
            (folder / name).write_text("")
        self.system.host_tools = {"ffmpeg"}
        self.assertEqual(main(["join", str(folder)], self.system.env()), 0)
        command = self.system.live[0]
        self.assertEqual(command[0], "ffmpeg")
        self.assertIn("-y", command)
        self.assertFalse(list(folder.glob(".*.list")))

    def test_join_needs_two_clips(self):
        folder = Path(self.tmp.name) / "one"
        folder.mkdir()
        (folder / "a.mp4").write_text("")
        self.assertEqual(main(["join", str(folder)], self.system.env()), 1)

    def test_ffmpeg_falls_back_to_toolbox(self):
        self.system.host_tools = set()
        main(["denoise-extract", "clip.mp4", "--dry-run"], self.system.env())
        self.assertTrue(
            self.system.output[0].startswith(
                "toolbox run --container fedora-toolbox-44 ffmpeg"
            )
        )


if __name__ == "__main__":
    unittest.main()
