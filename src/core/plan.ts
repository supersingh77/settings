import { PreconditionError } from "./errors"
import type { Change, Facet, Repo } from "./facet"
import type { Device, Plan, Step } from "./types"

export type Delta = { facet: string; managed: boolean; changes: Change[] }

export function plan(
  device: Device,
  deltas: readonly Delta[],
  facets: readonly Facet[],
  repo: Repo,
): Plan {
  const byName = new Map(facets.map((facet) => [facet.name, facet]))
  const steps: Step[] = []
  for (const delta of deltas.filter((entry) => entry.managed)) {
    const facet = byName.get(delta.facet)
    if (!facet) throw new PreconditionError(`unknown facet ${delta.facet}`)
    for (const change of delta.changes) steps.push(...facet.plan(change, repo))
  }
  return { device: device.id, steps }
}

export function destructiveSteps(planned: Plan): Step[] {
  return planned.steps.filter((step) => step.destructive)
}

export function managedOnly(deltas: readonly Delta[]): Delta[] {
  return deltas.filter((delta) => delta.managed)
}

export function pending(deltas: readonly Delta[]): boolean {
  return deltas.some((delta) => delta.changes.length > 0)
}
