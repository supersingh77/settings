import { readFile, readdir, readlink, unlink, writeFile } from "node:fs/promises"
import { homedir } from "node:os"
import { join } from "node:path"
import { Exit } from "../core/errors"
import { isRetiredLink, withBashrcHook, withProfileHook } from "../core/hooks"
import type { Ctx, Outcome, Verb } from "./ctx"

async function updateFile(ctx: Ctx, path: string, transform: (text: string) => string, mustExist: boolean, changes: string[]): Promise<void> {
  let current = ""
  try {
    current = await readFile(path, "utf8")
  } catch {
    if (mustExist) return
  }
  const next = transform(current)
  if (next === current) return
  changes.push(`${ctx.args.dryRun ? "would update" : "update"} ${path}`)
  if (!ctx.args.dryRun) await writeFile(path, next)
}

const shell: Verb = {
  name: "shell",
  usage: "shell [--dry-run]",
  mutates: "host",
  run: async (ctx): Promise<Outcome> => {
    const home = homedir()
    const changes: string[] = []
    await updateFile(ctx, join(home, ".bashrc"), (text) => withBashrcHook(text, ctx.root), false, changes)
    await updateFile(ctx, join(home, ".bash_profile"), withProfileHook, true, changes)
    const bin = join(home, ".local/bin")
    let names: string[] = []
    try {
      names = await readdir(bin)
    } catch {
      names = []
    }
    for (const name of names) {
      const path = join(bin, name)
      let target = ""
      try {
        target = await readlink(path)
      } catch {
        continue
      }
      if (!isRetiredLink(name, target)) continue
      changes.push(`${ctx.args.dryRun ? "would remove" : "remove"} ${path}`)
      if (!ctx.args.dryRun) await unlink(path)
    }
    return { code: Exit.ok, data: { dryRun: ctx.args.dryRun, changes }, text: changes.length ? changes.join("\n") : "0 changes" }
  },
}

export const shellVerbs: Verb[] = [shell]
