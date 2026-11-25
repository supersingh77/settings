import { PreconditionError } from "../../core/errors"
import type { Change, Cmd, Facet, Repo } from "../../core/facet"
import type { Device, Item, Step } from "../../core/types"

function expand(template: string, home: string): string {
  return template.replaceAll("{home}", home)
}

function quote(value: string): string {
  return "'" + value.replaceAll("'", "'\\''") + "'"
}

function command(_device: Device, repo: Repo): Cmd {
  const lines = repo.recipes.map(
    (recipe) =>
      `printf '%s\\t%s\\n' ${quote(recipe.id)} "$(cat ${quote(expand(recipe.paths.version, repo.home))} 2>/dev/null || true)"`,
  )
  return { argv: ["bash", "-c", lines.join("\n")] }
}

function parseApps(stdout: string): Item[] {
  const items: Item[] = []
  for (const line of stdout.split("\n")) {
    if (line === "") continue
    const at = line.indexOf("\t")
    if (at < 1) throw new Error(`unrecognized app row: ${line}`)
    const id = line.slice(0, at)
    const version = line.slice(at + 1)
    items.push(
      version === ""
        ? { id: "app:" + id, a: { recipe: id } }
        : { id: "app:" + id, a: { recipe: id }, o: { version } },
    )
  }
  return items
}

function planChange(change: Change, repo: Repo): Step[] {
  const name = change.id.slice("app:".length)
  if (!repo.recipes.some((recipe) => recipe.id === name)) {
    throw new PreconditionError(`app:${name} has no recipe`)
  }
  const action = change.kind === "remove" ? "remove" : "install"
  return [{ id: `app:${name}:${action}`, item: change.id, recipe: name, action, destructive: action === "remove" }]
}

export const app: Facet = {
  name: "app",
  platform: "linux",
  mode: "managed",
  command,
  parse: parseApps,
  plan: planChange,
}
