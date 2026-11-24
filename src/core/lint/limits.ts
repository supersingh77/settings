import { isSource, lineCount, type Rule, type Violation } from "./types"

const MAX_SOURCE_LINES = 200
const MAX_ROOT_DOC_LINES = 40
const ROOT_DOCS = new Set(["README.md", "AGENTS.md"])

export const limits: Rule = (files) => {
  const violations: Violation[] = []
  const add = (rule: string, path: string, message: string) => {
    violations.push({ rule, path, line: 1, message })
  }
  for (const file of files) {
    if (file.text.includes("\r")) add("lf-only", file.path, "contains CR characters")
    const lines = lineCount(file.text)
    if (isSource(file) && lines > MAX_SOURCE_LINES) {
      add("small-files", file.path, `${lines} lines, limit ${MAX_SOURCE_LINES}`)
    }
    if (!file.path.endsWith(".md")) continue
    if (ROOT_DOCS.has(file.path)) {
      if (lines > MAX_ROOT_DOC_LINES) {
        add("markdown-bounds", file.path, `${lines} lines, limit ${MAX_ROOT_DOC_LINES}`)
      }
    } else if (!file.path.startsWith("notes/")) {
      add("markdown-bounds", file.path, "markdown is only allowed in notes/, README.md and AGENTS.md")
    }
  }
  return violations
}
