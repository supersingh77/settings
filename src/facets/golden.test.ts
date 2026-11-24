import { expect, test } from "bun:test"
import { readFile } from "node:fs/promises"
import { join } from "node:path"
import { formatJsonl } from "../core/store"
import { listFiles } from "../runtime/files"
import { facets } from "./index"

const root = join(import.meta.dir, "..", "..")

test("facet names are unique", () => {
  const names = facets.map((facet) => facet.name)
  expect(new Set(names).size).toBe(names.length)
})

for (const facet of facets) {
  test(`${facet.name} parses every recorded fixture to its golden file`, async () => {
    const inputs = (await listFiles(root, `fixtures/${facet.name}`)).filter((path) => path.endsWith(".txt"))
    expect(inputs.length).toBeGreaterThan(0)
    for (const input of inputs) {
      const raw = await readFile(join(root, input), "utf8")
      const golden = await readFile(join(root, input.replace(/\.txt$/, ".golden.jsonl")), "utf8")
      expect(formatJsonl(facet.parse(raw), input)).toBe(golden)
    }
  })
}
