import type { Facet } from "../../core/facet"
import type { Item, Scalar } from "../../core/types"

type BiosRow = { vendor?: string; version?: string; date?: string }
type BoardRow = { manufacturer?: string; product?: string }
type CpuRow = { name?: string; mhz?: number; cores?: number; threads?: number }
type DimmRow = {
  locator?: string
  bank?: string
  sizeMb?: number
  type?: string
  rated?: number
  configured?: number
  manufacturer?: string
  partNumber?: string
}
type GpuRow = { name?: string; version?: string; date?: string; vramMb?: number }
type MonitorRow = { name?: string; inf?: string[]; icm?: string[] }
type HardwareDump = {
  bios?: BiosRow
  board?: BoardRow
  cpu?: CpuRow
  dimms?: DimmRow[]
  gpus?: GpuRow[]
  monitors?: MonitorRow[]
}

function put(target: Record<string, Scalar>, key: string, value: string | number | undefined): void {
  if (typeof value === "number" && value > 0) target[key] = value
  else if (typeof value === "string" && value !== "") target[key] = value
}

function makeItem(id: string, a: Record<string, Scalar>, o: Record<string, Scalar>): Item {
  return { id, a, ...(Object.keys(o).length > 0 ? { o } : {}) }
}

function boardItems(data: HardwareDump): Item[] {
  const product = data.board?.product?.trim() ?? ""
  if (!product) return []
  const a: Record<string, Scalar> = {}
  put(a, "manufacturer", data.board?.manufacturer?.trim())
  const o: Record<string, Scalar> = {}
  put(o, "biosVendor", data.bios?.vendor?.trim())
  put(o, "biosVersion", data.bios?.version?.trim())
  put(o, "biosDate", data.bios?.date?.trim())
  return [makeItem(`board:${product}`, a, o)]
}

function cpuItems(data: HardwareDump): Item[] {
  const name = data.cpu?.name?.trim() ?? ""
  if (!name) return []
  const a: Record<string, Scalar> = {}
  put(a, "cores", data.cpu?.cores)
  put(a, "threads", data.cpu?.threads)
  const o: Record<string, Scalar> = {}
  put(o, "mhz", data.cpu?.mhz)
  return [makeItem(`cpu:${name}`, a, o)]
}

function dimmKey(row: DimmRow): string {
  const locator = row.locator?.trim() ?? ""
  const bank = row.bank?.trim() ?? ""
  if (!locator || !bank || bank === locator) return locator
  return `${locator} (${bank})`
}

function dimmItems(data: HardwareDump): Item[] {
  const items: Item[] = []
  for (const row of data.dimms ?? []) {
    const key = dimmKey(row)
    if (!key) continue
    const a: Record<string, Scalar> = {}
    put(a, "sizeMb", row.sizeMb)
    put(a, "type", row.type?.trim())
    put(a, "rated", row.rated)
    put(a, "manufacturer", row.manufacturer?.trim())
    put(a, "partNumber", row.partNumber?.trim())
    const o: Record<string, Scalar> = {}
    put(o, "configured", row.configured)
    items.push(makeItem(`dimm:${key}`, a, o))
  }
  return items
}

function gpuItems(data: HardwareDump): Item[] {
  const items: Item[] = []
  for (const row of data.gpus ?? []) {
    const name = row.name?.trim() ?? ""
    if (!name) continue
    const a: Record<string, Scalar> = {}
    put(a, "vramMb", row.vramMb)
    const o: Record<string, Scalar> = {}
    put(o, "driverVersion", row.version?.trim())
    put(o, "driverDate", row.date?.trim())
    items.push(makeItem(`gpu:${name}`, a, o))
  }
  return items
}

function monitorItems(data: HardwareDump): Item[] {
  const items: Item[] = []
  for (const row of data.monitors ?? []) {
    const name = row.name?.trim() ?? ""
    if (!name) continue
    const o: Record<string, Scalar> = {}
    put(o, "inf", (row.inf ?? []).join(", "))
    put(o, "icm", (row.icm ?? []).join(", "))
    items.push(makeItem(`monitor:${name}`, {}, o))
  }
  return items
}

function parseHardware(stdout: string): Item[] {
  const trimmed = stdout.trim()
  if (!trimmed) return []
  const data = JSON.parse(trimmed) as HardwareDump
  const items = [
    ...boardItems(data),
    ...cpuItems(data),
    ...dimmItems(data),
    ...gpuItems(data),
    ...monitorItems(data),
  ]
  return items.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

export const hardware: Facet = {
  name: "hardware",
  platform: "windows",
  mode: "observed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/hardware.ps1"] }),
  parse: parseHardware,
  plan: () => [],
}
