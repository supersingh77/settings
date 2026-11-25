import { parseFrontMatter, splitRefs } from "../frontmatter"
import { parseJsonl } from "../store"
import type { Rule, SourceFile, Violation } from "./types"

function stateIds(files: readonly SourceFile[]): Set<string> {
  const ids = new Set<string>()
  for (const file of files.filter((f) => /^data\/devices\/[^/]+\/state\/.+\.jsonl$/.test(f.path))) {
    try {
      for (const item of parseJsonl(file.text, file.path)) ids.add(item.id)
    } catch {
      continue
    }
  }
  return ids
}

export const notes: Rule = (files) => {
  const violations: Violation[] = []
  const ids = stateIds(files)
  const paths = new Set(files.map((file) => file.path))
  const fail = (path: string, message: string) => {
    violations.push({ rule: "notes", path, line: 1, message })
  }
  for (const file of files.filter((f) => f.path.startsWith("notes/") && f.path.endsWith(".md"))) {
    if (/\d{4}-\d{2}-\d{2}/.test(file.path)) fail(file.path, "note names must not carry dates")
    const front = parseFrontMatter(file.text)
    if (!front || !("refs" in front.head)) {
      fail(file.path, "missing front matter with a refs line")
      continue
    }
    for (const ref of splitRefs(front.head.refs)) {
      if (!ids.has(ref) && !paths.has(ref)) fail(file.path, `ref ${ref} does not resolve`)
    }
  }
  return violations
}
