import type { Facet } from "../../core/facet"
import type { Item } from "../../core/types"

type DisplayRow = {
  device?: string
  width?: number
  height?: number
  hz?: number
  bpp?: number
}

function parseDisplay(stdout: string): Item[] {
  const trimmed = stdout.trim()
  if (!trimmed) return []
  const raw = JSON.parse(trimmed) as DisplayRow | DisplayRow[]
  const rows = Array.isArray(raw) ? raw : [raw]
  const items: Item[] = []
  for (const row of rows) {
    const device = row.device?.trim() ?? ""
    if (!device) continue
    items.push({
      id: `display-mode:${device}`,
      a: {
        width: row.width ?? 0,
        height: row.height ?? 0,
        hz: row.hz ?? 0,
        bpp: row.bpp ?? 0,
      },
    })
  }
  return items.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

export const display: Facet = {
  name: "display",
  mode: "observed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/display.ps1"] }),
  parse: parseDisplay,
  plan: () => [],
}
