import { readFile } from "node:fs/promises"
import { hostname } from "node:os"
import { join } from "node:path"
import { parseFrontMatter, splitRefs } from "../core/frontmatter"
import { parseJsonl } from "../core/store"
import type { Item } from "../core/types"
import { realEnv } from "../runtime/env"
import { listDevices, listFiles, loadTasks } from "../runtime/files"
import { loadRepo } from "../runtime/recipes"
import type { Io } from "./ctx"
import { run } from "./run"
import { verbs } from "./verbs"

export type RunResult = { code: number; data: unknown; out: string; err: string }

function parseJson(text: string): unknown {
  try {
    return JSON.parse(text)
  } catch {
    return undefined
  }
}

export function blocked(argv: readonly string[]): string | undefined {
  const name = argv.find((word) => !word.startsWith("-"))
  const verb = verbs.find((candidate) => candidate.name === name)
  if (verb?.mutates === "host" && !argv.includes("--dry-run")) {
    return `${verb.name} changes the host; the web console only runs it with --dry-run`
  }
  return undefined
}

export async function runArgv(root: string, argv: readonly string[]): Promise<RunResult> {
  const out: string[] = []
  const err: string[] = []
  const io: Io = {
    out: (line) => out.push(line),
    err: (line) => err.push(line),
    stdin: async () => "",
    now: () => new Date(),
    hostname,
  }
  const code = await run(argv, { root, io, env: realEnv(root, io.err) })
  const text = out.join("\n")
  const data = argv.includes("--json") ? parseJson(text) : undefined
  return { code, data, out: text, err: err.join("\n") }
}

async function stateFor(root: string, id: string): Promise<Record<string, Item[]>> {
  const prefix = `data/devices/${id}/state/`
  const state: Record<string, Item[]> = {}
  for (const path of (await listFiles(root, `data/devices/${id}/state`)).filter((p) => p.endsWith(".jsonl"))) {
    const text = await readFile(join(root, path), "utf8")
    state[path.slice(prefix.length).replace(/\.jsonl$/, "")] = parseJsonl(text, path)
  }
  return state
}

export async function deviceDetail(root: string, id: string): Promise<unknown> {
  const device = (await listDevices(root)).find((candidate) => candidate.id === id)
  if (!device) return undefined
  return { device, tasks: await loadTasks(root, id), state: await stateFor(root, id) }
}

export async function recipes(root: string): Promise<unknown> {
  return { recipes: (await loadRepo(root)).recipes }
}

export async function fixtures(root: string): Promise<unknown> {
  const paths = await listFiles(root, "data/fixtures")
  const found = []
  for (const path of paths.filter((p) => p.endsWith(".txt"))) {
    const [, , platform = "", facet = "", file = ""] = path.split("/")
    const golden = path.replace(/\.txt$/, ".golden.jsonl")
    found.push({
      platform,
      facet,
      name: file.replace(/\.txt$/, ""),
      path,
      raw: await readFile(join(root, path), "utf8"),
      golden: paths.includes(golden) ? await readFile(join(root, golden), "utf8") : "",
    })
  }
  return { fixtures: found }
}

export async function notes(root: string): Promise<unknown> {
  const found = []
  for (const path of (await listFiles(root, "notes")).filter((p) => p.endsWith(".md"))) {
    const text = await readFile(join(root, path), "utf8")
    const parsed = parseFrontMatter(text)
    const body = parsed ? parsed.body : text
    const title = /^#\s+(.+)$/m.exec(body)?.[1] ?? path
    found.push({ path, title, refs: splitRefs(parsed?.head.refs), body: body.trim() })
  }
  return { notes: found }
}

export async function mail(root: string): Promise<unknown> {
  const inbox = await runArgv(root, ["inbox", "list", "--json"])
  const outbox = await runArgv(root, ["outbox", "list", "--json"])
  const entries = (result: RunResult) => (result.data as { entries?: unknown[] } | undefined)?.entries ?? []
  return { inbox: entries(inbox), outbox: entries(outbox) }
}
