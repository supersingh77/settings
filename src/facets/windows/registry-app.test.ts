import { expect, test } from "bun:test"
import { normalizeAppName, registryApp } from "./registry-app"

test("version suffixes are stripped from ids", () => {
  expect(normalizeAppName("ExitLag version 5.23.3")).toBe("ExitLag")
  expect(normalizeAppName("Focusrite Audio Drivers 4.150.0.432")).toBe("Focusrite Audio Drivers")
  expect(normalizeAppName("Focusrite Control 2 1.1210.0.0")).toBe("Focusrite Control 2")
  expect(normalizeAppName("7-Zip 26.06 (x64)")).toBe("7-Zip (x64)")
})

test("names without a version are unchanged", () => {
  expect(normalizeAppName("Git")).toBe("Git")
  expect(normalizeAppName("AMD Software")).toBe("AMD Software")
})

test("the parser keeps the raw display name and collapses duplicate ids", () => {
  const stdout = JSON.stringify([
    { name: "ExitLag version 5.23.3", version: "5.23.3" },
    { name: "ExitLag version 5.24.0", version: "5.24.0" },
    { name: "Git", version: "" },
  ])
  expect(registryApp.parse(stdout)).toEqual([
    { id: "reg:ExitLag", a: {}, o: { raw: "ExitLag version 5.23.3", version: "5.23.3" } },
    { id: "reg:Git", a: {}, o: { raw: "Git" } },
  ])
})