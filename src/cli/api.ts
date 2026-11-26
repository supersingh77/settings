import { hostname } from "node:os"
import { realEnv } from "../runtime/env"
import type { Io } from "./ctx"
import { run } from "./run"
import { verbs } from "./verbs"

export type RunResult = { code: number; data: unknown; out: string; err: string }

let queue: Promise<unknown> = Promise.resolve()

function parseJson(text: string): unknown {
  try {
    return JSON.parse(text)
  } catch {
    return undefined
  }
}

function writes(argv: readonly string[]): boolean {
  const name = argv.find((word) => !word.startsWith("-"))
  const verb = verbs.find((candidate) => candidate.name === name)
  return verb !== undefined && verb.mutates !== "no"
}

async function execute(root: string, argv: readonly string[]): Promise<RunResult> {
  const out: string[] = []
  const err: string[] = []
  const io: Io = {
    out: (line) => out.push(line),
    err: (line) => err.push(line),
    stdin: async () => "",
    now: () => new Date(),
    hostname,
  }
  const code = await run(argv, { root, io, env: realEnv(root, io.err), policy: "web" })
  const text = out.join("\n")
  return { code, data: argv.includes("--json") ? parseJson(text) : undefined, out: text, err: err.join("\n") }
}

export function runArgv(root: string, argv: readonly string[]): Promise<RunResult> {
  if (!writes(argv)) return execute(root, argv)
  const next = queue.then(() => execute(root, argv))
  queue = next.catch(() => undefined)
  return next
}
