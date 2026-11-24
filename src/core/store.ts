import { InputError } from "./errors"
import { Item } from "./types"

export function compareIds(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0
}

export function canonical(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonical)
  if (value !== null && typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>)
    entries.sort(([a], [b]) => compareIds(a, b))
    return Object.fromEntries(entries.map(([key, inner]) => [key, canonical(inner)]))
  }
  return value
}

export function sortItems(items: readonly Item[]): Item[] {
  return [...items].sort((a, b) => compareIds(a.id, b.id))
}

export function assertUnique(items: readonly Item[], source: string): void {
  const seen = new Set<string>()
  for (const item of items) {
    if (seen.has(item.id)) throw new InputError(`${source}: duplicate id ${item.id}`)
    seen.add(item.id)
  }
}

export function formatItem(item: Item): string {
  const ordered = item.o
    ? { id: item.id, a: canonical(item.a), o: canonical(item.o) }
    : { id: item.id, a: canonical(item.a) }
  return JSON.stringify(ordered)
}

export function formatJsonl(items: readonly Item[], source = "store"): string {
  const sorted = sortItems(items)
  assertUnique(sorted, source)
  return sorted.map((item) => `${formatItem(item)}\n`).join("")
}

export function parseJsonl(text: string, source = "store"): Item[] {
  const items: Item[] = []
  text.split("\n").forEach((line, index) => {
    if (line.trim() === "") return
    const where = `${source}:${index + 1}`
    let raw: unknown
    try {
      raw = JSON.parse(line)
    } catch {
      throw new InputError(`${where}: invalid JSON`)
    }
    const parsed = Item.safeParse(raw)
    if (!parsed.success) {
      throw new InputError(`${where}: ${parsed.error.issues[0]?.message ?? "invalid item"}`)
    }
    items.push(parsed.data)
  })
  assertUnique(items, source)
  return items
}
