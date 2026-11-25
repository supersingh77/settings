import { resolveDevice } from "../core/device"
import type { Facet } from "../core/facet"
import { selectFacets } from "../core/registry"
import type { Device } from "../core/types"
import { facets as registry } from "../facets"
import { listDevices } from "../runtime/files"
import type { Ctx } from "./ctx"

export async function deviceOf(ctx: Ctx, positional: readonly string[]): Promise<Device> {
  const devices = await listDevices(ctx.root)
  const first = positional[0]
  const named = ctx.args.values.device?.[0] ?? (devices.some((d) => d.id === first) ? first : undefined)
  return resolveDevice(devices, ctx.io.hostname(), named)
}

export async function targetOf(ctx: Ctx): Promise<{ device: Device; facets: Facet[] }> {
  const device = await deviceOf(ctx, ctx.args.positional)
  const rest = ctx.args.positional.filter((word) => word !== device.id)
  const asked = [...rest, ...(ctx.args.values.facet ?? [])]
  const names = asked.length > 0 ? asked : device.facets
  return { device, facets: selectFacets(registry, device, names) }
}
