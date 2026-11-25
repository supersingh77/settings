import { stat } from "node:fs/promises"
import { homedir } from "node:os"
import { join } from "node:path"
import { Exit, PreconditionError } from "../core/errors"
import type { Outcome, Verb } from "./ctx"

const uad: Verb = {
  name: "uad",
  usage: "uad [--dry-run]",
  mutates: "host",
  run: async (ctx): Promise<Outcome> => {
    const desktop = join(homedir(), ".local/share/applications/uad-ng.desktop")
    try {
      await stat(desktop)
    } catch {
      throw new PreconditionError("UAD-NG is not installed; install it with restore first")
    }
    const argv = ["gio", "launch", desktop]
    if (ctx.args.dryRun) return { code: Exit.ok, data: { dryRun: true, argv }, text: argv.join(" ") }
    const result = await ctx.env.run({ argv })
    const ok = result.code === 0
    return {
      code: ok ? Exit.ok : Exit.failed,
      data: { argv, code: result.code },
      text: ok ? "launched UAD-NG" : result.err.trim(),
    }
  },
}

export const uadVerbs: Verb[] = [uad]
