import { mkdir, readFile, writeFile } from "node:fs/promises"
import { homedir } from "node:os"
import { dirname, join } from "node:path"
import { type Cmd, type Env, type RunResult, wrap } from "../core/facet"
import { runRecipe } from "./recipe/install"

function isMissing(error: unknown): boolean {
  return (error as { code?: string }).code === "ENOENT"
}

async function toolboxName(): Promise<string> {
  try {
    const text = await readFile("/etc/os-release", "utf8")
    const version = /^VERSION_ID="?([^"\n]+)"?$/m.exec(text)?.[1]
    return version ? `fedora-toolbox-${version}` : ""
  } catch {
    return ""
  }
}

export function realEnv(root: string, say: (line: string) => void): Env {
  const run = async (cmd: Cmd): Promise<RunResult> => {
    try {
      const proc = Bun.spawn(wrap(cmd, process.platform), {
        cwd: cmd.cwd ?? root,
        stdin: "ignore",
        stdout: "pipe",
        stderr: "pipe",
      })
      const [out, err, code] = await Promise.all([
        new Response(proc.stdout).text(),
        new Response(proc.stderr).text(),
        proc.exited,
      ])
      return { code, out, err }
    } catch (error) {
      return { code: 127, out: "", err: String(error) }
    }
  }
  return {
    run,
    read: async (path) => {
      try {
        return await readFile(join(root, path), "utf8")
      } catch (error) {
        if (isMissing(error)) return null
        throw error
      }
    },
    write: async (path, text) => {
      const full = join(root, path)
      await mkdir(dirname(full), { recursive: true })
      await writeFile(full, text)
    },
    say,
    install: async (recipe, action) =>
      runRecipe(recipe, action, {
        home: homedir(),
        toolbox: await toolboxName(),
        run,
        say,
      }),
  }
}
