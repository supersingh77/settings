import type { Change, Facet } from "../../core/facet"
import type { Item, Needs, Scalar, Step } from "../../core/types"

type ExtensionRow = {
  ext?: string
  progid?: string | null
  openWithProgids?: string[] | null
  openWithExe?: string | null
}

type ProgIdRow = {
  progid?: string
  description?: string | null
  command?: string | null
}

type ApplicationRow = {
  exe?: string
  friendly?: string | null
  command?: string | null
}

type Probe = {
  extensions?: ExtensionRow[]
  progids?: ProgIdRow[]
  applications?: ApplicationRow[]
}

const HKCR = "HKCR"
const HKCU = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts"

function byId(a: Item, b: Item): number {
  return a.id < b.id ? -1 : a.id > b.id ? 1 : 0
}

function text(value: Scalar | Scalar[] | undefined): string {
  return typeof value === "string" ? value : ""
}

function texts(value: Scalar | Scalar[] | undefined): string[] {
  return Array.isArray(value) ? value.filter((entry): entry is string => typeof entry === "string") : []
}

function parseAssociations(stdout: string): Item[] {
  const trimmed = stdout.trim()
  if (trimmed === "") return []
  const data = JSON.parse(trimmed) as Probe
  const items: Item[] = []
  const progIds = new Set<string>()
  for (const row of data.progids ?? []) {
    const progId = row.progid?.trim()
    if (!progId || !row.command) continue
    progIds.add(progId)
    items.push({ id: `progid:${progId}`, a: { description: row.description ?? "", command: row.command } })
  }
  for (const row of data.extensions ?? []) {
    const ext = row.ext?.trim()
    if (!ext) continue
    const progId = row.progid?.trim()
    if (progId) items.push({ id: `assoc:${ext}`, a: { progid: progId } })
    const exposed = [...new Set((row.openWithProgids ?? []).map((name) => name.trim()))]
      .filter((name) => progIds.has(name))
      .sort()
    const exe = row.openWithExe?.trim()
    const a: Record<string, Scalar | Scalar[]> = { progids: exposed }
    if (exe) a.exe = exe
    if (exposed.length > 0 || exe) items.push({ id: `open-with:${ext}`, a })
  }
  for (const row of data.applications ?? []) {
    const exe = row.exe?.trim()
    if (!exe || !row.command) continue
    items.push({ id: `app-reg:${exe}`, a: { friendly: row.friendly ?? "", command: row.command } })
  }
  return items.sort(byId)
}

function hkcr(...parts: string[]): string {
  return [HKCR, ...parts].join("\\")
}

function addDefault(key: string, value: string): string[] {
  return ["reg.exe", "add", key, "/ve", "/t", "REG_SZ", "/d", value, "/f"]
}

function addNamed(key: string, name: string, value: string): string[] {
  return ["reg.exe", "add", key, "/v", name, "/t", "REG_SZ", "/d", value, "/f"]
}

function deleteDefault(key: string): string[] {
  return ["reg.exe", "delete", key, "/ve", "/f"]
}

function deleteNamed(key: string, name: string): string[] {
  return ["reg.exe", "delete", key, "/v", name, "/f"]
}

function deleteKey(key: string): string[] {
  return ["reg.exe", "delete", key, "/f"]
}

function step(id: string, item: string, argv: string[], needs?: Needs): Step {
  return { id, item, argv, ...(needs ? { needs } : {}), destructive: false }
}

function destructive(id: string, item: string, argv: string[], needs?: Needs): Step {
  return { id, item, argv, ...(needs ? { needs } : {}), destructive: true }
}

function planAssoc(change: Change): Step[] {
  const key = hkcr(change.id.slice("assoc:".length))
  const progId = text(change.want?.a.progid)
  if (change.kind === "remove" || progId === "") {
    return [destructive(`${change.id}:delete`, change.id, deleteDefault(key), "admin")]
  }
  return [step(`${change.id}:set`, change.id, addDefault(key, progId), "admin")]
}

function planProgId(change: Change): Step[] {
  const progId = change.id.slice("progid:".length)
  const key = hkcr(progId)
  if (change.kind === "remove") {
    return [destructive(`${change.id}:delete`, change.id, deleteKey(key), "admin")]
  }
  const description = text(change.want?.a.description)
  const command = text(change.want?.a.command)
  const steps: Step[] = []
  const added = change.kind === "add"
  if (added ? description !== "" : description !== text(change.have?.a.description)) {
    steps.push(step(`${change.id}:description`, change.id, addDefault(key, description), "admin"))
  }
  if (command !== "" && (added || command !== text(change.have?.a.command))) {
    steps.push(step(`${change.id}:command`, change.id, addDefault(hkcr(progId, "shell", "open", "command"), command), "admin"))
  }
  return steps
}

function planAppReg(change: Change): Step[] {
  const exe = change.id.slice("app-reg:".length)
  const key = hkcr("Applications", exe)
  if (change.kind === "remove") {
    return [destructive(`${change.id}:delete`, change.id, deleteKey(key), "admin")]
  }
  const friendly = text(change.want?.a.friendly)
  const command = text(change.want?.a.command)
  const steps: Step[] = []
  const added = change.kind === "add"
  if (added ? friendly !== "" : friendly !== text(change.have?.a.friendly)) {
    steps.push(step(`${change.id}:friendly`, change.id, addNamed(key, "FriendlyAppName", friendly), "admin"))
  }
  if (command !== "" && (added || command !== text(change.have?.a.command))) {
    steps.push(step(`${change.id}:command`, change.id, addDefault(hkcr("Applications", exe, "shell", "open", "command"), command), "admin"))
  }
  return steps
}

function planOpenWith(change: Change): Step[] {
  const ext = change.id.slice("open-with:".length)
  const openKey = hkcr(ext, "OpenWithProgids")
  const listKey = `${HKCU}\\${ext}\\OpenWithList`
  const wanted = texts(change.want?.a.progids)
  const live = texts(change.have?.a.progids)
  const steps: Step[] = []
  for (const progId of wanted) {
    if (live.includes(progId)) continue
    steps.push(step(`${change.id}:add:${progId}`, change.id, addNamed(openKey, progId, ""), "admin"))
  }
  for (const progId of live) {
    if (wanted.includes(progId)) continue
    steps.push(destructive(`${change.id}:delete:${progId}`, change.id, deleteNamed(openKey, progId), "admin"))
  }
  const exe = text(change.want?.a.exe)
  const liveExe = text(change.have?.a.exe)
  if (exe !== liveExe) {
    steps.push(
      exe === ""
        ? destructive(`${change.id}:delete-exe`, change.id, deleteNamed(listKey, "a"))
        : step(`${change.id}:exe`, change.id, addNamed(listKey, "a", exe)),
    )
  }
  return steps
}

function planChange(change: Change): Step[] {
  const prefix = change.id.slice(0, change.id.indexOf(":"))
  if (prefix === "assoc") return planAssoc(change)
  if (prefix === "progid") return planProgId(change)
  if (prefix === "app-reg") return planAppReg(change)
  if (prefix === "open-with") return planOpenWith(change)
  return []
}

export const association: Facet = {
  name: "association",
  mode: "managed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/association.ps1"] }),
  parse: parseAssociations,
  plan: planChange,
}
