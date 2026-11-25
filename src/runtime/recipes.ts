import { readFile } from "node:fs/promises"
import { homedir } from "node:os"
import { join } from "node:path"
import { InputError } from "../core/errors"
import type { Repo } from "../core/facet"
import { Recipe } from "../core/recipe"
import { listFiles } from "./files"

export async function loadRepo(root: string): Promise<Repo> {
  const paths = (await listFiles(root, "recipes")).filter((path) => path.endsWith(".json"))
  const recipes: Recipe[] = []
  for (const path of paths) {
    let raw: unknown
    try {
      raw = JSON.parse(await readFile(join(root, path), "utf8"))
    } catch (error) {
      throw new InputError(`${path}: ${error instanceof Error ? error.message : error}`)
    }
    const parsed = Recipe.safeParse(raw)
    if (!parsed.success) throw new InputError(`${path}: ${parsed.error.issues[0]?.message ?? "invalid recipe"}`)
    if (`recipes/${parsed.data.id}.json` !== path) throw new InputError(`${path}: id must match the file name`)
    recipes.push(parsed.data)
  }
  return { home: homedir(), recipes }
}
