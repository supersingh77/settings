import { Exit, PreconditionError, UsageError } from "../core/errors"
import { formatJsonl, parseJsonl } from "../core/store"
import { Item, type Scalar } from "../core/types"
import { statePath } from "../core/pipeline"
import type { Outcome, Verb } from "./ctx"
import { deviceOf } from "./target"

function scalar(raw: string): Scalar {
  if (raw === "true") return true
  if (raw === "false") return false
  return raw !== "" && !Number.isNaN(Number(raw)) ? Number(raw) : raw
}

function attributes(sets: readonly string[]): Record<string, Scalar> {
  const attrs: Record<string, Scalar> = {}
  for (const entry of sets) {
    const at = entry.indexOf("=")
    if (at < 1) throw new UsageError(`--set needs key=value, got ${entry}`)
    attrs[entry.slice(0, at)] = scalar(entry.slice(at + 1))
  }
  return attrs
}

const want: Verb = {
  name: "want",
  usage: "want add <id> --facet <name> [--set key=value ...] | want rm <id> [--facet <name>] [--device <id>]",
  mutates: "repo",
  run: async (ctx): Promise<Outcome> => {
    const [action, id] = ctx.args.positional
    if ((action !== "add" && action !== "rm") || !id) throw new UsageError("usage: want add|rm <id>")
    const device = await deviceOf(ctx, [])
    const asked = ctx.args.values.facet ?? []
    const facets = asked.length > 0 ? asked : device.facets
    for (const name of facets) {
      if (!device.facets.includes(name)) throw new UsageError(`${device.id} does not use facet ${name}`)
    }
    if (action === "add") {
      if (asked.length !== 1 || !asked[0]) throw new UsageError("want add needs exactly one --facet")
      const path = statePath(device.id, asked[0])
      const item = Item.parse({ id, a: attributes(ctx.args.values.set ?? []) })
      const before = parseJsonl((await ctx.env.read(path)) ?? "", path)
      await ctx.env.write(path, formatJsonl([...before.filter((entry) => entry.id !== id), item], path))
      return { code: Exit.ok, data: { added: item, path }, text: `added ${id} to ${path}` }
    }
    for (const name of facets) {
      const path = statePath(device.id, name)
      const before = parseJsonl((await ctx.env.read(path)) ?? "", path)
      if (!before.some((entry) => entry.id === id)) continue
      await ctx.env.write(path, formatJsonl(before.filter((entry) => entry.id !== id), path))
      return { code: Exit.ok, data: { removed: id, path }, text: `removed ${id} from ${path}` }
    }
    throw new PreconditionError(`${id} is not in any state file of ${device.id}`)
  },
}

export const wantVerbs: Verb[] = [want]
