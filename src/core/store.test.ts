import { expect, test } from "bun:test"
import { InputError } from "./errors"
import { formatJsonl, parseJsonl } from "./store"
import type { Item } from "./types"

const items: Item[] = [
  { id: "flatpak:org.b", a: { origin: "flathub", branch: "stable" }, o: { version: "2" } },
  { id: "flatpak:org.a", a: { branch: "stable", origin: "fedora" } },
]

test("output is sorted by id with sorted keys, one item per line", () => {
  const text = formatJsonl(items)
  expect(text).toBe(
    '{"id":"flatpak:org.a","a":{"branch":"stable","origin":"fedora"}}\n' +
      '{"id":"flatpak:org.b","a":{"branch":"stable","origin":"flathub"},"o":{"version":"2"}}\n',
  )
})

test("format and parse round trip, and formatting is a fixed point", () => {
  const text = formatJsonl(items)
  expect(formatJsonl(parseJsonl(text))).toBe(text)
})

test("input order does not change output", () => {
  expect(formatJsonl([...items].reverse())).toBe(formatJsonl(items))
})

test("rejects duplicate ids, bad JSON and unknown keys with a line number", () => {
  const dup = '{"id":"a:x","a":{}}\n{"id":"a:x","a":{}}\n'
  expect(() => parseJsonl(dup, "f")).toThrow(InputError)
  expect(() => parseJsonl("nope\n", "f")).toThrow("f:1: invalid JSON")
  expect(() => parseJsonl('{"id":"a:x","a":{},"why":"x"}\n', "f")).toThrow(InputError)
})

test("empty store formats to empty text", () => {
  expect(formatJsonl([])).toBe("")
  expect(parseJsonl("")).toEqual([])
})
