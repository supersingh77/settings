import { writeFile } from "node:fs/promises"

const USER_AGENT =
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

export async function fetchJson(url: string): Promise<unknown> {
  const response = await fetch(url, {
    headers: { "user-agent": USER_AGENT, accept: "application/json" },
    redirect: "follow",
  })
  if (!response.ok) throw new Error(`GET ${url}: ${response.status}`)
  return response.json()
}

export async function download(url: string, destination: string): Promise<void> {
  const response = await fetch(url, {
    headers: { "user-agent": USER_AGENT },
    redirect: "follow",
  })
  if (!response.ok || response.body === null) throw new Error(`GET ${url}: ${response.status}`)
  await writeFile(destination, new Uint8Array(await response.arrayBuffer()))
}
