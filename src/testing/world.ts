import type { Cmd, Env, Facet } from "../core/facet"
import type { Device, Item, Step } from "../core/types"

export type World = {
  items: Map<string, string>
  files: Map<string, string>
  mutations: string[][]
  failOn: string | undefined
}

export function makeWorld(items: Record<string, string> = {}): World {
  return { items: new Map(Object.entries(items)), files: new Map(), mutations: [], failOn: undefined }
}

export const toyDevice: Device = {
  id: "toybox",
  match: { hostname: "toyhost" },
  facets: ["toy"],
  ignore: ["toy:tmp-*"],
}

function parseToy(stdout: string): Item[] {
  return stdout
    .split("\n")
    .filter((line) => line !== "")
    .map((line) => {
      const [pair = "", version = ""] = line.split("@")
      const [key = "", value = ""] = pair.split("=")
      return { id: `toy:${key}`, a: { value }, o: { version } }
    })
}

function toyStep(id: string, verb: "set" | "del", key: string, value: string): Step {
  const argv = verb === "set" ? ["toy", "set", key, value] : ["toy", "del", key]
  return { id: `${verb}-${key}`, item: id, argv, destructive: verb === "del" }
}

export const toyFacet: Facet = {
  name: "toy",
  command: () => ({ argv: ["toy", "list"] }),
  parse: parseToy,
  plan: (change) => {
    const key = change.id.slice("toy:".length)
    if (change.kind === "remove") return [toyStep(change.id, "del", key, "")]
    return [toyStep(change.id, "set", key, String(change.want?.a.value ?? ""))]
  },
}

export function fakeEnv(world: World): Env {
  return {
    run: async (cmd: Cmd) => {
      const [tool, verb, key = "", value = ""] = cmd.argv
      if (tool !== "toy") return { code: 127, out: "", err: "not found" }
      if (verb === "list") {
        const lines = [...world.items].map(([k, v]) => `${k}=${v}@1\n`)
        return { code: 0, out: lines.join(""), err: "" }
      }
      world.mutations.push(cmd.argv)
      if (key === world.failOn) return { code: 1, out: "", err: "boom\nsecond line" }
      if (verb === "set") world.items.set(key, value)
      if (verb === "del") world.items.delete(key)
      return { code: 0, out: "", err: "" }
    },
    read: async (path) => world.files.get(path) ?? null,
    write: async (path, text) => {
      world.files.set(path, text)
    },
    say: () => {},
  }
}
