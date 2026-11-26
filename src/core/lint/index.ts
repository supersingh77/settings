import { comments } from "./comments"
import { data } from "./data"
import { facetFiles } from "./facets"
import { layers } from "./layers"
import { limits } from "./limits"
import { notes } from "./notes"
import { webParity } from "./web"
import type { Rule, SourceFile, Violation } from "./types"

export const SCANNED_DIRS = ["src", "data", "notes", "web"] as const
export const SCANNED_FILES = ["README.md", "AGENTS.md"] as const

export const rules: Record<string, Rule> = {
  "no-comments": comments,
  layers,
  limits,
  data,
  notes,
  "facet-files": facetFiles,
  "web-parity": webParity,
}

export const ruleDocs: Record<string, string> = {
  "no-comments": "No comments in TypeScript source",
  layers: "core and facets stay pure; layers import only downward",
  limits: "Source files stay small, LF only, markdown only where allowed",
  data: "Device state, tasks and recipes parse and stay canonical",
  notes: "Notes carry front matter and refs that resolve",
  "facet-files": "Every facet has its parser, probe and fixtures",
  "web-parity": "The web UI reaches the CLI only through POST /api/run",
}

export function lint(files: readonly SourceFile[]): Violation[] {
  const found = Object.entries(rules).flatMap(([group, rule]) => rule(files).map((violation) => ({ ...violation, group })))
  return found.sort(
    (a, b) => a.path.localeCompare(b.path) || a.line - b.line || a.rule.localeCompare(b.rule),
  )
}
