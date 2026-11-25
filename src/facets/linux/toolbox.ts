import type { Change, Facet } from "../../core/facet"
import type { Item, Step } from "../../core/types"

const PACKAGES = ["7zip", "7zip-standalone", "android-tools", "ffmpeg-free", "gh"]

const SCRIPT = [
  "v=$(sed -n 's/^VERSION_ID=//p' /etc/os-release | sed 's/\"//g')",
  "c=fedora-toolbox-$v",
  "podman ps --all --format '{{.Names}}' | grep -qx \"$c\" || c=",
  "printf 'container\\t%s\\n' \"$c\"",
  "if [ -n \"$c\" ]; then toolbox run --container \"$c\" rpm -q --qf '%{NAME}\\t%{VERSION}-%{RELEASE}\\n' 7zip 7zip-standalone android-tools ffmpeg-free gh || true; fi",
].join("\n")

function parseToolbox(stdout: string): Item[] {
  const versions = new Map<string, string>()
  let container = ""
  for (const line of stdout.split("\n")) {
    const [key = "", value = ""] = line.split("\t")
    if (key === "container") container = value
    else if (PACKAGES.includes(key) && value !== "") versions.set(key, value)
  }
  const items: Item[] = []
  if (container !== "") items.push({ id: "container:" + container, a: {} })
  for (const name of PACKAGES) {
    const version = versions.get(name)
    items.push(
      version === undefined
        ? { id: "toolbox-pkg:" + name, a: {} }
        : { id: "toolbox-pkg:" + name, a: {}, o: { version } },
    )
  }
  return items
}

function planChange(change: Change): Step[] {
  if (change.id.startsWith("container:")) {
    const name = change.id.slice("container:".length)
    const match = /^fedora-toolbox-([0-9]+)$/.exec(name)
    if (!match?.[1]) return []
    if (change.kind === "remove") {
      return [{ id: change.id + ":remove", item: change.id, argv: ["toolbox", "rm", "--force", name], destructive: true }]
    }
    const image = "registry.fedoraproject.org/fedora-toolbox:" + match[1]
    return [{ id: change.id + ":create", item: change.id, argv: ["toolbox", "create", "--assumeyes", "--container", name, "--image", image], destructive: false }]
  }
  if (!change.id.startsWith("toolbox-pkg:")) return []
  const pkg = change.id.slice("toolbox-pkg:".length)
  if (change.kind === "remove") {
    return [{ id: change.id + ":remove", item: change.id, argv: ["sudo", "dnf", "remove", "-y", pkg], needs: "toolbox", destructive: true }]
  }
  return [{ id: change.id + ":install", item: change.id, argv: ["sudo", "dnf", "install", "-y", pkg], needs: "toolbox", destructive: false }]
}

export const toolbox: Facet = {
  name: "toolbox",
  platform: "linux",
  mode: "managed",
  command: () => ({ argv: ["bash", "-c", SCRIPT] }),
  parse: parseToolbox,
  plan: planChange,
}
