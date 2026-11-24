export type FrontMatter = { head: Record<string, string>; body: string }

export function parseFrontMatter(text: string): FrontMatter | null {
  const lines = text.split("\n")
  if (lines[0] !== "---") return null
  const end = lines.indexOf("---", 1)
  if (end < 0) return null
  const head: Record<string, string> = {}
  for (const line of lines.slice(1, end)) {
    const colon = line.indexOf(":")
    if (colon > 0) head[line.slice(0, colon).trim()] = line.slice(colon + 1).trim()
  }
  return { head, body: lines.slice(end + 1).join("\n") }
}

export function splitRefs(value: string | undefined): string[] {
  return (value ?? "")
    .split(",")
    .map((ref) => ref.trim())
    .filter((ref) => ref !== "")
}
