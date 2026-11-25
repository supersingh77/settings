import { InputError } from "../errors"
import { formatJsonl, parseJsonl } from "../store"
import { Recipe } from "../recipe"
import { Device, Tasks } from "../types"
import type { Rule, SourceFile, Violation } from "./types"

const DEVICE_FILE = /^data\/devices\/([^/]+)\/(.+)$/
const RECIPE_FILE = /^data\/recipes\/([a-z0-9-]+)\.json$/

function readJson(text: string): unknown {
  try {
    return JSON.parse(text)
  } catch {
    throw new InputError("invalid JSON")
  }
}

function checkState(file: SourceFile, facets: readonly string[], rel: string): string[] {
  const facet = /^state\/([a-z0-9-]+)\.jsonl$/.exec(rel)?.[1]
  if (!facet) return [`unexpected file ${rel}`]
  const problems: string[] = []
  if (!facets.includes(facet)) problems.push(`facet ${facet} is not listed in device.json`)
  try {
    const items = parseJsonl(file.text, file.path)
    if (formatJsonl(items, file.path) !== file.text) problems.push("not canonical: sorted, compact, one item per line")
  } catch (error) {
    problems.push(error instanceof Error ? error.message : String(error))
  }
  return problems
}

function checkDevice(file: SourceFile, dir: string): { facets: string[]; problems: string[] } {
  try {
    const parsed = Device.safeParse(readJson(file.text))
    if (!parsed.success) return { facets: [], problems: [parsed.error.issues[0]?.message ?? "invalid device"] }
    const problems = parsed.data.id === dir ? [] : [`id ${parsed.data.id} does not match directory ${dir}`]
    return { facets: parsed.data.facets, problems }
  } catch (error) {
    return { facets: [], problems: [error instanceof Error ? error.message : String(error)] }
  }
}

function checkTasks(file: SourceFile): string[] {
  try {
    const parsed = Tasks.safeParse(readJson(file.text))
    return parsed.success ? [] : [parsed.error.issues[0]?.message ?? "invalid tasks"]
  } catch (error) {
    return [error instanceof Error ? error.message : String(error)]
  }
}

function checkRecipe(file: SourceFile, name: string): string[] {
  try {
    const parsed = Recipe.safeParse(readJson(file.text))
    if (!parsed.success) return [parsed.error.issues[0]?.message ?? "invalid recipe"]
    return parsed.data.id === name ? [] : [`id ${parsed.data.id} does not match the file name`]
  } catch (error) {
    return [error instanceof Error ? error.message : String(error)]
  }
}

export const data: Rule = (files) => {
  const violations: Violation[] = []
  for (const file of files.filter((entry) => entry.path.startsWith("data/recipes/"))) {
    const match = RECIPE_FILE.exec(file.path)
    const problems = match?.[1] ? checkRecipe(file, match[1]) : ["unexpected file"]
    for (const message of problems) violations.push({ rule: "data", path: file.path, line: 1, message })
  }
  const inDevices = files.filter((file) => DEVICE_FILE.test(file.path))
  const facetsOf = new Map<string, string[]>()
  for (const file of inDevices) {
    const [, dir, rel] = DEVICE_FILE.exec(file.path) ?? []
    if (dir && rel === "device.json") facetsOf.set(dir, checkDevice(file, dir).facets)
  }
  for (const file of inDevices) {
    const [, dir, rel] = DEVICE_FILE.exec(file.path) ?? []
    if (!dir || !rel) continue
    let problems: string[]
    if (rel === "device.json") problems = checkDevice(file, dir).problems
    else if (rel === "tasks.json") problems = checkTasks(file)
    else problems = checkState(file, facetsOf.get(dir) ?? [], rel)
    if (rel !== "device.json" && !facetsOf.has(dir)) problems.push(`data/devices/${dir}/device.json is missing`)
    for (const message of problems) violations.push({ rule: "data", path: file.path, line: 1, message })
  }
  return violations
}
