export const MARKER = "device/fedora-laptop/shellrc"
export const PROFILE_LINE = "[ -f ~/.bashrc ] && source ~/.bashrc"

function quoted(value: string): string {
  return value.replaceAll("'", "'\\''")
}

export function bashrcHook(repoRoot: string): string {
  return (
    "export SETTINGS_ROOT='" + quoted(repoRoot) + "'\n" +
    'if [ -f "$SETTINGS_ROOT/' + MARKER + '" ]; then . "$SETTINGS_ROOT/' + MARKER + '"; fi\n'
  )
}

export function withBashrcHook(text: string, repoRoot: string): string {
  const hook = bashrcHook(repoRoot)
  if (text.includes(MARKER)) {
    const lines = text.split("\n")
    for (const [index, line] of lines.entries()) {
      if (line.startsWith("export SETTINGS_ROOT=")) {
        lines[index] = hook.split("\n")[0] ?? ""
        return lines.join("\n")
      }
    }
    return text
  }
  const separator = text === "" || text.endsWith("\n") ? "" : "\n"
  return text + separator + "\n" + hook
}

export function withProfileHook(text: string): string {
  if (text.includes(".bashrc")) return text
  const separator = text === "" || text.endsWith("\n") ? "" : "\n"
  return text + separator + "\n" + PROFILE_LINE + "\n"
}

export const RETIRED_COMMANDS = [
  "update-system",
  "cleanup-system",
  "update-openwork",
  "update-uad",
  "update-antigravity",
  "launch-uad",
]

export function isRetiredLink(name: string, target: string): boolean {
  return RETIRED_COMMANDS.includes(name) && target.includes("device/fedora-laptop/scripts")
}
