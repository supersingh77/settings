export type Level = { mean: number | null; peak: number | null }
export type Loudness = { lufs: number | null; lra: number | null; peak: number | null }

export type LevelRow = {
  file: string
  snrDb: number | null
  noiseDb: number | null
  voiceDb: number | null
  peakDb: number | null
  lufs: number | null
  lra: number | null
  bodyDb: number | null
  midDb: number | null
  highDb: number | null
}

export const AUDIO_EXTENSIONS = [".wav", ".m4a", ".mp3", ".flac", ".mp4", ".mkv", ".opus"]

export function audioFiles(names: readonly string[]): string[] {
  return names
    .filter((name) => AUDIO_EXTENSIONS.includes(name.slice(name.lastIndexOf(".")).toLowerCase()))
    .sort()
}

function sink(windows: boolean): string {
  return windows ? "NUL" : "-"
}

export function listDevicesCommand(): string[] {
  return ["ffmpeg", "-hide_banner", "-list_devices", "true", "-f", "dshow", "-i", "dummy"]
}

export function parseDeviceList(text: string): string[] {
  const names = new Set<string>()
  for (const line of text.split("\n")) {
    if (line.includes("Alternative name")) continue
    const name = /"([^"]+)"\s+\(audio\)/.exec(line)?.[1]?.trim()
    if (name) names.add(name)
  }
  return [...names].sort()
}

export function micCommand(device: string, seconds: number, windows: boolean): string[] {
  return [
    "ffmpeg", "-hide_banner", "-v", "info", "-f", "dshow", "-i", "audio=" + device,
    "-t", String(seconds), "-af", "volumedetect", "-f", "null", sink(windows),
  ]
}

export function volumedetectCommand(
  file: string,
  windows: boolean,
  options: { start?: number; seconds?: number; filter?: string } = {},
): string[] {
  const segment = [
    ...(options.start === undefined ? [] : ["-ss", String(options.start)]),
    ...(options.seconds === undefined ? [] : ["-t", String(options.seconds)]),
  ]
  const filter = options.filter ? options.filter + ",volumedetect" : "volumedetect"
  return ["ffmpeg", "-hide_banner", "-v", "info", "-i", file, ...segment, "-af", filter, "-f", "null", sink(windows)]
}

export function loudnessCommand(file: string, windows: boolean): string[] {
  return ["ffmpeg", "-hide_banner", "-v", "info", "-i", file, "-af", "ebur128=peak=true", "-f", "null", sink(windows)]
}

function level(text: string, key: string): number | null {
  const match = new RegExp(key + ":\\s+(-?[\\d.]+|-inf)").exec(text)
  const value = match?.[1]
  if (value === undefined) return null
  return value === "-inf" ? -100 : Number(value)
}

export function parseVolumedetect(text: string): Level {
  return { mean: level(text, "mean_volume"), peak: level(text, "max_volume") }
}

export function parseLoudness(text: string): Loudness {
  const integrated = /\bI:\s+(-?[\d.]+|-inf) LUFS/.exec(text)?.[1]
  const range = /\bLRA:\s+(-?[\d.]+) LU/.exec(text)?.[1]
  return {
    lufs: integrated === undefined || integrated === "-inf" ? null : Number(integrated),
    lra: range === undefined ? null : Number(range),
    peak: level(text, "Peak"),
  }
}

export function captureVerdict(mean: number | null, peak: number | null): string {
  if (mean === null) return "FAILED to open"
  if (mean <= -70) return "SILENT - muted, dead, or privacy-blocked"
  if (mean <= -50) return "very quiet - raise the mic level"
  if (mean <= -30) return "quiet - usable with gain"
  if (peak !== null && peak > -3) return "hot - close to clipping"
  return "healthy"
}

export function levelsVerdict(row: LevelRow): string {
  const notes: string[] = []
  if (row.snrDb !== null) {
    if (row.snrDb < 3) notes.push("no silent lead-in - pattern not followed")
    else if (row.snrDb >= 30) notes.push("clean")
    else if (row.snrDb >= 20) notes.push("usable")
    else notes.push("NOISY")
  }
  if (row.peakDb !== null && row.peakDb > -3) notes.push("near clipping")
  if (row.lufs !== null && row.lufs < -30) notes.push("too quiet")
  if (row.highDb !== null && row.midDb !== null && row.highDb - row.midDb > 6) notes.push("harsh/sibilant")
  if (row.bodyDb !== null && row.midDb !== null && row.bodyDb - row.midDb > 12) notes.push("boomy")
  return notes.length > 0 ? notes.join(", ") : "balanced"
}