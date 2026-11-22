import io
import json
import struct
import tempfile
import unittest
from pathlib import Path

from laptop import apps, declared, install, media
from laptop.model import Result


def make_asar(name, payload):
    header = json.dumps(
        {"files": {name: {"size": len(payload), "offset": "0"}}}
    ).encode()
    padded = header + b"\x00" * (-len(header) % 4)
    pickle = struct.pack("<II", len(padded) + 4, len(header)) + padded
    return struct.pack("<II", 4, len(pickle)) + pickle + payload


class PureTests(unittest.TestCase):
    def test_github_asset_selection(self):
        release = {
            "tag_name": "v1.2.3",
            "assets": [
                {"name": "x.zip", "browser_download_url": "no"},
                {
                    "name": "openwork-linux-x86_64-1.AppImage",
                    "browser_download_url": "yes",
                },
            ],
        }
        rule = {"prefix": "openwork-linux-x86_64", "suffix": ".AppImage"}
        self.assertEqual(apps.github_latest(release, rule), ("1.2.3", "yes"))
        with self.assertRaises(ValueError):
            apps.github_latest({"tag_name": "v1", "assets": []}, rule)

    def test_antigravity_version_combines_version_and_execution(self):
        version, url = apps.antigravity_latest(
            [{"version": "2.3.1", "execution_id": "99"}], "u/{version}-{execution}/t"
        )
        self.assertEqual((version, url), ("2.3.1-99", "u/2.3.1-99/t"))

    def test_should_install(self):
        self.assertFalse(apps.should_install("1", "1", True, False))
        self.assertTrue(apps.should_install("1", "2", True, False))
        self.assertTrue(apps.should_install("1", "1", False, False))
        self.assertTrue(apps.should_install("1", "1", True, True))

    def test_launcher_and_desktop_rendering(self):
        self.assertEqual(
            apps.render_launcher([("A", "1")], "/x/y"),
            '#!/bin/bash\nexport A=1\nexec /x/y "$@"\n',
        )
        self.assertEqual(
            apps.render_desktop([("Name", "N")]), "[Desktop Entry]\nName=N\n"
        )

    def test_asar_entry_and_png_size(self):
        png = (
            b"\x89PNG\r\n\x1a\n"
            + struct.pack(">I", 13)
            + b"IHDR"
            + struct.pack(">II", 512, 256)
        )
        data = make_asar("icon.png", png)
        buffer = io.BytesIO(data)

        def read(offset, length):
            buffer.seek(offset)
            return buffer.read(length)

        self.assertEqual(apps.asar_entry(read, "icon.png"), png)
        self.assertEqual(apps.png_size(png), (512, 256))

    def test_every_declared_app_is_well_formed(self):
        for name, spec in declared.load("apps").items():
            with self.subTest(app=name):
                self.assertIn(spec["install"]["kind"], install.INSTALLERS)
                self.assertTrue({"install", "version"} <= set(spec["paths"]))
                self.assertTrue(apps.owned_paths(spec, Path("/h")))


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.said = []
        self.downloads = []
        self.spec = declared.load("apps")["uad-ng"]

    def ctx(self, dry_run=False, version="1.0"):
        def fetch(url):
            return {
                "tag_name": f"v{version}",
                "assets": [
                    {"name": "uad-ng-linux", "browser_download_url": "http://x/uad"}
                ],
            }

        def download(url, dest):
            self.downloads.append(url)
            Path(dest).write_bytes(b"binary")

        return install.Ctx(
            home=self.home,
            toolbox="fedora-toolbox-44",
            dry_run=dry_run,
            fetch_json=fetch,
            download=download,
            run=lambda argv, cwd=None: Result(0, "", ""),
            say=self.said.append,
        )

    def test_install_then_rerun_changes_nothing(self):
        self.assertGreater(install.install_app("uad-ng", self.spec, self.ctx()), 0)
        binary = self.home / ".local/bin/uad-ng"
        self.assertEqual(binary.read_bytes(), b"binary")
        self.assertEqual(binary.stat().st_mode & 0o777, 0o755)
        self.assertEqual((self.home / ".local/bin/uad-ng.version").read_text(), "1.0\n")
        desktop = (self.home / ".local/share/applications/uad-ng.desktop").read_text()
        self.assertIn(f"Exec=toolbox run -c fedora-toolbox-44 {binary}", desktop)
        self.downloads.clear()
        self.assertEqual(install.install_app("uad-ng", self.spec, self.ctx()), 0)
        self.assertEqual(self.downloads, [])

    def test_new_release_triggers_reinstall(self):
        install.install_app("uad-ng", self.spec, self.ctx())
        self.assertEqual(
            install.install_app("uad-ng", self.spec, self.ctx(version="2.0")), 1
        )
        self.assertEqual((self.home / ".local/bin/uad-ng.version").read_text(), "2.0\n")

    def test_dry_run_writes_nothing(self):
        self.assertGreater(
            install.install_app("uad-ng", self.spec, self.ctx(dry_run=True)), 0
        )
        self.assertEqual(list(self.home.iterdir()), [])
        self.assertEqual(self.downloads, [])

    def test_remove_deletes_only_owned_paths(self):
        install.install_app("uad-ng", self.spec, self.ctx())
        keep = self.home / ".local/bin/other"
        keep.write_text("x")
        self.assertGreater(install.remove_app("uad-ng", self.spec, self.ctx()), 0)
        self.assertFalse((self.home / ".local/bin/uad-ng").exists())
        self.assertTrue(keep.exists())

    def test_appimage_install_extracts_and_writes_wrapper(self):
        spec = declared.load("apps")["openwork"]
        ctx = self.ctx()

        def run(argv, cwd=None):
            if cwd is None:
                return Result(0, "", "")
            (Path(cwd) / "squashfs-root").mkdir()
            (Path(cwd) / "squashfs-root/.DirIcon").write_bytes(b"icon")
            return Result(0, "", "")

        ctx = install.Ctx(
            **{
                **ctx.__dict__,
                "run": run,
                "fetch_json": lambda url: {
                    "tag_name": "v3",
                    "assets": [
                        {
                            "name": "openwork-linux-x86_64.AppImage",
                            "browser_download_url": "http://x/o",
                        }
                    ],
                },
            }
        )
        install.install_app("openwork", spec, ctx)
        wrapper = (self.home / ".local/bin/openwork").read_text()
        self.assertIn(f"export APPDIR={self.home}/.local/lib/openwork", wrapper)
        self.assertIn(
            "exec "
            + str(self.home / ".local/lib/openwork/openwork")
            + ' --no-sandbox "$@"',
            wrapper,
        )
        icon = self.home / ".local/share/icons/hicolor/512x512/apps/openwork.png"
        self.assertEqual(icon.read_bytes(), b"icon")


class MediaTests(unittest.TestCase):
    def test_commands(self):
        output, arguments = media.extract_audio("/v/a.mp4")
        self.assertEqual(str(output), "/v/a_audio.m4a")
        self.assertEqual(arguments[-1], "/v/a_audio.m4a")
        output, arguments = media.merge_audio("/v/a.mp4", "/v/e.wav", "256k")
        self.assertEqual(str(output), "/v/a_denoised.mp4")
        self.assertIn("256k", arguments)

    def test_concat_list_escapes_quotes(self):
        self.assertEqual(
            media.concat_list("/d", ["it's.mp4"]), "file '/d/it'\\''s.mp4'\n"
        )

    def test_select_clips(self):
        self.assertEqual(
            media.select_clips(
                ["b.MP4", "a.mkv", "x.txt", "out.mp4"], {".mp4", ".mkv"}, "out.mp4"
            ),
            ["a.mkv", "b.MP4"],
        )


if __name__ == "__main__":
    unittest.main()
