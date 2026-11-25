export type MediaCommand = { output: string; argv: string[] }

export const AUDIO_BITRATE = "192k"

function directoryOf(path: string): string {
  const at = path.lastIndexOf("/")
  return at < 0 ? "" : path.slice(0, at)
}

function baseName(path: string): string {
  const at = path.lastIndexOf("/")
  return at < 0 ? path : path.slice(at + 1)
}

function stem(path: string): string {
  const name = baseName(path)
  const dot = name.lastIndexOf(".")
  return dot <= 0 ? name : name.slice(0, dot)
}

function joinPath(directory: string, name: string): string {
  return directory === "" ? name : directory + "/" + name
}

export function extractAudio(video: string, output?: string): MediaCommand {
  const target = output ?? joinPath(directoryOf(video), stem(video) + "_audio.m4a")
  return { output: target, argv: ["ffmpeg", "-i", video, "-vn", "-c:a", "copy", target] }
}

export function remuxAudio(video: string, audio: string, output?: string): MediaCommand {
  const target = output ?? joinPath(directoryOf(video), stem(video) + "_remuxed.mp4")
  const argv = [
    "ffmpeg", "-y", "-i", video, "-i", audio,
    "-map", "0:v:0", "-map", "1:a:0",
    "-c:v", "copy", "-c:a", "aac", "-b:a", AUDIO_BITRATE,
    "-movflags", "+faststart", target,
  ]
  return { output: target, argv }
}

export function denoiseAudio(video: string, output?: string): MediaCommand {
  const target = output ?? joinPath(directoryOf(video), stem(video) + "_denoised.mp4")
  const argv = [
    "ffmpeg", "-y", "-i", video,
    "-map", "0:v:0", "-map", "0:a:0",
    "-c:v", "copy", "-af", "afftdn", "-c:a", "aac", "-b:a", AUDIO_BITRATE,
    "-movflags", "+faststart", target,
  ]
  return { output: target, argv }
}

export type JoinCommand = { output: string; list: string; argv: string[] }

export function joinPair(first: string, second: string, output?: string): JoinCommand {
  const target = output ?? joinPath(directoryOf(first), stem(first) + "_joined.mp4")
  const list = target + ".list"
  return {
    output: target,
    list,
    argv: ["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", list, "-c", "copy", target],
  }
}

export function concatText(paths: readonly string[]): string {
  return paths.map((path) => `file '${path.replaceAll("'", "'\\''")}'`).join("\n") + "\n"
}