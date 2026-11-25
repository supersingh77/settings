import { Exit, UsageError } from "../core/errors"
import { planTasks } from "../core/tasks"
import { loadTasks } from "../runtime/files"
import type { Outcome, Verb } from "./ctx"
import { deviceOf } from "./target"

function firstLine(text: string): string {
  return text.trim().split("\n")[0] ?? ""
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
      const results: Array<{ id: string; code: number; err: string }> = []
      for (const step of planned.steps) {
        const result = await ctx.env.run({ argv: step.argv, needs: step.needs })
        results.push({ id: step.id, code: result.code, err: firstLine(result.err) })
      }
      const failed = results.filter((entry) => entry.code !== 0)
      const text = failed.length
        ? failed.map((entry) => `${entry.id} failed: ${entry.err}`).join("\n")
        : `ran ${results.length} tasks`
      return { code: failed.length > 0 ? Exit.failed : Exit.ok, data: { dryRun: false, ...planned, results }, text }
    },
  }
}

export const maintenanceVerbs: Verb[] = [maintenance("update"), maintenance("cleanup")]
