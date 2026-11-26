import { Play } from "lucide-react"
import { useEffect, useRef, useState } from "react"
import { api, type Describe, type RunResult } from "../api"
import { Card, Heading, Pre, Segmented, Th, primaryButton } from "./ui"

const presets: { label: string; argv: string[] }[] = [
  { label: "describe --json", argv: ["describe", "--json"] },
  { label: "check", argv: ["check"] },
  { label: "inbox list", argv: ["inbox", "list"] },
  { label: "outbox list", argv: ["outbox", "list"] },
  { label: "update --dry-run", argv: ["update", "--dry-run"] },
  { label: "cleanup --dry-run", argv: ["cleanup", "--dry-run"] },
]

const exitLabels: Record<number, string> = {
  0: "Nominal",
  1: "Found",
  2: "Bad usage",
  3: "Precondition failed",
  4: "Step failed",
  5: "Internal error",
}

export function tokenize(line: string): string[] {
  return [...line.matchAll(/"([^"]*)"|'([^']*)'|(\S+)/g)].map((m) => m[1] ?? m[2] ?? m[3] ?? "")
}

function exitColor(code: number): string {
  if (code === 0) return "text-[#86EFAC]"
  if (code === 1) return "text-[#FBBF24]"
  return "text-[#FCA5A5]"
}

export function ConsoleView({ describe, initial }: { describe: Describe; initial?: string[] }) {
  const [line, setLine] = useState(initial ? initial.join(" ") : "describe --json")
  const [result, setResult] = useState<RunResult | undefined>()
  const [mode, setMode] = useState<"text" | "json">("text")
  const [busy, setBusy] = useState(false)
  const started = useRef(false)

  async function execute(argv: string[]) {
    if (argv.length === 0) return
    setBusy(true)
    setLine(argv.join(" "))
    setResult(await api.run(argv))
    setBusy(false)
  }

  useEffect(() => {
    if (initial && !started.current) {
      started.current = true
      void execute(initial)
    }
  }, [initial])

  const text = result ? [result.out, result.err].filter((part) => part !== "").join("\n") || "(no output)" : ""
  const json = result
    ? JSON.stringify(result.data ?? tryParse(result.out), null, 2) ?? "(no JSON output; add --json)"
    : ""

  return (
    <div>
      <Heading title="CLI Console">Runs the same <span className="font-mono">dev</span> verbs agents use. Host-changing verbs only run with --dry-run.</Heading>
      <Card className="p-4 mb-6">
        <form
          className="flex gap-3"
          onSubmit={(event) => {
            event.preventDefault()
            void execute(tokenize(line))
          }}
        >
          <div className="flex-1 flex items-center bg-[#0B0D10] border border-[#232834] rounded-md focus-within:border-[#2563EB]">
            <span className="pl-3 pr-2 font-mono text-sm text-[#94A3B8] select-none">dev</span>
            <input
              className="flex-1 bg-transparent py-1.5 pr-3 font-mono text-sm text-[#F1F5F9] outline-none focus-visible:outline-none"
              value={line}
              spellCheck={false}
              onChange={(event) => setLine(event.target.value)}
            />
          </div>
          <button type="submit" disabled={busy} className={`${primaryButton} flex items-center gap-1.5`}>
            <Play className="w-3.5 h-3.5" /> Run Command
          </button>
        </form>
        <div className="mt-3 flex flex-wrap gap-2">
          {presets.map((preset) => (
            <button
              key={preset.label}
              onClick={() => void execute(preset.argv)}
              className="px-2.5 py-1 text-xs font-mono text-[#CBD5E1] bg-[#0E1116] border border-[#232834] rounded hover:bg-[#1A1E26]"
            >
              {preset.label}
            </button>
          ))}
        </div>
      </Card>

      {result ? (
        <div className="mb-6">
          <div className="flex items-center justify-between mb-2">
            <div className={`text-sm font-medium font-mono ${exitColor(result.code)}`}>
              Exit {result.code} · {exitLabels[result.code] ?? "Unknown"}
            </div>
            <Segmented
              label="Output format"
              value={mode}
              onChange={setMode}
              options={[
                { id: "text", label: "Text" },
                { id: "json", label: "JSON" },
              ]}
            />
          </div>
          <Pre className="max-h-[420px]">{mode === "text" ? text : json}</Pre>
        </div>
      ) : null}

      <Card className="overflow-hidden">
        <div className="px-4 py-3 border-b border-[#232834] text-sm font-semibold text-[#F1F5F9]">Verb Reference</div>
        <table className="w-full text-left">
          <thead className="border-b border-[#232834]">
            <tr>
              <Th>Verb</Th>
              <Th>Usage</Th>
              <Th>Mutates</Th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#1D222C]">
            {describe.verbs.map((verb) => (
              <tr key={verb.name} className="hover:bg-[#171B23] cursor-pointer transition-colors" onClick={() => setLine(verb.name + " ")}>
                <td className="py-2.5 px-4 font-mono text-xs text-[#F1F5F9] whitespace-nowrap align-top">{verb.name}</td>
                <td className="py-2.5 px-4 font-mono text-xs text-[#94A3B8] break-words">{verb.usage}</td>
                <td className={`py-2.5 px-4 text-xs align-top ${verb.mutates === "host" ? "text-[#FBBF24]" : "text-[#CBD5E1]"}`}>{verb.mutates}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  )
}

function tryParse(text: string): unknown {
  try {
    return JSON.parse(text)
  } catch {
    return undefined
  }
}
