import type { Facet } from "../../core/facet"
import type { Item } from "../../core/types"

type SteamRow = {
  path?: string
  registered?: boolean
  apps?: number
}

function parseSteam(stdout: string): Item[] {
  const trimmed = stdout.trim()
  if (!trimmed) return []
  const raw = JSON.parse(trimmed) as SteamRow | SteamRow[]
  const rows = Array.isArray(raw) ? raw : [raw]
  const items: Item[] = []
  for (const row of rows) {
    if (!row.path) continue
    items.push({
      id: `steam-lib:${row.path}`,
      a: { registered: Boolean(row.registered) },
      o: { apps: typeof row.apps === "number" ? row.apps : 0 },
    })
  }
  return items.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

export const steam: Facet = {
  name: "steam",
  platform: "windows",
  mode: "observed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/steam.ps1"] }),
  parse: parseSteam,
  plan: () => [],
}
