import type { Change } from "./facet"
import { canonical, compareIds } from "./store"
import type { Item } from "./types"

export type DiffOptions = { strict: boolean; ignore: readonly string[] }

export function globToRegExp(glob: string): RegExp {
  const escaped = glob.replace(/[.+?^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*")
  return new RegExp(`^${escaped}$`)
}

export function ignored(id: string, patterns: readonly string[]): boolean {
  return patterns.some((pattern) => globToRegExp(pattern).test(id))
}

function same(a: unknown, b: unknown): boolean {
  return JSON.stringify(canonical(a)) === JSON.stringify(canonical(b))
}

function observedMatches(want: Item, have: Item): boolean {
  return Object.entries(want.o ?? {}).every(([key, value]) => have.o?.[key] === value)
}

export function differs(want: Item, have: Item, strict: boolean): boolean {
  if (!same(want.a, have.a)) return true
  return strict && !observedMatches(want, have)
}

export function diff(
  want: readonly Item[],
  have: readonly Item[],
  options: DiffOptions,
): Change[] {
  const keep = (item: Item) => !ignored(item.id, options.ignore)
  const wanted = new Map(want.filter(keep).map((item) => [item.id, item]))
  const present = new Map(have.filter(keep).map((item) => [item.id, item]))
  const ids = [...new Set([...wanted.keys(), ...present.keys()])].sort(compareIds)
  const changes: Change[] = []
  for (const id of ids) {
    const w = wanted.get(id)
    const h = present.get(id)
    if (w && !h) changes.push({ kind: "add", id, want: w })
    else if (!w && h) changes.push({ kind: "remove", id, have: h })
    else if (w && h && differs(w, h, options.strict)) {
      changes.push({ kind: "modify", id, want: w, have: h })
    }
  }
  return changes
}
