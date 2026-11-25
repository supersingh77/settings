import type { Facet } from "../../core/facet"
import type { Item, Scalar } from "../../core/types"

type OsRow = {
  displayVersion?: string
  build?: string
  productName?: string
}

function parseOs(stdout: string): Item[] {
  const trimmed = stdout.trim()
  if (!trimmed) return []
  const row = JSON.parse(trimmed) as OsRow
  const a: Record<string, Scalar> = {}
  if (row.displayVersion) a.displayVersion = row.displayVersion
  if (row.build) a.build = row.build
  const o: Record<string, Scalar> = {}
  if (row.productName) o.productName = row.productName
  return [{
    id: "os:windows",
    a,
    ...(Object.keys(o).length > 0 ? { o } : {}),
  }]
}

export const os: Facet = {
  name: "os",
  mode: "observed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/os.ps1"] }),
  parse: parseOs,
  plan: () => [],
}
