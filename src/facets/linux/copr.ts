import type { Change, Facet } from "../../core/facet"
import type { Item, Step } from "../../core/types"

const REPO = /^_copr:(?:copr\.fedorainfracloud\.org:)?([^:]+):([^:]+)\.repo$/
const SAFE = /^[A-Za-z0-9][A-Za-z0-9._+-]*$/

function parseRepos(stdout: string): Item[] {
  const items: Item[] = []
  for (const line of stdout.split("\n")) {
    const match = REPO.exec(line.trim())
    if (match?.[1] && match[2]) items.push({ id: `copr:${match[1]}/${match[2]}`, a: {} })
  }
  return items
}

function destFile(owner: string, project: string): string {
  return `/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:${owner}:${project}.repo`
}

function addScript(owner: string, project: string): string {
  const dest = destFile(owner, project)
  const url = `https://copr.fedorainfracloud.org/coprs/${owner}/${project}/repo/fedora-$v/${owner}-${project}-fedora-$v.repo`
  return `v=$(sed -n 's/^VERSION_ID="\\(.*\\)"/\\1/p' /etc/os-release); curl -fsSL -o "${dest}" "${url}"`
}

function planChange(change: Change): Step[] {
  const [owner, project, ...rest] = change.id.slice("copr:".length).split("/")
  if (!owner || !project || rest.length > 0 || !SAFE.test(owner) || !SAFE.test(project)) return []
  if (change.kind === "remove") {
    return [{
      id: `${change.id}:remove`,
      item: change.id,
      argv: ["rm", "-f", destFile(owner, project)],
      needs: "admin",
      destructive: true,
    }]
  }
  return [{
    id: `${change.id}:add`,
    item: change.id,
    argv: ["sh", "-c", addScript(owner, project)],
    needs: "admin",
    destructive: false,
  }]
}

export const copr: Facet = {
  name: "copr",
  mode: "managed",
  command: () => ({
    argv: ["find", "/etc/yum.repos.d", "-maxdepth", "1", "-name", "_copr*", "-printf", "%f\n"],
  }),
  parse: parseRepos,
  plan: planChange,
}
