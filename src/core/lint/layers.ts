import ts from "typescript"
import { isSource, isTest, type Rule, type SourceFile, type Violation } from "./types"

const BUILTINS = new Set([
  "fs", "fs/promises", "path", "os", "child_process", "crypto", "util", "stream",
  "net", "http", "https", "url", "zlib", "readline", "process", "buffer", "events",
])

const ALLOWED: Record<string, readonly string[]> = {
  core: ["core"],
  facets: ["core", "facets"],
  runtime: ["core", "runtime"],
  cli: ["core", "facets", "runtime", "cli"],
}

const PURE = new Set(["core", "facets"])

function layerOf(path: string): string | undefined {
  return /^src\/([a-z]+)\//.exec(path)?.[1]
}

function resolve(from: string, specifier: string): string {
  const parts = from.split("/").slice(0, -1)
  for (const part of specifier.split("/")) {
    if (part === "..") parts.pop()
    else if (part !== ".") parts.push(part)
  }
  return parts.join("/")
}

function impure(specifier: string): boolean {
  return specifier.startsWith("node:") || specifier === "bun" || specifier.startsWith("bun:") || BUILTINS.has(specifier)
}

function check(file: SourceFile): Violation[] {
  const layer = layerOf(file.path)
  const allowed = layer ? ALLOWED[layer] : undefined
  if (!layer || !allowed) return []
  const violations: Violation[] = []
  const imports = ts.preProcessFile(file.text, true, true).importedFiles
  for (const { fileName, pos } of imports) {
    const line = file.text.slice(0, pos).split("\n").length
    const fail = (message: string) => {
      violations.push({ rule: "layers", path: file.path, line, message })
    }
    if (PURE.has(layer) && impure(fileName)) fail(`${layer}/ must stay pure, imports ${fileName}`)
    if (fileName.startsWith(".")) {
      const target = layerOf(`${resolve(file.path, fileName)}/`)
      if (target && !allowed.includes(target)) fail(`${layer}/ may not import ${target}/`)
    }
  }
  return violations
}

export const layers: Rule = (files) =>
  files.filter((file) => isSource(file) && !isTest(file)).flatMap(check)
