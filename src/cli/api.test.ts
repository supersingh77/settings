import { describe, expect, test } from "bun:test"
import { findRoot } from "../runtime/files"
import { blocked, fixtures, notes, runArgv } from "./api"

const root = await findRoot(process.cwd())

describe("web api", () => {
  test("host-changing verbs need --dry-run", () => {
    expect(blocked(["restore", "--json"])).toContain("--dry-run")
    expect(blocked(["restore", "--dry-run"])).toBeUndefined()
    expect(blocked(["check"])).toBeUndefined()
  })

  test("runArgv captures json output and exit code", async () => {
    const result = await runArgv(root, ["check", "--json"])
    expect(result.code).toBe(0)
    expect((result.data as { violations: unknown[] }).violations).toEqual([])
  })

  test("fixtures expose platform, facet and golden text", async () => {
    const { fixtures: found } = (await fixtures(root)) as { fixtures: { platform: string; facet: string; golden: string }[] }
    const winget = found.find((entry) => entry.facet === "winget")
    expect(winget?.platform).toBe("windows")
    expect(winget?.golden).not.toBe("")
  })

  test("notes carry refs from front matter", async () => {
    const { notes: found } = (await notes(root)) as { notes: { path: string; refs: string[] }[] }
    expect(found.find((entry) => entry.path === "notes/upower-battery.md")?.refs.length).toBeGreaterThan(0)
  })
})
