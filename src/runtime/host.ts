import { readFile } from "node:fs/promises"

export async function boardName(): Promise<string> {
  try {
    return (await readFile("/sys/class/dmi/id/board_name", "utf8")).trim()
  } catch {
    return ""
  }
}
