import ts from "typescript"
import { isSource, type Rule, type Violation } from "./types"

function commentLines(path: string, text: string): number[] {
  const source = ts.createSourceFile(path, text, ts.ScriptTarget.Latest, true)
  const found = new Set<number>()
  const mark = (position: number) => {
    found.add(source.getLineAndCharacterOfPosition(position).line + 1)
  }
  const visit = (node: ts.Node) => {
    const children = node.getChildren(source)
    if (children.length === 0) {
      for (const range of ts.getLeadingCommentRanges(text, node.getFullStart()) ?? []) mark(range.pos)
      for (const range of ts.getTrailingCommentRanges(text, node.getEnd()) ?? []) mark(range.pos)
      return
    }
    children.forEach(visit)
  }
  visit(source)
  return [...found].sort((a, b) => a - b)
}

export const comments: Rule = (files) => {
  const violations: Violation[] = []
  for (const file of files.filter(isSource)) {
    for (const line of commentLines(file.path, file.text)) {
      violations.push({ rule: "no-comments", path: file.path, line, message: "comment in source" })
    }
  }
  return violations
}
