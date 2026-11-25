import type { Facet } from "../../core/facet"
import type { Item, Scalar } from "../../core/types"

type ShortcutRow = { name?: string; target?: string; arguments?: string }

function parseTaskbar(stdout: string): Item[] {
  const trimmed = stdout.trim()
  if (trimmed === "") return []
  const raw = JSON.parse(trimmed) as ShortcutRow | ShortcutRow[]
  const rows = Array.isArray(raw) ? raw : [raw]
  const items: Item[] = []
  for (const row of rows) {
    const name = row.name?.trim() ?? ""
    if (name === "") continue
    const a: Record<string, Scalar> = {}
    const target = row.target?.trim() ?? ""
    if (target !== "") a.target = target
    const args = row.arguments?.trim() ?? ""
    if (args !== "") a.arguments = args
    items.push({ id: `taskbar:${name}`, a })
  }
  return items.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

export const taskbar: Facet = {
  name: "taskbar",
  platform: "windows",
  mode: "observed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/taskbar.ps1"] }),
  parse: parseTaskbar,
  plan: () => [],
}
