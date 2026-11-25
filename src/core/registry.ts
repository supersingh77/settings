import { PreconditionError, UsageError } from "./errors"
import type { Facet } from "./facet"
import type { Device } from "./types"

export function selectFacets(
  registry: readonly Facet[],
  device: Device,
  names: readonly string[],
): Facet[] {
  return names.map((name) => {
    if (!device.facets.includes(name)) throw new UsageError(`${device.id} does not use facet ${name}`)
    const facet = registry.find(
      (candidate) => candidate.platform === device.platform && candidate.name === name,
    )
    if (!facet) throw new PreconditionError(`facet ${name} is not implemented for ${device.platform}`)
    return facet
  })
}
