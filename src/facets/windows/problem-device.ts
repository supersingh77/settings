import type { Facet } from "../../core/facet"
import type { Item, Scalar } from "../../core/types"

type ProblemDeviceDump = { text?: string }

function problemCode(value: string | undefined): number | null {
  if (value === undefined) return null
  const hex = /0x([0-9a-f]+)/i.exec(value)?.[1]
  if (hex !== undefined) return Number.parseInt(hex, 16)
  const decimal = /\d+/.exec(value)?.[0]
  return decimal === undefined ? null : Number(decimal)
}

function fieldsOf(block: string): Map<string, string> {
  const fields = new Map<string, string>()
  for (const line of block.split("\n")) {
    const colon = line.indexOf(":")
    if (colon <= 0) continue
    const key = line.slice(0, colon).trim().toLowerCase()
    const value = line.slice(colon + 1).trim()
    if (key !== "" && value !== "") fields.set(key, value)
  }
  return fields
}

function parseProblemDevices(stdout: string): Item[] {
  const trimmed = stdout.trim()
  if (!trimmed) return []
  const data = JSON.parse(trimmed) as ProblemDeviceDump
  const text = (data.text ?? "").replaceAll("\r\n", "\n")
  if (/No devices were found/i.test(text)) return []
  const items: Item[] = []
  for (const block of text.split(/\n\s*\n/)) {
    const fields = fieldsOf(block)
    const instanceId = fields.get("instance id")
    if (instanceId === undefined) continue
    const a: Record<string, Scalar> = {}
    const description = fields.get("device description")
    if (description !== undefined) a.description = description
    const className = fields.get("class name")
    if (className !== undefined) a.class = className
    const code = problemCode(fields.get("problem code"))
    if (code !== null) a.problemCode = code
    const o: Record<string, Scalar> = {}
    const status = fields.get("status")
    if (status !== undefined) o.status = status
    items.push({ id: `problem-device:${instanceId}`, a, ...(Object.keys(o).length > 0 ? { o } : {}) })
  }
  return items.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

export const problemDevice: Facet = {
  name: "problem-device",
  platform: "windows",
  mode: "observed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/problem-device.ps1"] }),
  parse: parseProblemDevices,
  plan: () => [],
}
