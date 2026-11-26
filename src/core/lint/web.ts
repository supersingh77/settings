import type { Rule, SourceFile, Violation } from "./types"

const CLIENT = "web/src/api.ts"
const ALLOWED = new Set(["/api/run"])

function check(file: SourceFile): Violation[] {
  const violations: Violation[] = []
  file.text.split("\n").forEach((line, index) => {
    const add = (message: string) => violations.push({ rule: "web-parity", path: file.path, line: index + 1, message })
    if (file.path !== CLIENT && /\bfetch\(|XMLHttpRequest|WebSocket|EventSource/.test(line)) add(`network calls belong in ${CLIENT}`)
    for (const found of line.match(/\/api\/[A-Za-z0-9_-]+/g) ?? []) {
      if (!ALLOWED.has(found)) add(`${found}: the web UI may only call /api/run`)
    }
  })
  return violations
}

export const webParity: Rule = (files) =>
  files.filter((file) => file.path.startsWith("web/src/") && /\.tsx?$/.test(file.path)).flatMap(check)
