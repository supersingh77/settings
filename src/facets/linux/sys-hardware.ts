import type { Change, Facet } from "../../core/facet"
import type { Item, Scalar, Step } from "../../core/types"

const TYPES = new Set(["disk", "part", "lvm", "crypt"])

const SCRIPT = [
  "printf '@@os\\n'",
  "cat /etc/os-release",
  "printf '@@kernel\\n'",
  "cat /proc/sys/kernel/osrelease",
  "printf '@@dmi\\n'",
  "for f in board_name board_vendor bios_vendor bios_version bios_date; do printf '%s\\t%s\\n' \"$f\" \"$(cat /sys/class/dmi/id/$f)\"; done",
  "printf '@@cpu\\n'",
  "awk -F': ' '/^model name/ && !m {print \"model\\t\"$2; m=1} /^cpu cores/ && !c {print \"cores\\t\"$2; c=1} /^processor/{p++} END{print \"processors\\t\"p}' /proc/cpuinfo",
  "printf '@@meminfo\\n'",
  "grep '^MemTotal:' /proc/meminfo",
  "printf '@@zram\\n'",
  "for d in /sys/block/zram*/disksize; do [ -f \"$d\" ] && printf '%s\\t%s\\n' \"$(basename \"$(dirname \"$d\")\")\" \"$(cat \"$d\")\"; done",
  "printf '@@battery\\n'",
  "for b in /sys/class/power_supply/*; do [ \"$(cat \"$b/type\" 2>/dev/null)\" = Battery ] || continue; n=$(basename \"$b\"); d=$(cat \"$b/energy_full_design\" 2>/dev/null || true); f=$(cat \"$b/energy_full\" 2>/dev/null || true); printf '%s\\t%s\\t%s\\n' \"$n\" \"$d\" \"$f\"; done",
  "printf '@@net\\n'",
  "for n in /sys/class/net/*; do [ -e \"$n/device\" ] || continue; k=ethernet; [ -d \"$n/wireless\" ] && k=wireless; printf '%s\\t%s\\n' \"$(basename \"$n\")\" \"$k\"; done",
  "printf '@@fstab\\n'",
  "cat /etc/fstab",
  "printf '@@lsblk\\n'",
  "lsblk --json --output NAME,SIZE,MODEL,TYPE,FSTYPE,LABEL,MOUNTPOINTS",
].join("\n")

type Block = {
  name?: string
  size?: string
  model?: string | null
  type?: string
  fstype?: string | null
  label?: string | null
  mountpoints?: Array<string | null> | null
  children?: Block[]
}

function sections(stdout: string): Map<string, string[]> {
  const found = new Map<string, string[]>()
  let current = ""
  for (const line of stdout.split("\n")) {
    if (line.startsWith("@@")) {
      current = line.slice(2).trim()
      found.set(current, [])
    } else if (current !== "") {
      found.get(current)?.push(line)
    }
  }
  return found
}

function pairs(lines: readonly string[]): Map<string, string> {
  const found = new Map<string, string>()
  for (const line of lines) {
    const at = line.indexOf("\t")
    if (at > 0) found.set(line.slice(0, at), line.slice(at + 1))
  }
  return found
}

function osValues(lines: readonly string[]): Map<string, string> {
  const found = new Map<string, string>()
  for (const line of lines) {
    const at = line.indexOf("=")
    if (at > 0) found.set(line.slice(0, at), line.slice(at + 1).replaceAll("\"", ""))
  }
  return found
}

function gib(value: number): number {
  return Math.round(value / 1073741824)
}

function blockItems(devices: readonly Block[], items: Item[]): void {
  for (const device of devices) {
    const name = device.name ?? ""
    if (device.type && TYPES.has(device.type) && !name.startsWith("zram")) {
      const mounts = (device.mountpoints ?? []).filter(
        (mount): mount is string => typeof mount === "string" && mount !== "",
      )
      const a: Record<string, Scalar | Scalar[]> = { type: device.type, size: device.size ?? "" }
      if (device.model) a.model = device.model
      if (device.fstype) a.fstype = device.fstype
      if (device.label) a.label = device.label
      if (mounts.length > 0) a.mounts = mounts.sort()
      items.push({ id: "disk:" + name, a })
    }
    blockItems(device.children ?? [], items)
  }
}

function parseHardware(stdout: string): Item[] {
  const all = sections(stdout)
  const dmi = pairs(all.get("dmi") ?? [])
  const cpu = pairs(all.get("cpu") ?? [])
  const zram = pairs(all.get("zram") ?? [])
  const net = pairs(all.get("net") ?? [])
  const os = osValues(all.get("os") ?? [])
  const items: Item[] = []

  const release = (os.get("VERSION") ?? "").split(" (")
  items.push({
    id: "os:" + (os.get("ID") ?? "linux"),
    a: { version: release[0] ?? "", variant: (release[1] ?? "").replace(")", "") },
  })
  items.push({ id: "kernel:" + (all.get("kernel")?.[0] ?? "").trim(), a: {} })
  const board = dmi.get("board_name") ?? ""
  items.push({ id: "board:" + board, a: { vendor: dmi.get("board_vendor") ?? "" } })
  items.push({
    id: "firmware:" + (dmi.get("bios_version") ?? ""),
    a: { vendor: dmi.get("bios_vendor") ?? "", date: dmi.get("bios_date") ?? "" },
  })
  items.push({
    id: "cpu:" + (cpu.get("model") ?? ""),
    a: { cores: Number(cpu.get("cores") ?? 0), threads: Number(cpu.get("processors") ?? 0) },
  })

  const meminfo = (all.get("meminfo") ?? []).join("\n")
  const mem = /MemTotal:\s+(\d+)\s+kB/.exec(meminfo)
  items.push({ id: "mem:total", a: { gib: gib(Number(mem?.[1] ?? 0) * 1024) } })
  for (const [name, bytes] of zram) items.push({ id: "zram:" + name, a: { gib: gib(Number(bytes)) } })

  for (const line of all.get("battery") ?? []) {
    const [name = "", design = "", full = ""] = line.split("\t")
    if (name === "") continue
    const a: Record<string, Scalar> = {}
    if (design !== "" && full !== "") {
      a.designWh = Number(design) / 1000000
      a.fullWh = Number(full) / 1000000
    } else {
      a.capacity = "unreported"
    }
    items.push({ id: "battery:" + name, a })
  }

  for (const [name, kind] of net) items.push({ id: "iface:" + name, a: { kind } })

  for (const line of all.get("fstab") ?? []) {
    const trimmed = line.trim()
    if (trimmed === "" || trimmed.startsWith("#")) continue
    const fields = trimmed.split(/\s+/)
    const [source = "", mount = "", type = "", options = ""] = fields
    if (source === "" || mount === "" || type === "") continue
    items.push({ id: "mount:" + mount, a: { source, type, options } })
  }

  const lsblk = JSON.parse((all.get("lsblk") ?? []).join("\n")) as { blockdevices?: Block[] }
  blockItems(lsblk.blockdevices ?? [], items)
  return items
}

function planChange(_change: Change): Step[] {
  return []
}

export const hardware: Facet = {
  name: "sys-hardware",
  mode: "observed",
  command: () => ({ argv: ["bash", "-c", SCRIPT] }),
  parse: parseHardware,
  plan: planChange,
}
