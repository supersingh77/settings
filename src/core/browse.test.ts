import { expect, test } from "bun:test"
import { filterItems, itemLine, matchesNote, pairFixtures, summarizeNote } from "./browse"
import type { Item } from "./types"

const items: Item[] = [
  { id: "winget:Git.Git", a: { source: "winget" }, o: { version: "2.56.1" } },
  { id: "winget:7zip.7zip", a: { source: "winget" } },
  { id: "winget:Empty", a: {} },
]

test("filterItems matches ids and values and honours only", () => {
  expect(filterItems(items, "git", undefined).map((item) => item.id)).toEqual(["winget:Git.Git"])
  expect(filterItems(items, "2.56", undefined).length).toBe(1)
  expect(filterItems(items, "", "observed").map((item) => item.id)).toEqual(["winget:Git.Git"])
  expect(filterItems(items, "", "asserted").length).toBe(2)
})

test("itemLine joins id, asserted and observed values", () => {
  expect(itemLine(items[0] as Item)).toBe("winget:Git.Git  source=winget  version=2.56.1")
})

test("summarizeNote reads title and refs from front matter", () => {
  const note = summarizeNote("notes/x.md", "---\nrefs: a:b, c:d\n---\n\n# Title here\n\nbody\n")
  expect(note.title).toBe("Title here")
  expect(note.refs).toEqual(["a:b", "c:d"])
  expect(matchesNote(note, "c:d")).toBe(true)
  expect(matchesNote(note, "zzz")).toBe(false)
})

test("pairFixtures splits platform, facet and name", () => {
  const [ref] = pairFixtures(["data/fixtures/windows/winget/desktop.txt", "data/fixtures/windows/winget/desktop.golden.jsonl"])
  expect(ref).toEqual({
    platform: "windows",
    facet: "winget",
    name: "desktop",
    path: "data/fixtures/windows/winget/desktop.txt",
    golden: "data/fixtures/windows/winget/desktop.golden.jsonl",
  })
})
