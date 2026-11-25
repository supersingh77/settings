import { z } from "zod"
import { Exit } from "../core/errors"
import { SCANNED_DIRS, SCANNED_FILES, rules } from "../core/lint"
import { Device, Item, MessageHead, Plan, Task } from "../core/types"
import { facets } from "../facets"
import { listDevices } from "../runtime/files"
import type { Verb } from "./ctx"

const EXIT_CODES = {
  0: "ran, nothing to report",
  1: "ran, found differences or violations",
  2: "bad usage or invalid input",
  3: "probe or precondition failed",
  4: "a step failed or the host did not converge",
  5: "internal error",
}

const FLAGS = {
  "--json": "one JSON document on stdout, human text on stderr",
  "--dry-run": "probe and plan, never execute or write",
  "--strict": "count observed values as drift",
  "--yes": "allow destructive steps",
  "--facet": "narrow to a facet, repeatable",
  "--device": "choose a device instead of matching the hostname",
}

const describe: Verb = {
  name: "describe",
  usage: "describe [--json]",
  mutates: "no",
  run: async (ctx) => {
    const devices = await listDevices(ctx.root)
    const data = {
      verbs: ctx.catalog,
      flags: FLAGS,
      exit: EXIT_CODES,
      devices: devices.map((device) => ({ id: device.id, platform: device.platform, facets: device.facets })),
      facets: facets.map((facet) => ({ platform: facet.platform, name: facet.name })),
      lint: Object.keys(rules),
      scanned: [...SCANNED_DIRS, ...SCANNED_FILES],
      schemas: {
        item: z.toJSONSchema(Item),
        device: z.toJSONSchema(Device),
        task: z.toJSONSchema(Task),
        plan: z.toJSONSchema(Plan),
        message: z.toJSONSchema(MessageHead),
      },
    }
    const verbLines = ctx.catalog.map((verb) => `  ${verb.usage}  [mutates: ${verb.mutates}]`)
    const text = [
      "verbs:",
      ...verbLines,
      `devices: ${data.devices.map((d) => d.id).join(", ") || "none"}`,
      `facets: ${data.facets.map((facet) => `${facet.platform}:${facet.name}`).join(", ") || "none"}`,
      "use --json for flags, exit codes and schemas",
    ].join("\n")
    return { code: Exit.ok, data, text }
  },
}

export const describeVerbs: Verb[] = [describe]
