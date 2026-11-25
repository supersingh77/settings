import { expect, test } from "bun:test"
import { archiveName } from "./export"

const now = new Date("2026-11-26T02:40:30Z")

test("the default export names include the repo, commit and date", () => {
  expect(archiveName("settings", "4e0811a", now)).toBe("settings-4e0811a-20261126.zip")
})

test("a requested name is kept and gets a zip suffix", () => {
  expect(archiveName("settings", "abc1234", now, "handoff")).toBe("handoff.zip")
  expect(archiveName("settings", "abc1234", now, "handoff.ZIP")).toBe("handoff.ZIP")
})

test("unsafe export names are rejected", () => {
  expect(() => archiveName("settings", "abc", now, "../escape")).toThrow()
  expect(() => archiveName("settings", "abc", now, "a b")).toThrow()
})