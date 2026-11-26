import { describe, expect, test } from "bun:test"
import { readdir, readFile } from "node:fs/promises"
import { join } from "node:path"
import { verbs as client } from "../../web/src/verbs"
import { findRoot } from "../runtime/files"
import { runArgv } from "./api"
import { parseArgs } from "./args"
import { verbs } from "./verbs"

const root = await findRoot(process.cwd())

const reads: Record<string, string[]> = {
  describe: client.describe(),
  check: client.check(),
  device: client.device("desktop"),
  state: client.state("desktop", "winget", "git", "all"),
  stateObserved: client.state("desktop", "winget", "", "observed"),
  recipes: client.recipes(),
  recipe: client.recipe("uad-ng"),
  fixtures: client.fixtures("windows"),
  fixture: client.fixture("windows/winget/desktop"),
  notes: client.notes("battery"),
  note: client.note("notes/upower-battery.md"),
  inbox: client.mail.list("inbox"),
  outbox: client.mail.list("outbox"),
  previewUpdate: client.preview("update", "desktop"),
}

const writes: string[][] = [
  client.want.add("desktop", "winget", "winget:X.Y", ["a=1"]),
  client.want.rm("desktop", "winget", "winget:X.Y"),
  client.mail.ack("inbox", "x"),
  client.mail.put("desktop", "slug", "note", "body"),
  client.mail.show("inbox", "x"),
]

describe("web client parity", () => {
  test("every web call names a real verb and parses as CLI arguments", () => {
    const names = new Set(verbs.map((verb) => verb.name))
    for (const argv of [...Object.values(reads), ...writes]) {
      expect(names.has(parseArgs(argv).verb ?? "")).toBe(true)
    }
  })

  test("every read call succeeds through the same run() the CLI uses", async () => {
    for (const [name, argv] of Object.entries(reads)) {
      const result = await runArgv(root, argv)
      expect([name, result.code <= 1]).toEqual([name, true])
      expect(result.data).toBeDefined()
    }
  })

  test("the web policy keeps host-changing verbs in dry-run", async () => {
    const refused = await runArgv(root, ["restore", "--json"])
    expect(refused.code).toBe(2)
    expect((refused.data as { error: string }).error).toContain("--dry-run")
  })

  test("the web client only talks to /api/run", async () => {
    const files = await readdir(join(root, "web/src"), { recursive: true })
    for (const file of files.filter((name) => /\.tsx?$/.test(name))) {
      const text = await readFile(join(root, "web/src", file), "utf8")
      for (const found of text.match(/\/api\/[A-Za-z0-9_-]+/g) ?? []) expect(found).toBe("/api/run")
    }
  })

  test("write verbs run through the queue and report their errors", async () => {
    const results = await Promise.all([runArgv(root, ["inbox", "list", "--json"]), runArgv(root, ["want", "rm", "x:y", "--device", "desktop", "--json"])])
    expect(results[1]?.code).toBe(3)
  })
})
