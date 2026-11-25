import type { Cmd, RunResult } from "../../core/facet"

export type InstallContext = {
  home: string
  toolbox: string
  run: (cmd: Cmd) => Promise<RunResult>
  say: (line: string) => void
}
