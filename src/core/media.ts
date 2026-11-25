export type MediaCommand = { output: string; argv: string[] }

export const EXTENSIONS = [".mp4", ".mkv", ".mov", ".avi", ".webm", ".ts"]
export const DEFAULT_OUTPUT = "joined.mp4"
export const AUDIO_BITRATE = "256k"

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

export function extractAudio(video: string): MediaCommand {
  const output = joinPath(directoryOf(video), stem(video) + "_audio.m4a")
  return { output, argv: ["ffmpeg", "-i", video, "-vn", "-c:a", "copy", output] }
}

export function mergeAudio(video: string, audio: string, bitrate = AUDIO_BITRATE): MediaCommand {
  const output = joinPath(directoryOf(video), stem(video) + "_denoised.mp4")
  return {
    output,
    argv: [
      "ffmpeg", "-y", "-i", video, "-i", audio,
      "-c:v", "copy", "-c:a", "aac", "-b:a", bitrate,
      "-map", "0:v:0", "-map", "1:a:0", output,
    ],
  }
}

export function selectClips(names: readonly string[], output: string): string[] {
  return names
    .filter((name) => EXTENSIONS.includes(name.slice(name.lastIndexOf(".")).toLowerCase()) && name !== output)
    .sort()
}

export function concatList(folder: string, clips: readonly string[]): string {
  const lines = clips.map((clip) => {
    const path = joinPath(folder, clip).replaceAll("'", "'\\''")
    return `file '${path}'`
  })
  return lines.join("\n") + "\n"
}

export function joinCommand(listPath: string, output: string): string[] {
  return ["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", listPath, "-c", "copy", output]
}
