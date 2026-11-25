import { InputError } from "./errors"

export function archiveName(rootName: string, shortSha: string, now: Date, wanted?: string): string {
  const base = wanted?.trim() ?? ""
  if (base !== "") {
    if (!/^[A-Za-z0-9._-]+$/.test(base)) {
      throw new InputError("export name may only contain letters, digits, dot, underscore and dash")
    }
    return base.toLowerCase().endsWith(".zip") ? base : base + ".zip"
  }
  const stamp = now.toISOString().slice(0, 10).replaceAll("-", "")
  return `${rootName}-${shortSha}-${stamp}.zip`
}