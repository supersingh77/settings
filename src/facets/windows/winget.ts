import type { Change, Facet } from "../../core/facet"
import type { Item, Scalar, Step } from "../../core/types"

type WingetExport = {
  Sources?: Array<{
    Packages?: Array<{ PackageIdentifier?: string; Version?: string }>
    SourceDetails?: { Name?: string }
  }>
}

function parseExport(stdout: string): Item[] {
  const data = JSON.parse(stdout) as WingetExport
  const byId = new Map<string, Item>()
  for (const src of data.Sources ?? []) {
    const source = src.SourceDetails?.Name ?? "winget"
    for (const pkg of src.Packages ?? []) {
      const id = pkg.PackageIdentifier?.trim()
      if (!id) continue
      const o: Record<string, Scalar> = pkg.Version ? { version: pkg.Version } : {}
      byId.set(`winget:${id}`, {
        id: `winget:${id}`,
        a: { source },
        ...(Object.keys(o).length > 0 ? { o } : {}),
      })
    }
  }
  return [...byId.values()].sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

function planChange(change: Change): Step[] {
  const pkg = change.id.replace(/^winget:/, "")
  if (change.kind === "remove") {
    return [{
      id: `winget:remove:${pkg}`,
      item: change.id,
      argv: ["winget.exe", "uninstall", "--id", pkg, "--exact"],
      destructive: true,
    }]
  }
  const source = typeof change.want?.a.source === "string" ? change.want.a.source : "winget"
  return [{
    id: `winget:install:${pkg}`,
    item: change.id,
    argv: [
      "winget.exe",
      "install",
      "--id",
      pkg,
      "--source",
      source,
      "--exact",
      "--accept-package-agreements",
      "--accept-source-agreements",
    ],
    destructive: false,
  }]
}

export const winget: Facet = {
  name: "winget",
  mode: "managed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/winget.ps1"] }),
  parse: parseExport,
  plan: planChange,
}
