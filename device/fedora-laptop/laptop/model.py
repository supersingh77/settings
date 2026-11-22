from dataclasses import dataclass
from typing import NamedTuple


@dataclass(frozen=True)
class Hardware:
    system: tuple
    disks: tuple
    interfaces: tuple
    mounts: tuple
    config: tuple


@dataclass(frozen=True)
class Software:
    os_name: str
    deployment: str
    kernel: str
    toolbox: str
    layers: tuple
    removals: tuple
    copr: tuple
    flatpaks: tuple
    toolbox_packages: tuple
    apps: tuple


@dataclass(frozen=True)
class Step:
    kind: str
    label: str
    argv: tuple = ()
    name: str = ""


class ProbeError(Exception):
    pass


class Result(NamedTuple):
    code: int
    out: str
    err: str


class StepError(Exception):
    pass
