import { afterEach, beforeEach, expect, test } from "bun:test"
import { mkdir, mkdtemp, readFile, readdir, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { realEnv } from "../runtime/env"
import type { Io } from "./ctx"
import { run } from "./run"
import { verbs } from "./verbs"

const repoRoot = join(import.meta.dir, "..", "..")
const DEVICE = '{"id":"toybox","platform":"linux","match":{"hostname":"toyhost"},"facets":["toy"],"ignore":[]}'
let dir: string
let out: string[]
let err: string[]

function io(): Io {
  return {
    out: (line) => out.push(line),
    err: (line) => err.push(line),
    stdin: async () => "from stdin",
    now: () => new Date("2026-11-25T04:12:00Z"),
    hostname: () => "toyhost",
  }
}

async function exec(root: string, ...argv: string[]): Promise<number> {
  out = []
  err = []
  return run(argv, { root, io: io(), env: realEnv(root, () => {}) })
}

beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "dev-"))
  await mkdir(join(dir, "devices/toybox"), { recursive: true })
  await mkdir(join(dir, "inbox"), { recursive: true })
  await writeFile(join(dir, "devices/toybox/device.json"), DEVICE)
})

afterEach(async () => {
  await rm(dir, { recursive: true, force: true })
})

test("describe --json lists every verb with usage and the exit codes", async () => {
  expect(await exec(repoRoot, "describe", "--json")).toBe(0)
  expect(out.length).toBe(1)
  const data = JSON.parse(out[0] ?? "")
  expect(data.verbs.map((v: { name: string }) => v.name)).toEqual(verbs.map((v) => v.name))
  expect(data.verbs.every((v: { usage: string }) => v.usage.length > 0)).toBe(true)
  expect(Object.keys(data.exit)).toEqual(["0", "1", "2", "3", "4", "5"])
  expect(data.schemas.item.properties.id).toBeDefined()
})

test("the repo passes its own check", async () => {
  expect(await exec(repoRoot, "check")).toBe(0)
})

test("usage errors exit 2 and --json reports them as one document", async () => {
  expect(await exec(dir, "nope")).toBe(2)
  expect(await exec(dir, "check", "--bogus")).toBe(2)
  expect(await exec(dir, "nope", "--json")).toBe(2)
  expect(JSON.parse(out[0] ?? "").code).toBe(2)
})

test("a host that matches no device is a precondition failure", async () => {
  await rm(join(dir, "devices/toybox/device.json"))
  expect(await exec(dir, "drift")).toBe(3)
})

test("want add and rm edit the state file in canonical form", async () => {
  expect(await exec(dir, "want", "add", "toy:b", "--facet", "toy", "--set", "value=2")).toBe(0)
  expect(await exec(dir, "want", "add", "toy:a", "--facet", "toy", "--set", "on=true")).toBe(0)
  const path = join(dir, "devices/toybox/state/toy.jsonl")
  expect(await readFile(path, "utf8")).toBe(
    '{"id":"toy:a","a":{"on":true}}\n{"id":"toy:b","a":{"value":2}}\n',
  )
  expect(await exec(dir, "want", "rm", "toy:a")).toBe(0)
  expect(await readFile(path, "utf8")).toBe('{"id":"toy:b","a":{"value":2}}\n')
  expect(await exec(dir, "want", "rm", "toy:a")).toBe(3)
})

test("outbox put, show and ack round trip a message", async () => {
  const put = ["outbox", "put", "--to", "desktop", "--subject", "hello", "--ref", "toy:a"]
  expect(await exec(dir, ...put)).toBe(0)
  const name = "20261125T041200Z-hello"
  const text = await readFile(join(dir, "outbox", `${name}.md`), "utf8")
  expect(text).toBe("---\nfrom: toyhost\nto: desktop\nkind: note\nrefs: toy:a\n---\n\nfrom stdin\n")
  expect(await exec(dir, "outbox", "list", "--json")).toBe(0)
  expect(JSON.parse(out[0] ?? "").entries[0].to).toBe("desktop")
  expect(await exec(dir, "outbox", "ack", name)).toBe(0)
  expect(await readdir(join(dir, "outbox"))).toEqual([])
})

test("inbox lists non-message files by name without parsing them", async () => {
  await writeFile(join(dir, "inbox/bundle.zip"), "x")
  expect(await exec(dir, "inbox", "list", "--json")).toBe(0)
  expect(JSON.parse(out[0] ?? "").entries).toEqual([{ name: "bundle.zip", kind: "file" }])
})
