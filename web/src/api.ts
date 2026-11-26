import { useCallback, useEffect, useState } from "react"

export type Scalar = string | number | boolean
export type Item = { id: string; a: Record<string, Scalar | Scalar[]>; o?: Record<string, Scalar> }
export type Device = {
  id: string
  platform: string
  match: { hostname?: string; board?: string; serial?: string }
  via?: string
  facets: string[]
  ignore: string[]
}
export type Task = { id: string; group: "update" | "cleanup"; argv: string[]; needs?: string; destructive: boolean }
export type Verb = { name: string; usage: string; mutates: "no" | "repo" | "host" }
export type Describe = {
  verbs: Verb[]
  flags: Record<string, string>
  exit: Record<string, string>
  devices: { id: string; platform: string; facets: string[] }[]
  facets: { platform: string; name: string }[]
  lint: string[]
  scanned: string[]
}
export type Violation = { rule: string; path: string; line: number; message: string }
export type Check = { files: number; violations: Violation[] }
export type DeviceDetail = { device: Device; tasks: Task[]; state: Record<string, Item[]> }
export type Recipe = { id: string } & Record<string, unknown>
export type Fixture = { platform: string; facet: string; name: string; path: string; raw: string; golden: string }
export type Note = { path: string; title: string; refs: string[]; body: string }
export type Mail = { name: string; id?: string; from?: string; to?: string; kind?: string; refs?: string[] }
export type MailBoxes = { inbox: Mail[]; outbox: Mail[] }
export type RunResult = { code: number; data?: unknown; out: string; err: string }

async function get<T>(path: string): Promise<T> {
  const response = await fetch(path)
  const body = (await response.json()) as T & { error?: string }
  if (!response.ok) throw new Error(body.error ?? response.statusText)
  return body
}

export const api = {
  describe: () => get<Describe>("/api/describe"),
  check: () => get<Check>("/api/check"),
  device: (id: string) => get<DeviceDetail>(`/api/device?id=${encodeURIComponent(id)}`),
  recipes: () => get<{ recipes: Recipe[] }>("/api/recipes"),
  fixtures: () => get<{ fixtures: Fixture[] }>("/api/fixtures"),
  notes: () => get<{ notes: Note[] }>("/api/notes"),
  mail: () => get<MailBoxes>("/api/mail"),
  run: async (argv: string[]): Promise<RunResult> => {
    const response = await fetch("/api/run", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ argv }),
    })
    const body = (await response.json()) as RunResult & { error?: string }
    if (!response.ok) return { code: 5, out: "", err: body.error ?? response.statusText }
    return body
  },
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

export function formatRecord(record: Record<string, Scalar | Scalar[]> | undefined): string {
  if (!record) return ""
  return Object.entries(record)
    .map(([key, value]) => `${key}=${Array.isArray(value) ? value.join(",") : String(value)}`)
    .join("  ")
}
