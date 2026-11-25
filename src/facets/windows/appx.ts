import type { Facet } from "../../core/facet"
import type { Item, Scalar } from "../../core/types"

type AppxRow = {
  name?: string
  version?: string
}

function numbers(version: string): number[] {
  return version.split(/[^0-9]+/).filter((part) => part !== "").map(Number)
}

function newer(candidate: string, current: string): boolean {
  const left = numbers(candidate)
  const right = numbers(current)
  for (let index = 0; index < Math.max(left.length, right.length); index += 1) {
    const a = left[index] ?? 0
    const b = right[index] ?? 0
    if (a !== b) return a > b
  }
  return false
}

function parseAppx(stdout: string): Item[] {
  const trimmed = stdout.trim()
  if (!trimmed) return []
  const raw = JSON.parse(trimmed) as AppxRow | AppxRow[]
  const rows = Array.isArray(raw) ? raw : [raw]
  const byId = new Map<string, Item>()
  for (const row of rows) {
    const name = row.name?.trim()
    if (!name) continue
    const id = `appx:${name}`
    const o: Record<string, Scalar> = {}
    const version = row.version?.trim()
    if (version) o.version = version
    const seen = byId.get(id)?.o?.version
    if (typeof seen === "string" && !newer(version ?? "", seen)) continue
    byId.set(id, {
      id,
      a: {},
      ...(Object.keys(o).length > 0 ? { o } : {}),
    })
  }
  return [...byId.values()].sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

export const appx: Facet = {
  name: "appx",
  mode: "observed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/appx.ps1"] }),
  parse: parseAppx,
  plan: () => [],
}
