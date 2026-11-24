import { Exit } from "../core/errors"
import { lint } from "../core/lint"
import { loadSources } from "../runtime/files"
import type { Verb } from "./ctx"

const check: Verb = {
  name: "check",
  usage: "check [--json]",
  mutates: "no",
  run: async (ctx) => {
    const files = await loadSources(ctx.root)
    const violations = lint(files)
    const text = violations.length
      ? violations.map((v) => `${v.path}:${v.line} ${v.rule}: ${v.message}`).join("\n")
      : `ok, ${files.length} files`
    return { code: violations.length ? Exit.found : Exit.ok, data: { files: files.length, violations }, text }
  },
}

export const checkVerbs: Verb[] = [check]
