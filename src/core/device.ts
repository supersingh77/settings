import { PreconditionError } from "./errors"
import type { Device } from "./types"

export function resolveDevice(
  devices: readonly Device[],
  hostname: string,
  requested?: string,
): Device {
  if (requested !== undefined) {
    const found = devices.find((device) => device.id === requested)
    if (!found) throw new PreconditionError(`unknown device ${requested}`)
    return found
  }
  const matches = devices.filter(
    (device) => device.match.hostname?.toLowerCase() === hostname.toLowerCase(),
  )
  if (matches.length === 1 && matches[0]) return matches[0]
  const known = devices.map((device) => device.id).join(", ") || "none"
  const reason = matches.length === 0 ? "no device matches" : "several devices match"
  throw new PreconditionError(`${reason} host ${hostname}; pass --device (known: ${known})`)
}
