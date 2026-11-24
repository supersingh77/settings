import { DevError, Exit, UsageError } from "../core/errors"
import type { Env } from "../core/facet"
import { parseArgs } from "./args"
import type { Io, Outcome } from "./ctx"
import { verbs } from "./verbs"

export type Deps = { root: string; io: Io; env: Env }

function emit(outcome: Outcome, json: boolean, io: Io): void {
  if (json) {
    io.out(JSON.stringify(outcome.data))
    if (outcome.text) io.err(outcome.text)
  } else if (outcome.text) {
    io.out(outcome.text)
  }
}

export async function run(argv: readonly string[], deps: Deps): Promise<number> {
  const json = argv.includes("--json")
  try {
    const args = parseArgs(argv)
    const name = args.help || args.verb === undefined ? "describe" : args.verb
    const verb = verbs.find((candidate) => candidate.name === name)
    if (!verb) throw new UsageError(`unknown verb ${name}`)
    const catalog = verbs.map(({ name: verbName, usage, mutates }) => ({ name: verbName, usage, mutates }))
    const outcome = await verb.run({ root: deps.root, args, io: deps.io, env: deps.env, catalog })
    emit(outcome, json, deps.io)
    return outcome.code
  } catch (error) {
    const code = error instanceof DevError ? error.code : Exit.internal
    const message = error instanceof Error ? error.message : String(error)
    if (json) deps.io.out(JSON.stringify({ error: message, code }))
    deps.io.err(message)
    return code
  }
}
