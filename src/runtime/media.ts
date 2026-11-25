import { existsSync } from "node:fs"

const MACHINE_WIDE = "C:\\Program Files\\FFmpeg\\bin\\ffmpeg.exe"

export function isWindows(): boolean {
  return process.platform === "win32"
}

export function ffmpegArgv(argv: readonly string[]): string[] {
  const rest = argv.slice(1)
  if (!isWindows()) return ["toolbox", "run", "ffmpeg", ...rest]
  return [existsSync(MACHINE_WIDE) ? MACHINE_WIDE : "ffmpeg", ...rest]
}