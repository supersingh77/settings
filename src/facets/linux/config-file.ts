import type { Change, Facet } from "../../core/facet"
import type { Item, Step } from "../../core/types"

const PATH = "/etc/UPower/UPower.conf"
const KEYS = [
  "NoPollBatteries",
  "IgnoreLid",
  "UsePercentageForPolicy",
  "CriticalPowerAction",
  "AllowRiskyCriticalPowerAction",
]

function values(text: string): Map<string, string> {
  const found = new Map<string, string>()
  for (const line of text.split("\n")) {
    const trimmed = line.trim()
    if (trimmed === "" || trimmed.startsWith("#") || trimmed.startsWith(";") || trimmed.startsWith("[")) {
      continue
    }
    const at = trimmed.indexOf("=")
    if (at < 1) continue
    found.set(trimmed.slice(0, at).trim(), trimmed.slice(at + 1).trim())
  }
  return found
}

function parseConfig(stdout: string): Item[] {
  const found = values(stdout)
  return KEYS.map((key) => ({
    id: "conf:" + PATH + "#" + key,
    a: { value: found.get(key) ?? "unset" },
  }))
}

function planChange(_change: Change): Step[] {
  return []
}

export const configFile: Facet = {
  name: "config-file",
  platform: "linux",
  mode: "observed",
  command: () => ({ argv: ["cat", PATH] }),
  parse: parseConfig,
  plan: planChange,
}
