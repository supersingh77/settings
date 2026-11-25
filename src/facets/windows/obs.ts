import type { Facet } from "../../core/facet"
import type { Item, Scalar } from "../../core/types"

type IniMap = Record<string, string | undefined>

type ObsDump = {
  video?: IniMap
  output?: IniMap
  advanced?: IniMap
  audio?: IniMap
}

type Field = { ini: string; id: string; number?: boolean }

const VIDEO: Field[] = [
  { ini: "BaseCX", id: "video.baseWidth", number: true },
  { ini: "BaseCY", id: "video.baseHeight", number: true },
  { ini: "OutputCX", id: "video.outputWidth", number: true },
  { ini: "OutputCY", id: "video.outputHeight", number: true },
  { ini: "ScaleType", id: "video.scaleType" },
  { ini: "ColorFormat", id: "video.colorFormat" },
  { ini: "ColorSpace", id: "video.colorSpace" },
  { ini: "ColorRange", id: "video.colorRange" },
]

const OUTPUT: Field[] = [{ ini: "Mode", id: "output.mode" }]

const ADVANCED: Field[] = [
  { ini: "RecType", id: "output.recordingType" },
  { ini: "RecFormat2", id: "output.recFormat" },
  { ini: "Encoder", id: "output.streamEncoder" },
  { ini: "RecEncoder", id: "output.recEncoder" },
  { ini: "RecFilePath", id: "output.recFilePath" },
  { ini: "RecTracks", id: "output.recTracks", number: true },
]

const AUDIO: Field[] = [
  { ini: "SampleRate", id: "audio.sampleRate", number: true },
  { ini: "ChannelSetup", id: "audio.channels" },
]

function toNumber(raw: string): number | null {
  const value = Number(raw)
  return Number.isFinite(value) ? value : null
}

function scalarOf(field: Field, raw: string | undefined): Scalar | undefined {
  if (raw === undefined || raw === "") return undefined
  if (field.number !== true) return raw
  const value = toNumber(raw)
  return value === null ? undefined : value
}

function item(id: string, value: Scalar): Item {
  return { id: `obs:${id}`, a: { value } }
}

function fieldsOf(map: IniMap | undefined, fields: Field[]): Item[] {
  if (map === undefined) return []
  const items: Item[] = []
  for (const field of fields) {
    const value = scalarOf(field, map[field.ini])
    if (value !== undefined) items.push(item(field.id, value))
  }
  return items
}

function numberOrNull(raw: string | undefined): number | null {
  return raw === undefined || raw === "" ? null : toNumber(raw)
}

function fpsItems(video: IniMap): Item[] {
  const type = video.FPSType
  if (type === "1") {
    const value = numberOrNull(video.FPSInt)
    return value === null ? [] : [item("video.fps", value)]
  }
  if (type === "2") {
    const num = video.FPSNum
    const den = video.FPSDen
    if (num === undefined || den === undefined || num === "" || den === "") return []
    return [item("video.fps", `${num}/${den}`)]
  }
  const value = numberOrNull(video.FPSCommon)
  return value === null ? [] : [item("video.fps", value)]
}

function trackItems(advanced: IniMap): Item[] {
  const items: Item[] = []
  for (const key of Object.keys(advanced).sort()) {
    const match = /^Track(\d+)(Bitrate|Name)$/.exec(key)
    if (match === null) continue
    const index = match[1] ?? ""
    const kind = match[2] ?? ""
    const raw = advanced[key]
    if (raw === undefined || raw === "") continue
    if (kind === "Bitrate") {
      const value = toNumber(raw)
      if (value !== null) items.push(item(`output.track${index}Bitrate`, value))
    } else {
      items.push(item(`output.track${index}Name`, raw))
    }
  }
  return items
}

function parseObs(stdout: string): Item[] {
  const trimmed = stdout.trim()
  if (trimmed === "") return []
  const dump = JSON.parse(trimmed) as ObsDump
  const video = dump.video ?? {}
  const advanced = dump.advanced ?? {}
  const items = [
    ...fieldsOf(dump.video, VIDEO),
    ...fpsItems(video),
    ...fieldsOf(dump.output, OUTPUT),
    ...fieldsOf(dump.advanced, ADVANCED),
    ...trackItems(advanced),
    ...fieldsOf(dump.audio, AUDIO),
  ]
  return items.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

export const obs: Facet = {
  name: "obs",
  platform: "windows",
  mode: "observed",
  command: () => ({ argv: ["pwsh", "-NoProfile", "-File", "src/facets/windows/obs.ps1"] }),
  parse: parseObs,
  plan: () => [],
}
