import { chmod, mkdir, mkdtemp, readFile, rename, rm, stat, writeFile } from "node:fs/promises"
import { dirname, join } from "node:path"
import type { InstallAction, RunResult } from "../../core/facet"
import { antigravityLatest, githubLatest, type Recipe } from "../../core/recipe"
import type { InstallContext } from "./context"
import { download, fetchJson } from "./download"
import { expander, integrate, pathsOf, type Paths } from "./integrate"

async function exists(path: string): Promise<boolean> {
  try {
    await stat(path)
    return true
  } catch {
    return false
  }
}

async function latest(recipe: Recipe): Promise<{ version: string; url: string }> {
  const source = recipe.source
  if (source.kind === "github") {
    const release = await fetchJson(`https://api.github.com/repos/${source.repo}/releases/latest`)
    return githubLatest(release as never, source.asset)
  }
  const releases = await fetchJson(source.api)
  return antigravityLatest(releases as never, source.download)
}

async function installedVersion(paths: Paths): Promise<string> {
  const path = paths.version ?? ""
  if (path === "") return ""
  try {
    return (await readFile(path, "utf8")).trim()
  } catch {
    return ""
  }
}

async function writeVersion(paths: Paths, version: string): Promise<void> {
  const path = paths.version ?? ""
  if (path === "") return
  await mkdir(dirname(path), { recursive: true })
  await writeFile(path, version + "\n")
}

async function putBinary(url: string, target: string): Promise<void> {
  await mkdir(dirname(target), { recursive: true })
  const partial = target + ".part"
  try {
    await download(url, partial)
    await chmod(partial, 0o755)
    await rm(target, { force: true })
    await rename(partial, target)
  } finally {
    await rm(partial, { force: true })
  }
}

async function putAppImage(url: string, target: string, ctx: InstallContext): Promise<void> {
  const parent = dirname(target)
  await mkdir(parent, { recursive: true })
  const scratch = await mkdtemp(join(parent, ".appimage-"))
  try {
    const image = join(scratch, "app.AppImage")
    await download(url, image)
    await chmod(image, 0o755)
    const result = await ctx.run({ argv: [image, "--appimage-extract"], cwd: scratch })
    const extracted = join(scratch, "squashfs-root")
    if (result.code !== 0 || !(await exists(extracted))) {
      throw new Error(`AppImage extraction failed: ${result.err.trim()}`)
    }
    await rm(target, { recursive: true, force: true })
    await rename(extracted, target)
  } finally {
    await rm(scratch, { recursive: true, force: true })
  }
}

async function putTarball(
  url: string,
  target: string,
  install: { replace: string; verify: string },
  ctx: InstallContext,
): Promise<void> {
  await mkdir(target, { recursive: true })
  const scratch = await mkdtemp(join(target, ".download-"))
  try {
    const archive = join(scratch, "payload.tar.gz")
    await download(url, archive)
    await rm(join(target, install.replace), { recursive: true, force: true })
    const result = await ctx.run({ argv: ["tar", "-xzf", archive, "-C", target] })
    if (result.code !== 0) throw new Error(`tar failed: ${result.err.trim()}`)
    if (!(await exists(join(target, install.verify)))) throw new Error("archive did not contain the expected binary")
  } finally {
    await rm(scratch, { recursive: true, force: true })
  }
}

async function refresh(ctx: InstallContext): Promise<void> {
  await ctx.run({ argv: ["update-desktop-database", join(ctx.home, ".local/share/applications")] })
  await ctx.run({ argv: ["gtk-update-icon-cache", "-f", "-t", join(ctx.home, ".local/share/icons/hicolor")] })
}

async function removeRecipe(recipe: Recipe, ctx: InstallContext): Promise<RunResult> {
  const paths = pathsOf(recipe, ctx.home)
  let changed = 0
  for (const path of new Set(Object.values(paths))) {
    if (!(await exists(path))) continue
    await rm(path, { recursive: true, force: true })
    ctx.say(`remove ${path}`)
    changed += 1
  }
  if (changed > 0) await refresh(ctx)
  return { code: 0, out: `removed ${recipe.id}`, err: "" }
}

async function installRecipe(recipe: Recipe, ctx: InstallContext): Promise<RunResult> {
  const paths = pathsOf(recipe, ctx.home)
  const release = await latest(recipe)
  const installed = await installedVersion(paths)
  let changed = 0
  if (!(await exists(paths.install ?? "")) || installed !== release.version) {
    ctx.say(`install ${recipe.id} ${release.version} (installed: ${installed || "none"})`)
    const target = paths.install ?? ""
    if (recipe.install.kind === "tarball") await putTarball(release.url, target, recipe.install, ctx)
    else if (recipe.install.kind === "appimage") await putAppImage(release.url, target, ctx)
    else await putBinary(release.url, target)
    await writeVersion(paths, release.version)
    changed += 1
  }
  changed += await integrate(recipe, ctx, expander(recipe, ctx, paths), paths)
  if (changed > 0) await refresh(ctx)
  return { code: 0, out: `installed ${recipe.id} ${release.version}`, err: "" }
}

export async function runRecipe(recipe: Recipe, action: InstallAction, ctx: InstallContext): Promise<RunResult> {
  try {
    if (action === "remove") return await removeRecipe(recipe, ctx)
    return await installRecipe(recipe, ctx)
  } catch (error) {
    return { code: 1, out: "", err: error instanceof Error ? error.message : String(error) }
  }
}
