import type { Recipe } from "./recipe"
import type { Device, Item, Needs, Platform, Step } from "./types"

export type Cmd = { argv: string[]; needs?: Needs; cwd?: string }

export type RunResult = { code: number; out: string; err: string }

export type InstallAction = "install" | "remove"
export type Installer = (recipe: Recipe, action: InstallAction) => Promise<RunResult>

export type Env = {
  run: (cmd: Cmd) => Promise<RunResult>
  read: (path: string) => Promise<string | null>
  write: (path: string, text: string) => Promise<void>
  say: (line: string) => void
  install: Installer
}

export type Repo = {
  home: string
  recipes: readonly Recipe[]
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
  command: (device: Device, repo: Repo) => Cmd
  parse: (stdout: string) => Item[]
  plan: (change: Change, repo: Repo) => Step[]
}

export function wrap(cmd: Cmd, platform: string): string[] {
  if (cmd.needs === "admin" && platform !== "win32") return ["sudo", ...cmd.argv]
  if (cmd.needs === "toolbox") return ["toolbox", "run", ...cmd.argv]
  return cmd.argv
}
