import type { Device, Item, Needs, Platform, Step } from "./types"

export type Cmd = { argv: string[]; needs?: Needs }

export type RunResult = { code: number; out: string; err: string }

export type Env = {
  run: (cmd: Cmd) => Promise<RunResult>
  read: (path: string) => Promise<string | null>
  write: (path: string, text: string) => Promise<void>
  say: (line: string) => void
}

export type Change = {
  kind: "add" | "remove" | "modify"
  id: string
  want?: Item
  have?: Item
}

export type Facet = {
  name: string
  platform: Platform
  mode: "managed" | "observed"
  command: (device: Device) => Cmd
  parse: (stdout: string) => Item[]
  plan: (change: Change) => Step[]
}

export function wrap(cmd: Cmd, platform: string): string[] {
  if (cmd.needs === "admin" && platform !== "win32") return ["sudo", ...cmd.argv]
  if (cmd.needs === "toolbox") return ["toolbox", "run", ...cmd.argv]
  return cmd.argv
}
