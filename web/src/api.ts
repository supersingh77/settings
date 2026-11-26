import { useCallback, useEffect, useState } from "react"
import type { VerbInfo } from "../../src/cli/ctx"
import type { FixtureRef, Note, NoteSummary } from "../../src/core/browse"
import type { Device, Item, MessageHead, Scalar, Task } from "../../src/core/types"
import { verbs, type Box, type OnlyFilter } from "./verbs"

export type { Box, Device, Item, Note, NoteSummary, OnlyFilter, Scalar, Task, VerbInfo }

export type Describe = {
  verbs: VerbInfo[]
  flags: Record<string, string>
  exit: Record<string, string>
  devices: { id: string; platform: string; facets: string[] }[]
  lint: Record<string, string>
  scanned: string[]
}
export type Violation = { rule: string; group?: string; path: string; line: number; message: string }
export type Check = { files: number; violations: Violation[] }
export type DeviceDetail = { device: Device; tasks: Task[]; counts: Record<string, number> }
export type StateList = { device: string; facet: string; total: number; items: Item[] }
export type FixtureSummary = Omit<FixtureRef, "golden">
export type Fixture = FixtureSummary & { raw: string; golden: string }
export type Mail = { name: string; id?: string; from?: string; to?: string; kind?: string; refs?: string[] }
export type MailShow = { name: string; text: string; head?: MessageHead; body?: string }
export type RunResult = { code: number; data?: unknown; out: string; err: string }

async function post(argv: string[]): Promise<RunResult> {
  const response = await fetch("/api/run", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ argv }),
  })
  const body = (await response.json()) as RunResult & { error?: string }
  if (!response.ok) return { code: 5, out: "", err: body.error ?? response.statusText }
  return body
}

async function call<T>(argv: string[], ok: number[] = [0]): Promise<T> {
  const result = await post(argv)
  if (!ok.includes(result.code)) {
    const failure = (result.data as { error?: string } | undefined)?.error
    throw new Error(failure ?? (result.err || result.out || `exit ${result.code}`))
  }
  return result.data as T
}

export const api = {
  run: post,
  describe: () => call<Describe>(verbs.describe()),
  check: () => call<Check>(verbs.check(), [0, 1]),
  device: (id: string) => call<DeviceDetail>(verbs.device(id)),
  state: (device: string, facet: string, query: string, only: OnlyFilter) =>
    call<StateList>(verbs.state(device, facet, query, only)),
  recipes: () => call<{ recipes: string[] }>(verbs.recipes()),
  recipe: (id: string) => call<{ recipe: Record<string, unknown> }>(verbs.recipe(id)),
  fixtures: (platform: string) => call<{ fixtures: FixtureSummary[] }>(verbs.fixtures(platform)),
  fixture: (key: string) => call<{ fixture: Fixture }>(verbs.fixture(key)),
  notes: (query: string) => call<{ notes: NoteSummary[] }>(verbs.notes(query)),
  note: (path: string) => call<{ note: Note }>(verbs.note(path)),
  mail: (box: Box) => call<{ entries: Mail[] }>(verbs.mail.list(box)),
  mailShow: (box: Box, name: string) => call<MailShow>(verbs.mail.show(box, name)),
}

export function useLoad<T>(load: () => Promise<T>) {
  const [data, setData] = useState<T | undefined>()
  const [error, setError] = useState<string | undefined>()
  const [tick, setTick] = useState(0)
  useEffect(() => {
    let live = true
    load().then(
      (value) => {
        if (live) {
          setData(value)
          setError(undefined)
        }
      },
      (failure: unknown) => {
        if (live) setError(failure instanceof Error ? failure.message : String(failure))
      },
    )
    return () => {
      live = false
    }
  }, [load, tick])
  const reload = useCallback(() => setTick((value) => value + 1), [])
  return { data, error, reload }
}

export function useDebounced<T>(value: T, ms = 200): T {
  const [settled, setSettled] = useState(value)
  useEffect(() => {
    const timer = setTimeout(() => setSettled(value), ms)
    return () => clearTimeout(timer)
  }, [value, ms])
  return settled
}

export function formatRecord(record: Record<string, Scalar | Scalar[]> | undefined): string {
  if (!record) return ""
  return Object.entries(record)
    .map(([key, value]) => `${key}=${Array.isArray(value) ? value.join(",") : String(value)}`)
    .join("  ")
}
