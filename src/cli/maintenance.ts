import { Exit, UsageError } from "../core/errors"
import { failureSummary } from "../core/facet"
import { planTasks } from "../core/tasks"
import { loadTasks } from "../runtime/files"
import type { Outcome, Verb } from "./ctx"
import { deviceOf } from "./target"

type StepOutcome = { id: string; code: number; err: string }

function formatStepOutcome(entry: StepOutcome): string {
  if (entry.code === 0) return `${entry.id}: ok`
  const exitLabel = `exit ${entry.code}`
  const detail = entry.err !== "" && entry.err !== exitLabel ? `: ${entry.err}` : ""
  return `${entry.id}: failed (${exitLabel}${detail})`
}

function maintenance(group: "update" | "cleanup"): Verb {
  return {
    name: group,
    usage: `${group} [device] [--dry-run] [--json] [--yes]`,
    mutates: "host",
    run: async (ctx): Promise<Outcome> => {
      const device = await deviceOf(ctx, ctx.args.positional)
      const tasks = await loadTasks(ctx.root, device.id)
      const planned = planTasks(device.id, tasks, group)
      const lines = planned.steps.map((step) => `${step.id}: ${step.argv.join(" ")}`)
      if (ctx.args.dryRun) {
        return { code: Exit.ok, data: { dryRun: true, ...planned }, text: lines.length ? lines.join("\n") : "nothing to do" }
      }
      const risky = planned.steps.filter((step) => step.destructive)
      if (risky.length > 0 && !ctx.args.yes) {
        throw new UsageError(`destructive tasks need --yes: ${risky.map((step) => step.id).join(", ")}`)
      }
      const results: StepOutcome[] = []
      const total = planned.steps.length
      for (const [index, step] of planned.steps.entries()) {
        ctx.env.say(`[${index + 1}/${total}] ${step.id}: ${step.argv.join(" ")}`)
        const result = await ctx.env.run({ argv: step.argv, needs: step.needs, stream: true })
        const entry = { id: step.id, code: result.code, err: failureSummary(result) }
        results.push(entry)
        ctx.env.say(`[${index + 1}/${total}] ${formatStepOutcome(entry)}`)
      }
      const failed = results.filter((entry) => entry.code !== 0)
      const text = failed.length
        ? results.map(formatStepOutcome).join("\n")
        : results.length === 0
          ? "nothing to do"
          : `ran ${results.length} tasks`
      return { code: failed.length > 0 ? Exit.failed : Exit.ok, data: { dryRun: false, ...planned, results }, text }
    },
  }
}

export const maintenanceVerbs: Verb[] = [maintenance("update"), maintenance("cleanup")]
