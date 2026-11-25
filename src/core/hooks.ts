export const MARKER = "src/shellrc"
export const LEGACY_MARKER = "device/fedora-laptop/shellrc"
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

function withoutHook(text: string): string {
  return text
    .split("\n")
    .filter((line) => !line.includes("SETTINGS_ROOT=") && !line.includes(MARKER) && !line.includes(LEGACY_MARKER))
    .join("\n")
    .replace(/\n{3,}/g, "\n\n")
    .replace(/^\n+/, "")
    .replace(/\n+$/, "")
}

export function withBashrcHook(text: string, repoRoot: string): string {
  const hook = bashrcHook(repoRoot)
  const rest = withoutHook(text)
  return rest === "" ? hook : rest + "\n" + hook
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