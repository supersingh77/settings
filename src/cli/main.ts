#!/usr/bin/env bun
import { hostname } from "node:os"
import { DevError, Exit } from "../core/errors"
import { realEnv } from "../runtime/env"
import { findRoot } from "../runtime/files"
import { run } from "./run"

const io = {
  out: (line: string) => console.log(line),
  err: (line: string) => console.error(line),
  stdin: () => Bun.stdin.text(),
  now: () => new Date(),
  hostname,
}

try {
  const root = await findRoot(process.cwd())
  process.exitCode = await run(process.argv.slice(2), { root, io, env: realEnv(root, io.err) })
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error))
  process.exitCode = error instanceof DevError ? error.code : Exit.internal
}
