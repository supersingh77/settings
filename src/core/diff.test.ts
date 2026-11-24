import { expect, test } from "bun:test"
import type { Change } from "./facet"
import { diff, globToRegExp } from "./diff"
import { sortItems } from "./store"
import type { Item } from "./types"

function lcg(seed: number): () => number {
  let state = seed
  return () => {
    state = (state * 1664525 + 1013904223) % 4294967296
    return state / 4294967296
  }
}

function randomItems(next: () => number): Item[] {
  const items: Item[] = []
  for (let n = 0; n < 12; n++) {
    if (next() < 0.5) items.push({ id: `k:${n}`, a: { v: Math.floor(next() * 3) }, o: { version: Math.floor(next() * 3) } })
  }
  return items
}

function apply(have: Item[], changes: Change[]): Item[] {
  const byId = new Map(have.map((item) => [item.id, item]))
  for (const change of changes) {
    if (change.kind === "remove") byId.delete(change.id)
    else if (change.want) byId.set(change.id, change.want)
  }
  return sortItems([...byId.values()])
}

const loose = { strict: false, ignore: [] }

test("a set never differs from itself", () => {
  const next = lcg(1)
  for (let n = 0; n < 200; n++) {
    const items = randomItems(next)
    expect(diff(items, items, loose)).toEqual([])
    expect(diff(items, items, { strict: true, ignore: [] })).toEqual([])
  }
})

test("applying the changes to live yields the wanted set, ignoring observed values", () => {
  const next = lcg(7)
  for (let n = 0; n < 200; n++) {
    const want = randomItems(next)
    const have = randomItems(next)
    const result = apply(have, diff(want, have, loose))
    expect(diff(want, result, loose)).toEqual([])
    expect(result.map((item) => item.id)).toEqual(sortItems(want).map((item) => item.id))
  }
})

test("observed values only count when strict", () => {
  const want: Item[] = [{ id: "k:1", a: {}, o: { version: "1" } }]
  const have: Item[] = [{ id: "k:1", a: {}, o: { version: "2" } }]
  expect(diff(want, have, loose)).toEqual([])
  expect(diff(want, have, { strict: true, ignore: [] }).map((c) => c.kind)).toEqual(["modify"])
})

test("a wanted item with no observed values never differs on them", () => {
  const want: Item[] = [{ id: "k:1", a: {} }]
  const have: Item[] = [{ id: "k:1", a: {}, o: { version: "9" } }]
  expect(diff(want, have, { strict: true, ignore: [] })).toEqual([])
})

test("changes come out sorted by id with the right kinds", () => {
  const want: Item[] = [{ id: "k:b", a: { v: 1 } }, { id: "k:a", a: {} }]
  const have: Item[] = [{ id: "k:b", a: { v: 2 } }, { id: "k:c", a: {} }]
  expect(diff(want, have, loose).map((c) => `${c.kind} ${c.id}`)).toEqual(["add k:a", "modify k:b", "remove k:c"])
})

test("ignore globs hide matching ids on both sides", () => {
  const want: Item[] = [{ id: "k:tmp-1", a: {} }]
  const have: Item[] = [{ id: "k:tmp-2", a: {} }]
  expect(diff(want, have, { strict: false, ignore: ["k:tmp-*"] })).toEqual([])
  expect(globToRegExp("a.b*").test("a.bxx")).toBe(true)
  expect(globToRegExp("a.b*").test("aXbxx")).toBe(false)
})
