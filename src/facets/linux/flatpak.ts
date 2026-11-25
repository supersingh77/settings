import type { Change, Facet } from "../../core/facet"
import type { Item, Step } from "../../core/types"

const APP_ID = /^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)+$/

function parseFlatpaks(stdout: string): Item[] {
  const items: Item[] = []
  for (const line of stdout.split("\n")) {
    if (line.trim() === "") continue
    const cells = line.split("\t").map((cell) => cell.trim())
    if (cells[0] === "Application ID") continue
    const [app, version = "", branch = "", origin = ""] = cells
    if (!app || !APP_ID.test(app) || cells.length !== 4 || !branch || !origin) {
      throw new Error(`unrecognized flatpak row: ${line}`)
    }
    items.push({
      id: `flatpak:${app}`,
      a: { origin, branch },
      ...(version === "" ? {} : { o: { version } }),
    })
  }
  return items
}

function planChange(change: Change): Step[] {
  const app = change.id.slice("flatpak:".length)
  if (change.kind === "remove") {
    return [{
      id: `${change.id}:remove`,
      item: change.id,
      argv: ["flatpak", "uninstall", "--system", "-y", app],
      needs: "admin",
      destructive: true,
    }]
  }
  const origin = typeof change.want?.a.origin === "string" ? change.want.a.origin : "flathub"
  const branch = typeof change.want?.a.branch === "string" ? change.want.a.branch : ""
  const target = change.kind === "modify" && branch !== "" ? `${app}//${branch}` : app
  return [{
    id: `${change.id}:install`,
    item: change.id,
    argv: ["flatpak", "install", "--system", "-y", origin, target],
    needs: "admin",
    destructive: false,
  }]
}

export const flatpak: Facet = {
  name: "flatpak",
  platform: "linux",
  mode: "managed",
  command: () => ({
    argv: ["flatpak", "list", "--system", "--app", "--columns=application,version,branch,origin"],
  }),
  parse: parseFlatpaks,
  plan: planChange,
}
