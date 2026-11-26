import { filterItems, itemLine, matchesNote, summarizeNote, type Note, type Only } from "../core/browse"
import { Exit, PreconditionError, UsageError } from "../core/errors"
import { parseJsonl } from "../core/store"
import type { Device, Item } from "../core/types"
import { listDevices, listFiles, loadTasks } from "../runtime/files"
import type { Ctx, Outcome, Verb } from "./ctx"

async function deviceNamed(ctx: Ctx, id: string | undefined): Promise<Device> {
  const devices = await listDevices(ctx.root)
  const found = devices.find((device) => device.id === id)
  if (found) return found
  const known = devices.map((device) => device.id).join(", ") || "none"
  throw new PreconditionError(`unknown device ${id ?? ""}; known: ${known}`)
}

async function stored(ctx: Ctx, device: string, facet: string): Promise<Item[]> {
  const path = `data/devices/${device}/state/${facet}.jsonl`
  return parseJsonl((await ctx.env.read(path)) ?? "", path)
}

async function counts(ctx: Ctx, device: Device): Promise<Record<string, number>> {
  const entries = await Promise.all(device.facets.map(async (facet) => [facet, (await stored(ctx, device.id, facet)).length] as const))
  return Object.fromEntries(entries)
}

async function devicesRun(ctx: Ctx): Promise<Outcome> {
  const [action = "list", id] = ctx.args.positional
  if (action === "list") {
    const devices = await listDevices(ctx.root)
    const rows = await Promise.all(devices.map(async (device) => ({ device, counts: await counts(ctx, device) })))
    const text = rows.map((row) => `${row.device.id}  ${row.device.platform}  ${row.device.facets.length} facets`).join("\n")
    return { code: Exit.ok, data: { devices: rows }, text }
  }
  if (action !== "show") throw new UsageError("usage: devices list | show <id>")
  const device = await deviceNamed(ctx, id)
  const tasks = await loadTasks(ctx.root, device.id)
  const tally = await counts(ctx, device)
  const text = Object.entries(tally).map(([facet, count]) => `${facet}  ${count}`).join("\n")
  return { code: Exit.ok, data: { device, tasks, counts: tally }, text }
}

async function stateRun(ctx: Ctx): Promise<Outcome> {
  const [action, id] = ctx.args.positional
  const facet = ctx.args.values.facet?.[0]
  const only = ctx.args.values.only?.[0]
  if (action !== "list" || !facet) throw new UsageError("usage: state list <device> --facet <name> [--query text] [--only asserted|observed]")
  if (only !== undefined && only !== "asserted" && only !== "observed") throw new UsageError("--only is asserted or observed")
  const device = await deviceNamed(ctx, id)
  if (!device.facets.includes(facet)) throw new UsageError(`${device.id} does not use facet ${facet}`)
  const all = await stored(ctx, device.id, facet)
  const items = filterItems(all, ctx.args.values.query?.[0] ?? "", only as Only | undefined)
  return { code: Exit.ok, data: { device: device.id, facet, total: all.length, items }, text: items.map(itemLine).join("\n") }
}

async function recipesRun(ctx: Ctx): Promise<Outcome> {
  const [action = "list", id] = ctx.args.positional
  if (action === "list") {
    const ids = ctx.repo.recipes.map((recipe) => recipe.id)
    return { code: Exit.ok, data: { recipes: ids }, text: ids.join("\n") }
  }
  const recipe = ctx.repo.recipes.find((entry) => entry.id === id)
  if (action !== "show" || !recipe) throw new UsageError("usage: recipes list | show <id>")
  return { code: Exit.ok, data: { recipe }, text: JSON.stringify(recipe, null, 2) }
}

async function loadNotes(ctx: Ctx): Promise<Note[]> {
  const paths = (await listFiles(ctx.root, "notes")).filter((path) => path.endsWith(".md"))
  return Promise.all(paths.map(async (path) => summarizeNote(path, (await ctx.env.read(path)) ?? "")))
}

async function notesRun(ctx: Ctx): Promise<Outcome> {
  const [action = "list", wanted] = ctx.args.positional
  const notes = await loadNotes(ctx)
  if (action === "list") {
    const shown = notes.filter((note) => matchesNote(note, ctx.args.values.query?.[0] ?? ""))
    const summaries = shown.map(({ path, title, refs }) => ({ path, title, refs }))
    return { code: Exit.ok, data: { notes: summaries }, text: summaries.map((note) => `${note.path}  ${note.title}`).join("\n") }
  }
  const hits = notes.filter((note) => note.path === wanted || note.path === `notes/${wanted}`)
  if (action !== "show" || hits.length !== 1 || !hits[0]) throw new UsageError("usage: notes list [--query text] | show <path>")
  return { code: Exit.ok, data: { note: hits[0] }, text: hits[0].body }
}

const read = (name: string, usage: string, run: Verb["run"]): Verb => ({ name, usage, mutates: "no", run })

export const browseVerbs: Verb[] = [
  read("devices", "devices list | show <id> [--json]", devicesRun),
  read("state", "state list <device> --facet <name> [--query text] [--only asserted|observed] [--json]", stateRun),
  read("recipes", "recipes list | show <id> [--json]", recipesRun),
  read("notes", "notes list [--query text] | show <path> [--json]", notesRun),
]
