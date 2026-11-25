import { readdir, stat, unlink, writeFile } from "node:fs/promises"
import { join as joinPath } from "node:path"
import { Exit, PreconditionError, UsageError } from "../core/errors"
import type { RunResult } from "../core/facet"
import * as audio from "../core/audio"
import * as mediaModule from "../core/media"
import { ffmpegArgv, isWindows } from "../runtime/media"
import type { Ctx, Outcome, Verb } from "./ctx"

const USAGE = "media extract <video> [output] | remux <video> <audio> [output] | join <first> <second> [output] | denoise <video> [output] | mic [--seconds N] | levels <file|folder>"

const NOISE_SECONDS = 5
const VOICE_START = 5
const VOICE_SECONDS = 12

function db(value: number | null): string {
  return value === null ? "n/a" : value.toFixed(1) + " dB"
}

function show(argv: readonly string[]): string {
  return ffmpegArgv(argv).join(" ")
}

async function exec(ctx: Ctx, argv: readonly string[]): Promise<RunResult> {
  return ctx.env.run({ argv: ffmpegArgv(argv) })
}

async function command(ctx: Ctx, file: mediaModule.MediaCommand): Promise<Outcome> {
  if (ctx.args.dryRun) {
    return { code: Exit.ok, data: { dryRun: true, output: file.output, argv: ffmpegArgv(file.argv) }, text: show(file.argv) }
  }
  const result = await exec(ctx, file.argv)
  if (result.code !== 0) {
    return { code: Exit.failed, data: { code: result.code }, text: result.err.trim() || `ffmpeg failed: ${file.argv.join(" ")}` }
  }
  return { code: Exit.ok, data: { output: file.output }, text: `wrote ${file.output}` }
}

async function join(ctx: Ctx, first: string, second: string, output?: string): Promise<Outcome> {
  const file = mediaModule.joinPair(first, second, output)
  if (ctx.args.dryRun) {
    return { code: Exit.ok, data: { dryRun: true, output: file.output, list: file.list, argv: ffmpegArgv(file.argv) }, text: show(file.argv) }
  }
  await writeFile(file.list, mediaModule.concatText([first, second]))
  try {
    return await command(ctx, file)
  } finally {
    await unlink(file.list).catch(() => {})
  }
}

function positive(ctx: Ctx, key: string, fallback: number): number {
  const raw = ctx.args.values[key]?.[0]
  if (raw === undefined) return fallback
  const value = Number(raw)
  if (!Number.isFinite(value) || value <= 0) throw new UsageError(`--${key} needs a positive number`)
  return value
}

async function mic(ctx: Ctx): Promise<Outcome> {
  if (!isWindows()) throw new PreconditionError("media mic uses DirectShow, so it is Windows-only")
  const seconds = positive(ctx, "seconds", 5)
  const listing = await exec(ctx, audio.listDevicesCommand())
  const devices = audio.parseDeviceList(listing.out + listing.err)
  if (devices.length === 0) throw new PreconditionError("no DirectShow audio capture devices found")
  const commands = devices.map((device) => audio.micCommand(device, seconds, true))
  if (ctx.args.dryRun) {
    return { code: Exit.ok, data: { dryRun: true, devices, seconds }, text: commands.map(show).join("\n") }
  }
  const lines = [`measuring ${devices.length} microphone(s) for ${seconds}s`]
  for (const [index, device] of devices.entries()) {
    const result = await exec(ctx, commands[index] ?? [])
    const level = audio.parseVolumedetect(result.out + result.err)
    const verdict = result.code === 0 ? audio.captureVerdict(level.mean, level.peak) : "FAILED to open"
    lines.push(`${device}  mean ${db(level.mean)}  peak ${db(level.peak)}  ${verdict}`)
  }
  return { code: Exit.ok, data: { devices, seconds }, text: lines.join("\n") }
}

async function filesUnder(target: string): Promise<string[]> {
  const info = await stat(target).catch(() => null)
  if (info === null) throw new PreconditionError(`not found: ${target}`)
  if (info.isDirectory()) return audio.audioFiles(await readdir(target)).map((name) => joinPath(target, name))
  return [target]
}

