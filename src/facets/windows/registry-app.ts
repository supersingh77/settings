import type { Facet } from "../../core/facet"
import type { Item, Scalar } from "../../core/types"

type ArpRow = {
  name?: string
  version?: string
}

export function normalizeAppName(raw: string): string {
  return raw
    .replace(/\u0000/g, "")
    .replace(/\s+/g, " ")
    .replace(/\s+(?:version\s+)?v?\d+(?:\.\d+)+(?=\s|$)/gi, "")
    .replace(/\s+-\s*$/g, "")
    .trim()
}

function parseArp(stdout: string): Item[] {
  const trimmed = stdout.trim()
  if (!trimmed) return []
  const raw = JSON.parse(trimmed) as ArpRow | ArpRow[]
  const rows = Array.isArray(raw) ? raw : [raw]
  const byId = new Map<string, Item>()
  for (const row of rows) {
    const cleanRaw = (row.name ?? "").replace(/\u0000/g, "").trim()
    if (!cleanRaw) continue
    const key = normalizeAppName(cleanRaw) || cleanRaw
    const id = `reg:${key}`
    if (byId.has(id)) continue
    const o: Record<string, Scalar> = { raw: cleanRaw }
    const version = row.version?.trim()
    if (version) o.version = version
    byId.set(id, { id, a: {}, o })
  }
  return [...byId.values()].sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

export const registryApp: Facet = {
  name: "registry-app",
  mode: "observed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/registry-app.ps1"] }),
  parse: parseArp,
  plan: () => [],
}
