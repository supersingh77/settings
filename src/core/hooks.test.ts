import { expect, test } from "bun:test"
import { PROFILE_LINE, bashrcHook, isRetiredLink, withBashrcHook, withProfileHook } from "./hooks"

const root = "/home/toy/settings"

test("the bashrc hook exports the repo root and sources the shellrc", () => {
  const text = withBashrcHook("", root)
  expect(text).toContain("export SETTINGS_ROOT='/home/toy/settings'")
  expect(text).toContain("src/shellrc")
  expect(withBashrcHook(text, root)).toBe(text)
})

test("an existing hook is refreshed instead of duplicated", () => {
  const text = withBashrcHook("", "/old")
  expect(withBashrcHook(text, "/new")).toContain("SETTINGS_ROOT='/new'")
  expect(withBashrcHook(text, "/new").split(bashrcHook("/new")).length).toBe(2)
})

test("the old device shellrc hook is migrated away", () => {
  const legacy = [
    "export SETTINGS_ROOT='/home/toy/settings'",
    'if [ -f "$SETTINGS_ROOT/device/fedora-laptop/shellrc" ]; then . "$SETTINGS_ROOT/device/fedora-laptop/shellrc"; fi',
    "alias ll='ls -l'",
    "",
  ].join("\n")
  const next = withBashrcHook(legacy, root)
  expect(next).not.toContain("device/fedora-laptop/shellrc")
  expect(next).toContain("src/shellrc")
  expect(next).toContain("alias ll='ls -l'")
  expect(withBashrcHook(next, root)).toBe(next)
})

test("the profile hook is only added once and skipped when bashrc is sourced", () => {
  expect(withProfileHook("")).toContain(PROFILE_LINE)
  expect(withProfileHook(PROFILE_LINE)).toBe(PROFILE_LINE)
  expect(withProfileHook("source ~/.bashrc\n")).toBe("source ~/.bashrc\n")
})

test("only the retired command links are removed", () => {
  expect(isRetiredLink("update-system", "/repo/device/fedora-laptop/scripts/update-system.py")).toBe(true)
  expect(isRetiredLink("start-dsh", "/repo/device/fedora-laptop/scripts/start-dsh.sh")).toBe(false)
  expect(isRetiredLink("launch-uad", "/repo/src/cli/main.ts")).toBe(false)
})