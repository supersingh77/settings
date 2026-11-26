import { parseFrontMatter, splitRefs } from "./frontmatter"
import type { Item } from "./types"

export type Only = "asserted" | "observed"

export type NoteSummary = { path: string; title: string; refs: string[] }
export type Note = NoteSummary & { body: string }

export type FixtureRef = { platform: string; facet: string; name: string; path: string; golden: string }

function flat(record: Record<string, unknown> | undefined): string {
  return Object.entries(record ?? {})
    .map(([key, value]) => `${key}=${Array.isArray(value) ? value.join(",") : String(value)}`)
    .join(" ")
}

export function filterItems(items: readonly Item[], query: string, only: Only | undefined): Item[] {
  const needle = query.trim().toLowerCase()
  return items.filter((item) => {
    if (only === "observed" && !item.o) return false
    if (only === "asserted" && Object.keys(item.a).length === 0) return false
    return `${item.id} ${flat(item.a)} ${flat(item.o)}`.toLowerCase().includes(needle)
  })
}

export function itemLine(item: Item): string {
  return [item.id, flat(item.a), flat(item.o)].filter((part) => part !== "").join("  ")
}

export function summarizeNote(path: string, text: string): Note {
  const parsed = parseFrontMatter(text)
  const body = (parsed ? parsed.body : text).trim()
  const title = /^#\s+(.+)$/m.exec(body)?.[1] ?? path
  return { path, title, refs: splitRefs(parsed?.head.refs), body }
}

export function matchesNote(note: NoteSummary, query: string): boolean {
  const needle = query.trim().toLowerCase()
  return `${note.path} ${note.title} ${note.refs.join(" ")}`.toLowerCase().includes(needle)
}

export function pairFixtures(paths: readonly string[]): FixtureRef[] {
  const found: FixtureRef[] = []
  for (const path of paths.filter((entry) => entry.endsWith(".txt"))) {
    const [, , platform, facet, file] = path.split("/")
    if (!platform || !facet || !file) continue
    found.push({ platform, facet, name: file.replace(/\.txt$/, ""), path, golden: path.replace(/\.txt$/, ".golden.jsonl") })
  }
  return found
}
