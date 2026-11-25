import { expect, test } from "bun:test"
import {
  audioFiles,
  captureVerdict,
  levelsVerdict,
  micCommand,
  parseDeviceList,
  parseLoudness,
  parseVolumedetect,
  volumedetectCommand,
  type LevelRow,
} from "./audio"
import { concatText, denoiseAudio, extractAudio, joinPair, remuxAudio } from "./media"

const DEVICES = [
  '[in#0 @ 000001] "Owl Lite Camera" (none)',
  '[in#0 @ 000001]   Alternative name "@device_pnp_\\?\\usb#vid_0c45&pid_6300" (none)',
  '[in#0 @ 000001] "Microphone (Owl Lite Audio)" (audio)',
  '[in#0 @ 000001]   Alternative name "@device_cm_{7A0FFDB4}" (audio)',
  '[in#0 @ 000001] "Analogue 1 + 2 (Focusrite USB Audio)" (audio)',
  'Error opening input file dummy.',
].join("\n")

const VOLUMEDETECT = [
  "[Parsed_volumedetect_0 @ 0] n_samples: 0",
  "[Parsed_volumedetect_0 @ 0] n_samples: 88200",
  "[Parsed_volumedetect_0 @ 0] mean_volume: -21.1 dB",
  "[Parsed_volumedetect_0 @ 0] max_volume: -18.1 dB",
].join("\n")

const LOUDNESS = [
  "  Integrated loudness:",
  "    I:         -21.8 LUFS",
  "  Loudness range:",
  "    LRA:         0.0 LU",
  "  True peak:",
  "    Peak:      -18.1 dBFS",
].join("\n")

function row(overrides: Partial<LevelRow>): LevelRow {
  return { file: "x", snrDb: null, noiseDb: null, voiceDb: null, peakDb: null, lufs: null, lra: null, bodyDb: null, midDb: null, highDb: null, ...overrides }
}

test("extract keeps the video name and copies the audio stream", () => {
  const command = extractAudio("/videos/clip one.mp4")
  expect(command.output).toBe("/videos/clip one_audio.m4a")
  expect(command.argv).toEqual(["ffmpeg", "-i", "/videos/clip one.mp4", "-vn", "-c:a", "copy", "/videos/clip one_audio.m4a"])
})

test("remux copies video and encodes the new audio", () => {
  const command = remuxAudio("a/b.mkv", "a/b.m4a")
  expect(command.output).toBe("a/b_remuxed.mp4")
  expect(command.argv).toContain("0:v:0")
  expect(command.argv).toContain("1:a:0")
  expect(command.argv).toContain("192k")
  expect(remuxAudio("v.mp4", "a.m4a", "out.mp4").output).toBe("out.mp4")
})

test("denoise copies video and runs the local noise filter", () => {
  const command = denoiseAudio("a/b.mkv")
  expect(command.output).toBe("a/b_denoised.mp4")
  expect(command.argv).toContain("afftdn")
  expect(command.argv).toContain("copy")
})

test("join takes two files and builds a concat list beside the output", () => {
  const command = joinPair("a/first.mp4", "a/second.mp4")
  expect(command.output).toBe("a/first_joined.mp4")
  expect(command.list).toBe("a/first_joined.mp4.list")
  expect(command.argv).toEqual(["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", command.list, "-c", "copy", command.output])
})

test("concat lists quote paths and escape single quotes", () => {
  expect(concatText(["a/it's.mp4", "b.mp4"])).toBe("file 'a/it'\\''s.mp4'\nfile 'b.mp4'\n")
})

test("device list keeps only audio devices", () => {
  expect(parseDeviceList(DEVICES)).toEqual(["Analogue 1 + 2 (Focusrite USB Audio)", "Microphone (Owl Lite Audio)"])
})

test("volumedetect parses the last level row", () => {
  expect(parseVolumedetect(VOLUMEDETECT)).toEqual({ mean: -21.1, peak: -18.1 })
  expect(parseVolumedetect("nothing here")).toEqual({ mean: null, peak: null })
  expect(parseVolumedetect("[x] mean_volume: -91.0 dB")).toEqual({ mean: -91, peak: null })
})

test("loudness parses integrated loudness, range and true peak", () => {
  expect(parseLoudness(LOUDNESS)).toEqual({ lufs: -21.8, lra: 0, peak: -18.1 })
})

test("levels commands target a segment or a band", () => {
  const argv = volumedetectCommand("clip.mkv", true, { start: 5, seconds: 12, filter: "lowpass=f=300" })
  expect(argv).toContain("-ss")
  expect(argv).toContain("5")
  expect(argv).toContain("lowpass=f=300,volumedetect")
  expect(argv.at(-1)).toBe("NUL")
  expect(micCommand("Mic", 5, true).join(" ")).toContain("audio=Mic")
})

test("capture verdicts match the old thresholds", () => {
  expect(captureVerdict(null, null)).toBe("FAILED to open")
  expect(captureVerdict(-91, -88)).toContain("SILENT")
  expect(captureVerdict(-60, -40)).toContain("very quiet")
  expect(captureVerdict(-40, -20)).toContain("quiet")
  expect(captureVerdict(-25, -2)).toContain("hot")
  expect(captureVerdict(-25, -10)).toBe("healthy")
})

test("levels verdicts keep the old noise, clipping, loudness and tone checks", () => {
  expect(levelsVerdict(row({ snrDb: 35 }))).toBe("clean")
  expect(levelsVerdict(row({ snrDb: 25 }))).toBe("usable")
  expect(levelsVerdict(row({ snrDb: 10 }))).toBe("NOISY")
  expect(levelsVerdict(row({ snrDb: 1 }))).toContain("no silent lead-in")
  expect(levelsVerdict(row({ peakDb: -2, lufs: -35 }))).toContain("near clipping")
  expect(levelsVerdict(row({ lufs: -35 }))).toContain("too quiet")
  expect(levelsVerdict(row({ highDb: -10, midDb: -20 }))).toContain("harsh/sibilant")
  expect(levelsVerdict(row({ bodyDb: -5, midDb: -20 }))).toContain("boomy")
  expect(levelsVerdict(row({}))).toBe("balanced")
})

test("audio files are filtered by extension", () => {
  expect(audioFiles(["b.MP4", "a.wav", "notes.txt", "c.mkv"])).toEqual(["a.wav", "b.MP4", "c.mkv"])
})