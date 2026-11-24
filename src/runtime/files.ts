import { mkdir, readdir, readFile, rm, writeFile } from "node:fs/promises"
import { dirname, join, relative } from "node:path"
import { InputError, PreconditionError } from "../core/errors"
import { SCANNED_DIRS, SCANNED_FILES } from "../core/lint"
import type { SourceFile } from "../core/lint/types"
import { Device } from "../core/types"

const TEXT = /\.(ts|json|jsonl|md|txt)$/

function isMissing(error: unknown): boolean {
  return (error as { code?: string }).code === "ENOENT"
}

export async function listFiles(root: string, dir: string): Promise<string[]> {
  try {
    const entries = await readdir(join(root, dir), { recursive: true, withFileTypes: true })
    return entries
      .filter((entry) => entry.isFile())
      .map((entry) => relative(root, join(entry.parentPath, entry.name)).replaceAll("\\", "/"))
      .filter((path) => !path.includes("node_modules/"))
      .sort()
  } catch (error) {
    if (isMissing(error)) return []
    throw error
  }
}

async function isRoot(dir: string): Promise<boolean> {
  try {
    const pkg = JSON.parse(await readFile(join(dir, "package.json"), "utf8"))
    return pkg.name === "settings"
  } catch {
    return false
  }
}

export async function findRoot(start: string): Promise<string> {
  let dir = start
  while (!(await isRoot(dir))) {
    const parent = dirname(dir)
    if (parent === dir) throw new PreconditionError("not inside the settings repo")
    dir = parent
  }
  return dir
}

export async function loadSources(root: string): Promise<SourceFile[]> {
  const lists = await Promise.all(SCANNED_DIRS.map((dir) => listFiles(root, dir)))
  const paths = [...SCANNED_FILES, ...lists.flat()]
  const files: SourceFile[] = []
  for (const path of paths.filter((p) => TEXT.test(p))) {
    try {
      files.push({ path, text: await readFile(join(root, path), "utf8") })
    } catch (error) {
      if (!isMissing(error)) throw error
    }
  }
  return files
}

export async function listDevices(root: string): Promise<Device[]> {
  const found = await listFiles(root, "devices")
  const devices: Device[] = []
  for (const path of found.filter((p) => /^devices\/[^/]+\/device\.json$/.test(p))) {
    const parsed = Device.safeParse(JSON.parse(await readFile(join(root, path), "utf8")))
    if (!parsed.success) {
      throw new InputError(`${path}: ${parsed.error.issues[0]?.message ?? "invalid device"}`)
    }
    devices.push(parsed.data)
  }
  return devices
}

export async function listBox(root: string, box: string): Promise<string[]> {
  const names = await listFiles(root, box)
  return names.map((path) => path.slice(box.length + 1)).filter((name) => !name.startsWith("."))
}

export async function readBox(root: string, box: string, name: string): Promise<string> {
  return readFile(join(root, box, name), "utf8")
}

export async function removeFromBox(root: string, box: string, name: string): Promise<void> {
  await rm(join(root, box, name))
}

export async function writeToBox(root: string, box: string, name: string, text: string): Promise<void> {
  await mkdir(join(root, box), { recursive: true })
  await writeFile(join(root, box, name), text)
}
