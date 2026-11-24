import { Exit, UsageError } from "../core/errors"
import { capture, compare, restore } from "../core/pipeline"
import { destructiveSteps, type Delta, pending } from "../core/plan"
import type { Outcome, Verb } from "./ctx"
import { targetOf } from "./target"

const LABEL = { add: "missing", remove: "extra", modify: "changed" } as const

function lines(deltas: readonly Delta[]): string[] {
  return deltas.flatMap((delta) =>
    delta.changes.map((change) => `${delta.facet} ${LABEL[change.kind]} ${change.id}`),
  )
}

function report(text: string[], data: unknown, code: number): Outcome {
  return { code, data, text: text.join("\n") }
}

const drift: Verb = {
  name: "drift",
  usage: "drift [device] [facet...] [--strict] [--json]",
  mutates: "no",
  run: async (ctx) => {
    const { device, facets } = await targetOf(ctx)
    const deltas = await compare(ctx.env, device, facets, { strict: ctx.args.strict })
    const drifted = pending(deltas)
    const text = drifted ? lines(deltas) : ["no drift"]
    return report(text, { device: device.id, drifted, deltas }, drifted ? Exit.found : Exit.ok)
  },
}

const captureVerb: Verb = {
  name: "capture",
  usage: "capture [device] [facet...] [--dry-run] [--json]",
  mutates: "repo",
  run: async (ctx) => {
    const { device, facets } = await targetOf(ctx)
    const deltas = await capture(ctx.env, device, facets, ctx.args.dryRun)
    const verb = ctx.args.dryRun ? "would change" : "changed"
    const text = pending(deltas) ? lines(deltas).map((line) => `${verb}: ${line}`) : ["store already matches live"]
    return report(text, { device: device.id, dryRun: ctx.args.dryRun, deltas }, Exit.ok)
  },
}

const restoreVerb: Verb = {
  name: "restore",
  usage: "restore [device] [facet...] [--dry-run] [--strict] [--yes] [--json]",
  mutates: "host",
  run: async (ctx) => {
    const { device, facets } = await targetOf(ctx)
    const options = { strict: ctx.args.strict, dryRun: ctx.args.dryRun }
    if (!ctx.args.dryRun && !ctx.args.yes) {
      const preview = await restore(ctx.env, device, facets, { ...options, dryRun: true })
      const risky = destructiveSteps(preview.plan)
      if (risky.length > 0) {
        throw new UsageError(`destructive steps need --yes: ${risky.map((step) => step.id).join(", ")}`)
      }
    }
    const result = await restore(ctx.env, device, facets, options)
    const steps = result.plan.steps.map((step) => `${step.id}: ${step.argv.join(" ")}`)
    if (ctx.args.dryRun) {
      return report(steps.length ? steps : ["nothing to do"], { dryRun: true, ...result }, steps.length ? Exit.found : Exit.ok)
    }
    const failed = result.results.find((entry) => entry.code !== 0)
    const converged = !failed && !pending(result.remaining)
    const text = failed ? [`step ${failed.step.id} failed: ${failed.err}`] : converged ? ["converged"] : lines(result.remaining)
    return report(text, { dryRun: false, converged, ...result }, converged ? Exit.ok : Exit.failed)
  },
}

export const syncVerbs: Verb[] = [drift, captureVerb, restoreVerb]
