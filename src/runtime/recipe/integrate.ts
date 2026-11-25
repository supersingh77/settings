import { chmod, mkdir, readFile, stat, writeFile } from "node:fs/promises"
import { dirname } from "node:path"
import { expand, type Recipe } from "../../core/recipe"
import { asarEntry } from "./asar"
import type { InstallContext } from "./context"
import { download } from "./download"

export type Paths = Record<string, string>

export function pathsOf(recipe: Recipe, home: string): Paths {
  return Object.fromEntries(
    Object.entries(recipe.paths).map(([key, template]) => [key, expand(template, { home })]),
  )
}

export function expander(recipe: Recipe, ctx: InstallContext, paths: Paths): (template: string) => string {
  return (template) => expand(template, { home: ctx.home, toolbox: ctx.toolbox, install: paths.install ?? "" })
}

async function exists(path: string): Promise<boolean> {
  try {
    await stat(path)
    return true
  } catch {
    return false
  }
}

async function ensureBytes(path: string, data: Uint8Array, mode: number, ctx: InstallContext): Promise<number> {
  await mkdir(dirname(path), { recursive: true })
  try {
    const current = await readFile(path)
    if (Buffer.compare(current, data) === 0) {
      await chmod(path, mode)
      return 0
    }
  } catch {
    ctx.say(`write ${path}`)
  }
  await writeFile(path, data)
  await chmod(path, mode)
  return 1
}

async function iconData(recipe: Recipe, expanded: (template: string) => string): Promise<Uint8Array | null> {
  const icon = recipe.icon
  if (!icon || icon.kind === "url") return null
  if (icon.kind === "file") {
    try {
      return await readFile(expanded(icon.source))
    } catch {
      return null
    }
  }
  return asarEntry(expanded(icon.asar), icon.entry)
}

async function ensureIcon(
  recipe: Recipe,
  ctx: InstallContext,
  expanded: (template: string) => string,
  paths: Paths,
): Promise<number> {
  const icon = recipe.icon
  const target = paths.icon
  if (!icon || !target) return 0
  if (icon.kind === "url") {
    if (await exists(target)) return 0
    ctx.say(`download icon ${target}`)
    try {
      await download(icon.url, target)
    } catch (error) {
      ctx.say(`icon download skipped: ${error instanceof Error ? error.message : error}`)
    }
    return 1
  }
  const data = await iconData(recipe, expanded)
  return data === null ? 0 : ensureBytes(target, data, 0o644, ctx)
}

function launcherText(recipe: Recipe, expanded: (template: string) => string): string {
  const env = (recipe.launcher?.env ?? []).map(([name, value]) => `export ${name}=${expanded(value)}`)
  const command = expanded(recipe.launcher?.command ?? "")
  return ["#!/bin/bash", ...env, `exec ${command} "$@"`, ""].join("\n")
}

function desktopText(recipe: Recipe, expanded: (template: string) => string): string {
  const rows = (recipe.desktop ?? []).map(([key, value]) => `${key}=${expanded(value)}`)
  return ["[Desktop Entry]", ...rows, ""].join("\n")
}

export async function integrate(
  recipe: Recipe,
  ctx: InstallContext,
  expanded: (template: string) => string,
  paths: Paths,
): Promise<number> {
  let changed = 0
  if (recipe.launcher && paths.launcher) {
    changed += await ensureBytes(paths.launcher, Buffer.from(launcherText(recipe, expanded)), 0o755, ctx)
  }
  if (recipe.desktop && paths.desktop) {
    changed += await ensureBytes(paths.desktop, Buffer.from(desktopText(recipe, expanded)), 0o644, ctx)
  }
  changed += await ensureIcon(recipe, ctx, expanded, paths)
  return changed
}
