import { diff, ignored } from "./diff"
import { PreconditionError, ProbeError } from "./errors"
import type { Env, Facet, Repo, RunResult } from "./facet"
import { type Delta, plan } from "./plan"
import { formatJsonl, parseJsonl, sortItems } from "./store"
import { type Device, Item, type Plan, type Step } from "./types"

export type StepResult = { step: Step; code: number; err: string }
export type RestoreResult = { plan: Plan; results: StepResult[]; remaining: Delta[] }
export type CompareOptions = { strict: boolean }

export function statePath(device: string, facet: string): string {
  return `data/devices/${device}/state/${facet}.jsonl`
}

function firstLine(text: string): string {
  return text.trim().split("\n")[0] ?? ""
}

export async function probe(env: Env, device: Device, facet: Facet, repo: Repo): Promise<Item[]> {
  const result = await env.run(facet.command(device, repo))
  if (result.code !== 0) {
    throw new ProbeError(`${facet.name}: ${firstLine(result.err) || `exit ${result.code}`}`)
  }
  let items: Item[]
  try {
    items = sortItems(facet.parse(result.out).map((item) => Item.parse(item)))
    formatJsonl(items, facet.name)
  } catch (error) {
    throw new ProbeError(`${facet.name}: ${error instanceof Error ? error.message : error}`)
  }
  return items.filter((item) => !ignored(item.id, device.ignore))
}

export async function readState(env: Env, device: Device, facet: Facet): Promise<Item[]> {
  const path = statePath(device.id, facet.name)
  const text = await env.read(path)
  if (text === null) throw new PreconditionError(`${path}: missing, run capture first`)
  return parseJsonl(text, path)
}

export async function compare(
  env: Env,
  device: Device,
  facets: readonly Facet[],
  options: CompareOptions,
  repo: Repo,
): Promise<Delta[]> {
  const deltas: Delta[] = []
  for (const facet of facets) {
    const have = await probe(env, device, facet, repo)
    const want = await readState(env, device, facet)
    const changes = diff(want, have, { strict: options.strict, ignore: device.ignore })
    deltas.push({ facet: facet.name, managed: facet.mode === "managed", changes })
  }
  return deltas
}

export async function capture(
  env: Env,
  device: Device,
  facets: readonly Facet[],
  dryRun: boolean,
  repo: Repo,
): Promise<Delta[]> {
  const deltas: Delta[] = []
  for (const facet of facets) {
    const path = statePath(device.id, facet.name)
    const have = await probe(env, device, facet, repo)
    const text = await env.read(path)
    const before = text === null ? [] : parseJsonl(text, path)
    const changes = diff(before, have, { strict: true, ignore: device.ignore })
    if (!dryRun) await env.write(path, formatJsonl(have, path))
    deltas.push({ facet: facet.name, managed: facet.mode === "managed", changes })
  }
  return deltas
}

async function executeStep(env: Env, repo: Repo, step: Step): Promise<RunResult> {
  if (step.recipe !== undefined) {
    const recipe = repo.recipes.find((entry) => entry.id === step.recipe)
    if (!recipe) return { code: 3, out: "", err: `no recipe ${step.recipe}` }
    return env.install(recipe, step.action ?? "install")
  }
  return env.run({ argv: step.argv ?? [], needs: step.needs })
}

export async function restore(
  env: Env,
  device: Device,
  facets: readonly Facet[],
  options: CompareOptions & { dryRun: boolean },
  repo: Repo,
): Promise<RestoreResult> {
  const deltas = await compare(env, device, facets, options, repo)
  const planned = plan(device, deltas, facets, repo)
  if (options.dryRun || planned.steps.length === 0) {
    return { plan: planned, results: [], remaining: deltas }
  }
  const results: StepResult[] = []
  for (const step of planned.steps) {
    const run = await executeStep(env, repo, step)
    results.push({ step, code: run.code, err: firstLine(run.err) })
    if (run.code !== 0) return { plan: planned, results, remaining: deltas }
  }
  const remaining = await compare(env, device, facets, options, repo)
  return { plan: planned, results, remaining }
}