function levelCommands(file: string): string[][] {
  const windows = isWindows()
  return [
    audio.volumedetectCommand(file, windows, { seconds: NOISE_SECONDS }),
    audio.volumedetectCommand(file, windows, { start: VOICE_START, seconds: VOICE_SECONDS }),
    audio.volumedetectCommand(file, windows, { start: VOICE_START, seconds: VOICE_SECONDS, filter: "lowpass=f=300" }),
    audio.volumedetectCommand(file, windows, { start: VOICE_START, seconds: VOICE_SECONDS, filter: "highpass=f=300,lowpass=f=3000" }),
    audio.volumedetectCommand(file, windows, { start: VOICE_START, seconds: VOICE_SECONDS, filter: "highpass=f=3000" }),
    audio.loudnessCommand(file, windows),
  ]
}

async function levels(ctx: Ctx, target: string): Promise<Outcome> {
  const files = await filesUnder(target)
  if (files.length === 0) throw new PreconditionError(`no audio files in ${target}`)
  if (ctx.args.dryRun) {
    const lines = files.flatMap((file) => levelCommands(file).map(show))
    return { code: Exit.ok, data: { dryRun: true, files }, text: lines.join("\n") }
  }
  const lines: string[] = []
  for (const file of files) {
    const [noise, voice, body, mid, high, loudness] = levelCommands(file)
    const measure = async (argv: string[] | undefined): Promise<string> => {
      if (!argv) return ""
      const result = await exec(ctx, argv)
      return result.out + result.err
    }
    const noiseLevel = audio.parseVolumedetect(await measure(noise))
    const voiceLevel = audio.parseVolumedetect(await measure(voice))
    const bodyLevel = audio.parseVolumedetect(await measure(body))
    const midLevel = audio.parseVolumedetect(await measure(mid))
    const highLevel = audio.parseVolumedetect(await measure(high))
    const loud = audio.parseLoudness(await measure(loudness))
    const snrDb = noiseLevel.mean !== null && voiceLevel.mean !== null
      ? Math.round((voiceLevel.mean - noiseLevel.mean) * 10) / 10
      : null
    const row: audio.LevelRow = {
      file,
      snrDb,
      noiseDb: noiseLevel.mean,
      voiceDb: voiceLevel.mean,
      peakDb: voiceLevel.peak,
      lufs: loud.lufs,
      lra: loud.lra,
      bodyDb: bodyLevel.mean,
      midDb: midLevel.mean,
      highDb: highLevel.mean,
    }
    const bands = [row.bodyDb, row.midDb, row.highDb].map(db).join("/")
    lines.push(`${file}  snr=${db(row.snrDb)}  noise=${db(row.noiseDb)}  voice=${db(row.voiceDb)}  peak=${db(row.peakDb)}  lufs=${row.lufs ?? "n/a"}  lra=${row.lra ?? "n/a"}  bands=${bands}  ${audio.levelsVerdict(row)}`)
  }
  return { code: Exit.ok, data: { files }, text: lines.join("\n") }
}

const media: Verb = {
  name: "media",
  usage: USAGE,
  mutates: "host",
  run: async (ctx): Promise<Outcome> => {
    const [action, ...rest] = ctx.args.positional
    if (action === "extract" && rest[0]) return command(ctx, mediaModule.extractAudio(rest[0], rest[1]))
    if (action === "remux" && rest[0] && rest[1]) return command(ctx, mediaModule.remuxAudio(rest[0], rest[1], rest[2]))
    if (action === "denoise" && rest[0]) return command(ctx, mediaModule.denoiseAudio(rest[0], rest[1]))
    if (action === "join" && rest[0] && rest[1]) return join(ctx, rest[0], rest[1], rest[2])
    if (action === "mic") return mic(ctx)
    if (action === "levels" && rest[0]) return levels(ctx, rest[0])
    throw new UsageError(USAGE)
  },
}

export const mediaVerbs: Verb[] = [media]