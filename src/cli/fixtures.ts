import { Exit, UsageError } from "../core/errors"
import { formatJsonl } from "../core/store"
import { facets } from "../facets"
import { listFiles } from "../runtime/files"
import type { Verb } from "./ctx"

const fixtures: Verb = {
  name: "fixtures",
  usage: "fixtures update [--json]",
  mutates: "repo",
  run: async (ctx) => {
    if (ctx.args.positional[0] !== "update") throw new UsageError("usage: fixtures update")
    const written: string[] = []
    for (const facet of facets) {
      const dir = `data/fixtures/${facet.platform}/${facet.name}`
      const inputs = (await listFiles(ctx.root, dir)).filter((path) => path.endsWith(".txt"))
      for (const input of inputs) {
        const raw = await ctx.env.read(input)
        const golden = input.replace(/\.txt$/, ".golden.jsonl")
        await ctx.env.write(golden, formatJsonl(facet.parse(raw ?? ""), input))
        written.push(golden)
      }
    }
    const text = written.length ? written.map((path) => `wrote ${path}`).join("\n") : "no fixtures found"
    return { code: Exit.ok, data: { written }, text }
  },
}

export const fixtureVerbs: Verb[] = [fixtures]
