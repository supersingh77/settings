import { readdir, unlink, writeFile } from "node:fs/promises"
import { join } from "node:path"
import { Exit, PreconditionError, UsageError } from "../core/errors"
import { DEFAULT_OUTPUT, concatList, extractAudio, joinCommand, mergeAudio, selectClips } from "../core/media"
import type { Ctx, Outcome, Verb } from "./ctx"

async function finish(ctx: Ctx, output: string, argv: string[]): Promise<Outcome> {
  if (ctx.args.dryRun) return { code: Exit.ok, data: { dryRun: true, output, argv }, text: argv.join(" ") }
  const result = await ctx.env.run({ argv, needs: "toolbox" })
  const ok = result.code === 0
  return {
    code: ok ? Exit.ok : Exit.failed,
    data: { dryRun: false, output, argv, code: result.code },
    text: ok ? `wrote ${output}` : result.err.trim(),
  }
}

const media: Verb = {
  name: "media",
  usage: "media extract <video> | media merge <video> <audio> | media join <folder> [output] [--dry-run]",
  mutates: "host",
  run: async (ctx): Promise<Outcome> => {
    const [action, ...rest] = ctx.args.positional
    const first = rest[0]
    if (action === "extract" && first) {
      const command = extractAudio(first)
      return finish(ctx, command.output, command.argv)
    }
    if (action === "merge" && first && rest[1]) {
      const command = mergeAudio(first, rest[1])
      return finish(ctx, command.output, command.argv)
    }
    if (action === "join" && first) {
      const folder = first
      const output = rest[1] ?? DEFAULT_OUTPUT
      const clips = selectClips(await readdir(folder), output)
      if (clips.length < 2) throw new PreconditionError(`need at least 2 clips in ${folder}`)
      const listPath = join(folder, "." + output + ".list")
      const argv = joinCommand(listPath, join(folder, output))
      if (ctx.args.dryRun) return finish(ctx, join(folder, output), argv)
      await writeFile(listPath, concatList(folder, clips))
      try {
        return await finish(ctx, join(folder, output), argv)
      } finally {
        await unlink(listPath).catch(() => {})
      }
    }
    throw new UsageError(media.usage)
  },
}

export const mediaVerbs: Verb[] = [media]
