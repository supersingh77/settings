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
