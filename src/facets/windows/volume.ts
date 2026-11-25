import type { Facet } from "../../core/facet"
import type { Item } from "../../core/types"

type VolumeRow = {
  letter?: string
  label?: string
  type?: string
  totalGb?: number
  freeGb?: number
}

function parseVolume(stdout: string): Item[] {
  const trimmed = stdout.trim()
  if (!trimmed) return []
  const raw = JSON.parse(trimmed) as VolumeRow | VolumeRow[]
  const rows = Array.isArray(raw) ? raw : [raw]
  const items: Item[] = []
  for (const row of rows) {
    const letter = row.letter?.trim()
    if (!letter) continue
    items.push({
      id: `volume:${letter}`,
      a: {
        label: row.label ?? "",
        type: row.type ?? "Unknown",
        totalGb: typeof row.totalGb === "number" ? row.totalGb : 0,
      },
      o: {
        freeGb: typeof row.freeGb === "number" ? row.freeGb : 0,
      },
    })
  }
  return items.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

export const volume: Facet = {
  name: "volume",
  mode: "observed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/volume.ps1"] }),
  parse: parseVolume,
  plan: () => [],
}
