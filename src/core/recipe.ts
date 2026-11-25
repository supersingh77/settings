import { z } from "zod"

const Template = z.string().min(1)
const Asset = z.strictObject({
  name: z.string().min(1).optional(),
  prefix: z.string().min(1).optional(),
  suffix: z.string().min(1).optional(),
})
const Source = z.discriminatedUnion("kind", [
  z.strictObject({ kind: z.literal("github"), repo: z.string().min(1), asset: Asset }),
  z.strictObject({ kind: z.literal("antigravity"), api: z.string().min(1), download: Template }),
])
const Paths = z.strictObject({
  install: Template,
  version: Template,
  launcher: Template.optional(),
  desktop: Template.optional(),
  icon: Template.optional(),
})
const Install = z.discriminatedUnion("kind", [
  z.strictObject({ kind: z.literal("tarball"), replace: z.string().min(1), verify: z.string().min(1) }),
  z.strictObject({ kind: z.literal("appimage") }),
  z.strictObject({ kind: z.literal("binary") }),
])
const Icon = z.discriminatedUnion("kind", [
  z.strictObject({ kind: z.literal("file"), source: Template }),
  z.strictObject({ kind: z.literal("asar"), asar: Template, entry: z.string().min(1) }),
  z.strictObject({ kind: z.literal("url"), url: z.string().min(1) }),
])
const Launcher = z.strictObject({
  env: z.array(z.tuple([z.string(), z.string()])),
  command: z.string().min(1),
})

export const Recipe = z.strictObject({
  id: z.string().regex(/^[a-z][a-z0-9-]*$/),
  source: Source,
  paths: Paths,
  install: Install,
  launcher: Launcher.optional(),
  icon: Icon.optional(),
  desktop: z.array(z.tuple([z.string(), z.string()])).optional(),
})
export type Recipe = z.infer<typeof Recipe>

export function expand(template: string, values: Record<string, string>): string {
  let text = template
  for (const [key, value] of Object.entries(values)) text = text.replaceAll("{" + key + "}", value)
  return text
}

export type Release = { tag_name?: string; assets?: Array<{ name?: string; browser_download_url?: string }> }
export type AssetRule = { name?: string; prefix?: string; suffix?: string }

export function matchAsset(release: Release, rule: AssetRule): string {
  for (const asset of release.assets ?? []) {
    const name = asset.name ?? ""
    const matched =
      rule.name !== undefined
        ? name === rule.name
        : rule.prefix !== undefined && rule.suffix !== undefined && name.startsWith(rule.prefix) && name.endsWith(rule.suffix)
    if (matched && asset.browser_download_url) return asset.browser_download_url
  }
  return ""
}

export function githubLatest(release: Release, rule: AssetRule): { version: string; url: string } {
  const version = (release.tag_name ?? "").replace(/^v/, "")
  const url = matchAsset(release, rule)
  if (version === "" || url === "") throw new Error("release has no version or no matching asset")
  return { version, url }
}

export type AntigravityRelease = { version?: string; execution_id?: string }

export function antigravityLatest(
  releases: readonly AntigravityRelease[],
  template: string,
): { version: string; url: string } {
  const newest = releases[0]
  if (!newest?.version || newest.execution_id === undefined) throw new Error("release list is empty")
  const version = newest.version + "-" + newest.execution_id
  return { version, url: expand(template, { version: newest.version, execution: newest.execution_id }) }
}
