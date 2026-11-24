import { mkdir, readFile, writeFile } from "node:fs/promises"
import { dirname, join } from "node:path"
import { type Env, wrap } from "../core/facet"

function isMissing(error: unknown): boolean {
  return (error as { code?: string }).code === "ENOENT"
}

export function realEnv(root: string, say: (line: string) => void): Env {
  return {
    run: async (cmd) => {
      try {
        const proc = Bun.spawn(wrap(cmd, process.platform), {
          cwd: root,
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
    },
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
  }
}
