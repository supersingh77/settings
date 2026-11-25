import { PreconditionError } from "../../core/errors"
import type { Cmd, Facet, Repo } from "../../core/facet"
import type { Device, Item, Step } from "../../core/types"

const SCRIPT = [
  "for k in ro.product.model ro.product.device ro.product.name ro.build.version.release ro.build.version.sdk ro.build.display.id ro.build.fingerprint ro.build.version.security_patch ro.miui.ui.version.name ro.boot.vbmeta.device_state ro.boot.verifiedbootstate; do printf 'prop\\t%s\\t%s\\n' \"$k\" \"$(getprop \"$k\")\"; done",
  "printf 'mem\\t%s\\n' \"$(grep '^MemTotal:' /proc/meminfo)\"",
  "printf '@@all\\n'",
  "pm list packages --user 0 -u",
  "printf '@@installed\\n'",
  "pm list packages --user 0",
  "printf '@@third\\n'",
  "pm list packages --user 0 -3",
].join("\n")

function adb(device: Device, repo: Repo): string {
  const serial = device.match.serial
  if (!serial) throw new PreconditionError(device.id + " has no serial in device.json")
  return repo.home + "/.local/lib/platform-tools/adb"
}

function command(device: Device, repo: Repo): Cmd {
  const serial = device.match.serial
  if (!serial) throw new PreconditionError(device.id + " has no serial in device.json")
  return { argv: [adb(device, repo), "-s", serial, "shell", SCRIPT] }
}

function prop(props: Map<string, string>, key: string): string {
  return props.get(key) ?? ""
}

function parsePhone(stdout: string): Item[] {
  const props = new Map<string, string>()
  const lists: Record<string, string[]> = { all: [], installed: [], third: [] }
  let section = ""
  let mem = 0
  for (const raw of stdout.split("\n")) {
    const line = raw.replaceAll("\r", "")
    if (line.startsWith("prop\t")) {
      const [, key = "", value = ""] = line.split("\t")
      props.set(key, value)
      continue
    }
    if (line.startsWith("mem\t")) {
      mem = Number(/(\d+)/.exec(line.slice("mem\t".length))?.[1] ?? 0)
      continue
    }
    if (line.startsWith("@@")) {
      section = line.slice(2).trim()
      continue
    }
    if (section !== "" && line.startsWith("package:")) {
      const name = line.slice("package:".length).trim()
      if (name !== "") lists[section]?.push(name)
    }
  }
  const installed = new Set(lists.installed ?? [])
  const third = new Set(lists.third ?? [])
  const items: Item[] = [
    { id: "mem:total", a: { gib: Math.round((mem / 1048576) * 10) / 10 } },
    { id: "device:model", a: { value: prop(props, "ro.product.model") } },
    {
      id: "device:codename",
      a: { device: prop(props, "ro.product.device"), product: prop(props, "ro.product.name") },
    },
    {
      id: "device:android",
      a: {
        release: prop(props, "ro.build.version.release"),
        sdk: prop(props, "ro.build.version.sdk"),
      },
    },
    { id: "device:build", a: { id: prop(props, "ro.build.display.id") } },
    { id: "device:fingerprint", a: { value: prop(props, "ro.build.fingerprint") } },
    { id: "device:security-patch", a: { value: prop(props, "ro.build.version.security_patch") } },
    { id: "device:miui", a: { value: prop(props, "ro.miui.ui.version.name") } },
    {
      id: "device:bootloader",
      a: {
        state: prop(props, "ro.boot.vbmeta.device_state"),
        verified: prop(props, "ro.boot.verifiedbootstate"),
      },
    },
  ]
  for (const name of lists.all ?? []) {
    items.push({ id: "android:" + name, a: { installed: installed.has(name), thirdParty: third.has(name) } })
  }
  return items
}

function planChange(_change: unknown, _repo: Repo): Step[] {
  return []
}

export const android: Facet = {
  name: "android",
  platform: "android",
  mode: "observed",
  command,
  parse: parsePhone,
  plan: (change, repo) => planChange(change, repo),
}
