import type { Facet } from "../../core/facet"
import type { Item, Scalar } from "../../core/types"

type PathAppRow = {
  name?: string
  path?: string
  version?: string
}

function parsePathApp(stdout: string): Item[] {
  const trimmed = stdout.trim()
  if (!trimmed) return []
  const raw = JSON.parse(trimmed) as PathAppRow | PathAppRow[]
  const rows = Array.isArray(raw) ? raw : [raw]
  const byId = new Map<string, Item>()
  for (const row of rows) {
    const name = row.name?.trim()
    const path = row.path?.trim()
    if (!name || !path) continue
    const id = `path-app:${name}`
    const o: Record<string, Scalar> = {}
    const version = row.version?.trim()
    if (version) o.version = version
    byId.set(id, {
      id,
      a: { path },
      ...(Object.keys(o).length > 0 ? { o } : {}),
    })
  }
  return [...byId.values()].sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

export const pathApp: Facet = {
  name: "path-app",
  platform: "windows",
  mode: "observed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/path-app.ps1"] }),
  parse: parsePathApp,
  plan: () => [],
}
