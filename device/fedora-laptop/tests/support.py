import json
from pathlib import Path

from laptop.cli import Env
from laptop.model import Result

OSTREE = json.dumps(
    {
        "deployments": [
            {
                "booted": True,
                "version": "44.20261008.0",
                "requested-packages": ["uhubctl", "distrobox", "ghostty"],
                "requested-base-removals": ["firefox"],
            }
        ]
    }
)
LSBLK = json.dumps(
    {
        "blockdevices": [
            {
                "name": "nvme0n1",
                "size": "476.9G",
                "model": "WD Green 480G",
                "type": "disk",
                "fstype": None,
                "label": None,
                "mountpoints": [None],
                "children": [
                    {
                        "name": "nvme0n1p3",
                        "size": "475.3G",
                        "model": None,
                        "type": "part",
                        "fstype": "btrfs",
                        "label": "fedora",
                        "mountpoints": ["/", "/var"],
                    }
                ],
            },
            {
                "name": "zram0",
                "size": "8G",
                "model": None,
                "type": "disk",
                "fstype": "swap",
                "label": None,
                "mountpoints": ["[SWAP]"],
            },
        ]
    }
)
FLATPAKS = "org.mozilla.firefox\t134.0\tstable\tflathub\norg.gnome.Calculator\t\tstable\tflathub\n"
TOOLBOX_RPM = "7zip\t24.09-1.fc44\nandroid-tools\t35.0.2-3.fc44\ngh\t2.60.0-1.fc44\n"
CPUINFO = "".join(
    f"processor\t: {i}\nmodel name\t: AMD Ryzen 5 2500U with Radeon Vega Mobile Gfx\ncpu cores\t: 4\n\n"
    for i in range(8)
)


def write(path, text=""):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def make_root(base, board="X505ZA"):
    root = Path(base) / "root"
    dmi = root / "sys/class/dmi/id"
    write(dmi / "board_name", board + "\n")
    write(dmi / "board_vendor", "ASUSTeK COMPUTER INC.\n")
    write(dmi / "bios_vendor", "American Megatrends\n")
    write(dmi / "bios_version", "X505ZA.313\n")
    write(dmi / "bios_date", "02/25/2020\n")
    write(root / "proc/cpuinfo", CPUINFO)
    write(root / "proc/meminfo", "MemTotal:       10485760 kB\n")
    write(root / "proc/sys/kernel/osrelease", "7.2.9-200.fc44.x86_64\n")
    write(
        root / "etc/os-release",
        'PRETTY_NAME="Fedora Linux 44 (Silverblue)"\nVERSION_ID=44\n',
    )
    write(
        root / "etc/fstab",
        "UUID=1 /var/mnt/data btrfs defaults,nofail 0 0\n# comment\n",
    )
    write(
        root / "etc/UPower/UPower.conf",
        "[UPower]\nNoPollBatteries=false\nAllowRiskyCriticalPowerAction=true\n",
    )
    write(
        root
        / "etc/yum.repos.d/_copr:copr.fedorainfracloud.org:alternateved:ghostty.repo"
    )
    write(root / "etc/yum.repos.d/fedora.repo")
    write(root / "sys/block/zram0/disksize", "8589934592\n")
    battery = root / "sys/class/power_supply/BAT0"
    write(battery / "type", "Battery\n")
    write(battery / "energy_full_design", "0\n")
    write(battery / "energy_full", "0\n")
    (root / "sys/class/net/wlan0/device").mkdir(parents=True)
    (root / "sys/class/net/wlan0/wireless").mkdir(parents=True)
    (root / "sys/class/net/enp2s0/device").mkdir(parents=True)
    (root / "sys/class/net/lo").mkdir(parents=True)
    (root / "sys/class/net/podman0").mkdir(parents=True)
    return root


class FakeSystem:
    def __init__(self, tmp, board="X505ZA"):
        self.root = make_root(tmp, board)
        self.home = Path(tmp) / "home"
        self.home.mkdir()
        self.device_dir = Path(tmp) / "device/fedora-laptop"
        self.device_dir.mkdir(parents=True)
        self.output = []
        self.live = []
        self.flatpaks = FLATPAKS
        self.ostree = OSTREE
        self.toolbox_rpm = TOOLBOX_RPM
        self.containers = "fedora-toolbox-44\n"
        self.host_tools = {"adb"}
        self.adb_devices = "List of devices attached\nSERIAL\tdevice\n"
        self.live_code = 0

    def run(self, argv, cwd=None):
        argv = list(argv)
        head = argv[:2]
        if argv[0] == "lsblk":
            return Result(0, LSBLK, "")
        if head == ["rpm-ostree", "status"]:
            return Result(0, self.ostree, "")
        if head == ["flatpak", "list"]:
            return Result(0, self.flatpaks, "")
        if argv[0] == "podman":
            return Result(0, self.containers, "")
        if argv[:2] == ["toolbox", "run"] and "rpm" in argv:
            return Result(
                1, self.toolbox_rpm + "package ffmpeg-free is not installed\n", ""
            )
        if argv[-1] == "devices":
            return Result(0, self.adb_devices, "")
        return Result(0, "", "")

    def run_live(self, argv, cwd=None):
        self.live.append(list(argv))
        return self.live_code

    def say(self, message):
        self.output.append(message)

    def which(self, name):
        return f"/usr/bin/{name}" if name in self.host_tools else None

    def env(self, fetch_json=None, download=None):
        return Env(
            root=self.root,
            home=self.home,
            device_dir=self.device_dir,
            run=self.run,
            run_live=self.run_live,
            fetch_json=fetch_json or (lambda url: {}),
            download=download or (lambda url, dest: None),
            say=self.say,
            which=self.which,
        )

    @property
    def text(self):
        return "\n".join(self.output)
