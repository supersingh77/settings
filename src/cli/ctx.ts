import type { Env, Repo } from "../core/facet"
import type { Args } from "./args"

export type Io = {
  out: (line: string) => void
  err: (line: string) => void
  stdin: () => Promise<string>
  now: () => Date
  hostname: () => string
}

export type VerbInfo = {
  name: string
  usage: string
  mutates: "no" | "repo" | "host"
}

export type Ctx = {
  root: string
  args: Args
  io: Io
  env: Env
  repo: Repo
  catalog: VerbInfo[]
}

export type Outcome = { code: number; data: unknown; text: string }

export type Verb = VerbInfo & { run: (ctx: Ctx) => Promise<Outcome> }
