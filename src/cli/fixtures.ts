import { pairFixtures } from "../core/browse"
import { Exit, PreconditionError, UsageError } from "../core/errors"
import { formatJsonl } from "../core/store"
import { facets } from "../facets"
import { listFiles } from "../runtime/files"
import type { Ctx, Outcome, Verb } from "./ctx"

async function update(ctx: Ctx): Promise<Outcome> {
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
}

async function list(ctx: Ctx): Promise<Outcome> {
  const platform = ctx.args.values.platform?.[0]
  const refs = pairFixtures(await listFiles(ctx.root, "data/fixtures")).filter((ref) => !platform || ref.platform === platform)
  const summaries = refs.map(({ platform: p, facet, name, path }) => ({ platform: p, facet, name, path }))
  return { code: Exit.ok, data: { fixtures: summaries }, text: summaries.map((ref) => ref.path).join("\n") }
}

async function show(ctx: Ctx): Promise<Outcome> {
  const wanted = ctx.args.positional[1]
  const refs = pairFixtures(await listFiles(ctx.root, "data/fixtures"))
  const ref = refs.find((entry) => entry.path === wanted || `${entry.platform}/${entry.facet}/${entry.name}` === wanted)
  if (!ref) throw new PreconditionError(`${wanted ?? ""}: no such fixture; use platform/facet/name`)
  const raw = (await ctx.env.read(ref.path)) ?? ""
  const golden = (await ctx.env.read(ref.golden)) ?? ""
  return { code: Exit.ok, data: { fixture: { ...ref, raw, golden } }, text: raw }
}

const fixtures: Verb = {
  name: "fixtures",
  usage: "fixtures update | list [--platform p] | show <platform/facet/name> [--json]",
  mutates: "repo",
  run: async (ctx) => {
    const action = ctx.args.positional[0]
    if (action === "update") return update(ctx)
    if (action === "list") return list(ctx)
    if (action === "show") return show(ctx)
    throw new UsageError("usage: fixtures update | list | show <platform/facet/name>")
  },
}

export const fixtureVerbs: Verb[] = [fixtures]
