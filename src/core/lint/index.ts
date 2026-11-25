import { comments } from "./comments"
import { data } from "./data"
import { facetFiles } from "./facets"
import { layers } from "./layers"
import { limits } from "./limits"
import { notes } from "./notes"
import type { Rule, SourceFile, Violation } from "./types"

export const SCANNED_DIRS = ["src", "data", "notes"] as const
export const SCANNED_FILES = ["README.md", "AGENTS.md"] as const

export const rules: Record<string, Rule> = {
  "no-comments": comments,
  layers,
  limits,
  data,
  notes,
  "facet-files": facetFiles,
}

export function lint(files: readonly SourceFile[]): Violation[] {
  const found = Object.values(rules).flatMap((rule) => rule(files))
  return found.sort(
    (a, b) => a.path.localeCompare(b.path) || a.line - b.line || a.rule.localeCompare(b.rule),
  )
}
