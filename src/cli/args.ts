import { UsageError } from "../core/errors"

export type Args = {
  verb: string | undefined
  positional: string[]
  json: boolean
  dryRun: boolean
  strict: boolean
  yes: boolean
  help: boolean
  values: Record<string, string[]>
}

const FLAGS: Record<string, "json" | "dryRun" | "strict" | "yes" | "help"> = {
  "--json": "json",
  "--dry-run": "dryRun",
  "--strict": "strict",
  "--yes": "yes",
  "--help": "help",
  "-h": "help",
}

const VALUE_FLAGS = new Set(["facet", "device", "set", "to", "from", "kind", "subject", "ref", "body"])

export function parseArgs(argv: readonly string[]): Args {
  const args: Args = {
    verb: undefined,
    positional: [],
    json: false,
    dryRun: false,
    strict: false,
    yes: false,
    help: false,
    values: {},
  }
  const words = [...argv]
  while (words.length > 0) {
    const word = words.shift() as string
    const boolean = FLAGS[word]
    if (boolean) {
      args[boolean] = true
    } else if (word.startsWith("--")) {
      const [name = "", inline] = word.slice(2).split(/=(.*)/s)
      if (!VALUE_FLAGS.has(name)) throw new UsageError(`unknown flag ${word}`)
      const value = inline ?? words.shift()
      if (value === undefined) throw new UsageError(`${word} needs a value`)
      args.values[name] = [...(args.values[name] ?? []), value]
    } else if (args.verb === undefined) {
      args.verb = word
    } else {
      args.positional.push(word)
    }
  }
  return args
}
