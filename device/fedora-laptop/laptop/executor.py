from . import install
from .model import Step, StepError


def maintenance_steps(group, toolbox):
    steps = []
    for item in group:
        if "apps" in item:
            steps.append(Step("apps-update", item["name"]))
        elif "toolbox" in item:
            argv = ("toolbox", "run", "--container", toolbox, *item["toolbox"])
            steps.append(Step("exec", item["name"], argv))
        else:
            steps.append(Step("exec", item["name"], tuple(item["argv"])))
    return steps


def dispatch(step, specs, ctx, run_live):
    if step.kind == "exec":
        if run_live(list(step.argv)) != 0:
            raise StepError(f"{' '.join(step.argv)} exited non-zero")
        return 1
    if step.kind == "app-install":
        return install.install_app(step.name, specs[step.name], ctx, force=True)
    if step.kind == "app-remove":
        return install.remove_app(step.name, specs[step.name], ctx)
    if step.kind == "apps-update":
        return sum(
            install.install_app(name, spec, ctx)
            for name, spec in sorted(specs.items())
            if install.installed_version(spec, ctx.home)
        )
    raise ValueError(f"unknown step kind {step.kind!r}")


def execute(steps, specs, ctx, run_live):
    failures = []
    for step in steps:
        ctx.say(f"==> {step.label}")
        if ctx.dry_run:
            if step.argv:
                ctx.say("    " + " ".join(step.argv))
            elif step.kind == "app-install":
                ctx.say(f"    install {step.name} from its declared release")
            elif step.kind == "app-remove":
                ctx.say(f"    remove managed files for {step.name}")
            elif step.kind == "apps-update":
                names = [
                    name
                    for name, spec in sorted(specs.items())
                    if install.installed_version(spec, ctx.home)
                ]
                ctx.say("    update installed apps: " + (", ".join(names) or "none"))
            continue
        try:
            dispatch(step, specs, ctx, run_live)
        except install.FAILURES as error:
            ctx.say(f"failed: {step.label}: {error}")
            failures.append(step.label)
    return failures
