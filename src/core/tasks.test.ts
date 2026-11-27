import { expect, test } from "bun:test"
import { failureSummary } from "./facet"
import { planTasks } from "./tasks"
import type { Task } from "./types"

const tasks: Task[] = [
  { id: "flatpak-update", group: "update", argv: ["flatpak", "update", "-y"], needs: "admin", destructive: false },
  { id: "trash-empty", group: "cleanup", argv: ["gio", "trash", "--empty"], destructive: true },
]

test("tasks are filtered by group and keep their needs", () => {
  const update = planTasks("toybox", tasks, "update")
  expect(update.steps).toEqual([{ id: "flatpak-update", argv: ["flatpak", "update", "-y"], needs: "admin", destructive: false }])
  const cleanup = planTasks("toybox", tasks, "cleanup")
  expect(cleanup.steps[0]?.destructive).toBe(true)
  expect(cleanup.group).toBe("cleanup")
})

test("failureSummary falls back from stderr to stdout last line to exit code", () => {
  expect(failureSummary({ code: 0, out: "ignored", err: "ignored" })).toBe("")
  expect(failureSummary({ code: 1, out: "out", err: "\nboom\nmore" })).toBe("boom")
  expect(failureSummary({ code: 2, out: "spinner\r\nNo available upgrade found.\r\n", err: "" })).toBe("No available upgrade found.")
  expect(failureSummary({ code: 42, out: "", err: "   " })).toBe("exit 42")
})
