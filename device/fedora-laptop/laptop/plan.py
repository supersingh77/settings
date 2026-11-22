import re

from .model import Step

COPR_URL = (
    "https://copr.fedorainfracloud.org/coprs/{owner}/{project}/repo/"
    "fedora-{release}/{owner}-{project}-fedora-{release}.repo"
)
COPR_DEST = "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:{owner}:{project}.repo"
SAFE_NAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._+-]*$")


def missing(want, have):
    return tuple(item for item in want if item not in have)


def installed_names(packages):
    return tuple(name for name, version in packages if version)


def copr_steps(want, have, release):
    steps = []
    for repo in missing(want, have):
        owner, project = repo.split("/")
        dest = COPR_DEST.format(owner=owner, project=project)
        url = COPR_URL.format(owner=owner, project=project, release=release)
        steps.append(
            Step(
                "exec",
                f"add COPR {repo}",
                ("sudo", "curl", "-fsSL", "-o", dest, url),
            )
        )
    for repo in missing(have, want):
        owner, project = repo.split("/")
        dest = COPR_DEST.format(owner=owner, project=project)
        steps.append(Step("exec", f"remove COPR {repo}", ("sudo", "rm", "-f", dest)))
    return steps


def ostree_steps(want, have):
    steps = []
    pairs = (
        ("install", "layer", missing(want.layers, have.layers)),
        ("uninstall", "unlayer", missing(have.layers, want.layers)),
    )
    for verb, label, names in pairs:
        if names:
            steps.append(
                Step(
                    "exec",
                    f"{label} {' '.join(names)}",
                    ("rpm-ostree", verb, "--idempotent", *names),
                )
            )
    pairs = (
        ("remove", missing(want.removals, have.removals)),
        ("reset", missing(have.removals, want.removals)),
    )
    for verb, names in pairs:
        if names:
            steps.append(
                Step(
                    "exec",
                    f"override {verb} {' '.join(names)}",
                    ("rpm-ostree", "override", verb, *names),
                )
            )
    return steps


def flatpak_steps(want, have):
    steps = []
    have_ids = {row[0] for row in have}
    want_ids = {row[0] for row in want}
    for app, _version, _branch, origin in want:
        if app not in have_ids:
            steps.append(
                Step(
                    "exec",
                    f"install flatpak {app}",
                    ("flatpak", "install", "--system", "-y", origin, app),
                )
            )
    for app, *_rest in have:
        if app not in want_ids:
            steps.append(
                Step(
                    "exec",
                    f"remove flatpak {app}",
                    ("flatpak", "uninstall", "--system", "-y", app),
                )
            )
    return steps


def toolbox_steps(want, have, release):
    toolbox = f"fedora-toolbox-{release}"
    steps = []
    if want.toolbox and not have.toolbox:
        image = f"registry.fedoraproject.org/fedora-toolbox:{release}"
        steps.append(
            Step(
                "exec",
                f"create toolbox {toolbox}",
                (
                    "toolbox",
                    "create",
                    "--assumeyes",
                    "--container",
                    toolbox,
                    "--image",
                    image,
                ),
            )
        )
    want_names = set(installed_names(want.toolbox_packages))
    have_names = set(installed_names(have.toolbox_packages))
    install = sorted(want_names - have_names)
    remove = sorted(have_names - want_names)
    run = ("toolbox", "run", "--container", toolbox, "sudo", "dnf")
    if install:
        steps.append(
            Step(
                "exec",
                f"toolbox install {' '.join(install)}",
                (*run, "install", "-y", *install),
            )
        )
    if remove:
        steps.append(
            Step(
                "exec",
                f"toolbox remove {' '.join(remove)}",
                (*run, "remove", "-y", *remove),
            )
        )
    return steps


def app_steps(want, have):
    want_names = {name for name, _version in want}
    have_names = {name for name, _version in have}
    steps = [
        Step("app-install", f"install app {name}", name=name)
        for name in sorted(want_names - have_names)
    ]
    steps.extend(
        Step("app-remove", f"remove app {name}", name=name)
        for name in sorted(have_names - want_names)
    )
    return steps


def plan_restore(want, have, release):
    return [
        *copr_steps(want.copr, have.copr, release),
        *ostree_steps(want, have),
        *flatpak_steps(want.flatpaks, have.flatpaks),
        *toolbox_steps(want, have, release),
        *app_steps(want.apps, have.apps),
    ]


def unsafe_names(software):
    names = [
        *software.layers,
        *software.removals,
        *(row[0] for row in software.flatpaks),
        *(name for name, _version in software.toolbox_packages),
        *(name for name, _version in software.apps),
    ]
    return tuple(name for name in names if not SAFE_NAME.match(name))
