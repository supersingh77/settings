import type { Rule, Violation } from "./types"

const FACET_FILE = /^src\/facets\/([a-z]+)\/([a-z0-9-]+)\.ts$/

export const facetFiles: Rule = (files) => {
  const violations: Violation[] = []
  const index = files.find((file) => file.path === "src/facets/index.ts")
  for (const file of files) {
    const match = FACET_FILE.exec(file.path)
    if (!match) continue
    const [, dir, name] = match
    const fail = (message: string) => {
      violations.push({ rule: "facet-files", path: file.path, line: 1, message })
    }
    if (!new RegExp(`name:\\s*"${name}"`).test(file.text)) fail(`must define a facet named "${name}"`)
    if (!new RegExp(`platform:\\s*"${dir}"`).test(file.text)) fail(`platform must be "${dir}"`)
    if (!index?.text.includes(`./${dir}/${name}"`)) fail("not registered in src/facets/index.ts")
    const fixtures = files.filter((f) => f.path.startsWith(`fixtures/${dir}/${name}/`))
    if (!fixtures.some((f) => f.path.endsWith(".txt"))) fail(`no recorded output in fixtures/${name}/`)
    if (!fixtures.some((f) => f.path.endsWith(".golden.jsonl"))) fail(`no golden file in fixtures/${name}/`)
  }
  return violations
}
