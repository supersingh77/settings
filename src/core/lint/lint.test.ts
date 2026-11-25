import { expect, test } from "bun:test"
import { lint } from "./index"
import type { SourceFile } from "./types"

const file = (path: string, text: string): SourceFile => ({ path, text })
const rulesOf = (files: SourceFile[]) => lint(files).map((v) => v.rule)

const device = file("data/devices/d1/device.json", '{"id":"d1","platform":"linux","match":{},"facets":["toy"],"ignore":[]}')
const state = file("data/devices/d1/state/toy.jsonl", '{"id":"toy:a","a":{}}\n')

test("comments are flagged, shebangs and string contents are not", () => {
  expect(rulesOf([file("src/x.ts", "const a = 1 // note\n")])).toEqual(["no-comments"])
  expect(rulesOf([file("src/x.ts", "/* block */\nconst a = 1\n")])).toEqual(["no-comments"])
  expect(rulesOf([file("src/x.ts", '#!/usr/bin/env bun\nconst a = "// not a comment"\n')])).toEqual([])
  expect(rulesOf([file("src/x.ts", "const a = `// ${1} /* x */`\n")])).toEqual([])
})

test("pure layers may not import node, bun or other layers", () => {
  const core = (text: string) => rulesOf([file("src/core/x.ts", text)])
  expect(core('import { a } from "node:fs"\n')).toEqual(["layers"])
  expect(core('import { a } from "path"\n')).toEqual(["layers"])
  expect(core('import { a } from "../runtime/env"\n')).toEqual(["layers"])
  expect(core('import { a } from "./other"\nimport { z } from "zod"\n')).toEqual([])
  expect(rulesOf([file("src/runtime/x.ts", 'import { a } from "../cli/run"\n')])).toEqual(["layers"])
  expect(rulesOf([file("src/cli/x.ts", 'import { a } from "node:os"\nimport { b } from "../runtime/env"\n')])).toEqual([])
  expect(rulesOf([file("src/core/x.test.ts", 'import { a } from "bun:test"\n')])).toEqual([])
})

test("files over 200 lines and CR characters are flagged", () => {
  expect(rulesOf([file("src/x.ts", "const a = 1\n".repeat(201))])).toEqual(["small-files"])
  expect(rulesOf([file("src/x.ts", "const a = 1\r\n")])).toEqual(["lf-only"])
})

test("markdown is only allowed in notes, README and AGENTS, within bounds", () => {
  expect(rulesOf([file("docs/x.md", "hi\n")])).toEqual(["markdown-bounds"])
  expect(rulesOf([file("README.md", "line\n".repeat(41))])).toEqual(["markdown-bounds"])
  expect(rulesOf([file("README.md", "line\n".repeat(40))])).toEqual([])
})

test("device and state files are validated against strict schemas", () => {
  expect(rulesOf([device, state])).toEqual([])
  expect(rulesOf([file("data/devices/d1/device.json", '{"id":"d1","platform":"linux","match":{},"facets":[],"ignore":[],"note":"x"}')])).toEqual(["data"])
  expect(rulesOf([device, file("data/devices/d1/state/toy.jsonl", '{"id":"toy:b","a":{}}\n{"id":"toy:a","a":{}}\n')])).toEqual(["data"])
  expect(rulesOf([device, file("data/devices/d1/state/other.jsonl", "")])).toEqual(["data"])
  expect(rulesOf([state])).toEqual(["data", "data"])
  expect(rulesOf([device, file("data/devices/d1/readme.txt", "x")])).toEqual(["data"])
})

test("recipes are validated against the strict schema", () => {
  const ok = '{"id":"x","source":{"kind":"github","repo":"a/b","asset":{"name":"x"}},"paths":{"install":"{home}/x","version":"{home}/x.version"},"install":{"kind":"binary"}}'
  expect(rulesOf([file("data/recipes/x.json", ok)])).toEqual([])
  expect(rulesOf([file("data/recipes/x.json", '{"id":"x"}')])).toEqual(["data"])
  expect(rulesOf([file("data/recipes/x.json", ok.replace('"id":"x"', '"id":"y"'))])).toEqual(["data"])
  expect(rulesOf([file("data/recipes/x.txt", "")])).toEqual(["data"])
})

test("notes need front matter, no dates, and refs that resolve", () => {
  const note = (name: string, refs: string) => file(`notes/${name}.md`, `---\nrefs: ${refs}\n---\n\nbody\n`)
  expect(rulesOf([device, state, note("ok", "toy:a, src/x.ts"), file("src/x.ts", "")])).toEqual([])
  expect(rulesOf([device, state, note("bad", "toy:gone")])).toEqual(["notes"])
  expect(rulesOf([file("notes/plain.md", "no front matter\n")])).toEqual(["notes"])
  expect(rulesOf([note("2026-11-24-x", "")])).toEqual(["notes"])
})

test("facet files must be named, registered and have fixtures", () => {
  const facet = file("src/facets/linux/flatpak.ts", 'export const flatpak = { name: "flatpak", platform: "linux" }\n')
  const index = file("src/facets/index.ts", 'import { flatpak } from "./linux/flatpak"\n')
  const fixtures = [file("data/fixtures/linux/flatpak/a.txt", ""), file("data/fixtures/linux/flatpak/a.golden.jsonl", "")]
  expect(rulesOf([facet, index, ...fixtures])).toEqual([])
  expect(rulesOf([facet, file("src/facets/index.ts", ""), ...fixtures])).toEqual(["facet-files"])
  expect(rulesOf([facet, index])).toEqual(["facet-files", "facet-files"])
  expect(rulesOf([file("src/facets/linux/flatpak.ts", 'export const x = { name: "other", platform: "linux" }\n'), index, ...fixtures])).toEqual(["facet-files"])
})
