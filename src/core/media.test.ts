import { expect, test } from "bun:test"
import { concatList, extractAudio, joinCommand, mergeAudio, selectClips } from "./media"

test("extract keeps the video name and copies the audio stream", () => {
  const command = extractAudio("/videos/clip one.mp4")
  expect(command.output).toBe("/videos/clip one_audio.m4a")
  expect(command.argv.slice(0, 2)).toEqual(["ffmpeg", "-i"])
  expect(command.argv.at(-2)).toBe("copy")
})

test("merge copies the video and encodes the new audio", () => {
  const command = mergeAudio("a/b.mkv", "a/b.m4a", "192k")
  expect(command.output).toBe("a/b_denoised.mp4")
  expect(command.argv).toContain("192k")
  expect(command.argv).toContain("0:v:0")
})

test("clips are filtered by extension and exclude the output", () => {
  expect(selectClips(["b.MP4", "a.mkv", "notes.txt", "joined.mp4"], "joined.mp4")).toEqual(["a.mkv", "b.MP4"])
})

test("concat lists quote paths and escape single quotes", () => {
  expect(concatList("/media", ["it's.mp4", "b.mp4"])).toBe("file '/media/it'\\''s.mp4'\nfile '/media/b.mp4'\n")
})

test("join commands read a concat list and copy streams", () => {
  expect(joinCommand("/m/.out.list", "/m/joined.mp4")).toEqual([
    "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", "/m/.out.list", "-c", "copy", "/m/joined.mp4",
  ])
})
