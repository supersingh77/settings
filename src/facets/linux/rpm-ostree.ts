import type { Change, Facet } from "../../core/facet"
import type { Item, Step } from "../../core/types"

type Deployment = {
  booted?: boolean
  staged?: boolean
  "requested-packages"?: string[]
  "requested-base-removals"?: string[]
}

type Status = { deployments?: Deployment[] }

function requested(status: Status): Deployment {
  const deployments = status.deployments ?? []
  const pending =
    deployments.find((entry) => entry.staged) ?? deployments.find((entry) => entry.booted)
  if (!pending) throw new Error("rpm-ostree status has no booted or staged deployment")
  return pending
}

function parseStatus(stdout: string): Item[] {
  const pending = requested(JSON.parse(stdout) as Status)
  const layers = pending["requested-packages"] ?? []
  const removals = pending["requested-base-removals"] ?? []
  return [
    ...layers.map((name) => ({ id: `layer:${name}`, a: {} })),
    ...removals.map((name) => ({ id: `removal:${name}`, a: {} })),
  ]
}

function step(id: string, item: string, argv: string[], destructive: boolean): Step {
  return { id, item, argv, needs: "admin", destructive }
}

function planChange(change: Change): Step[] {
  const key = change.id.slice(change.id.indexOf(":") + 1)
  if (change.id.startsWith("layer:")) {
    if (change.kind === "remove") {
      return [step(`layer:${key}:uninstall`, change.id, ["rpm-ostree", "uninstall", "--idempotent", key], true)]
    }
    return [step(`layer:${key}:install`, change.id, ["rpm-ostree", "install", "--idempotent", key], false)]
  }
  if (change.id.startsWith("removal:")) {
    if (change.kind === "remove") {
      return [step(`removal:${key}:reset`, change.id, ["rpm-ostree", "override", "reset", key], false)]
    }
    return [step(`removal:${key}:remove`, change.id, ["rpm-ostree", "override", "remove", key], true)]
  }
  return []
}

export const rpmOstree: Facet = {
  name: "rpm-ostree",
  platform: "linux",
  mode: "managed",
  command: () => ({ argv: ["rpm-ostree", "status", "--json"] }),
  parse: parseStatus,
  plan: planChange,
}
