import { useCallback, useState } from "react"
import { api, useDebounced, useLoad } from "../api"
import { Card, Empty, Failure, Heading, Loading, Markdown, inputClass } from "./ui"

export function NotesView() {
  const [query, setQuery] = useState("")
  const settled = useDebounced(query)
  const list = useLoad(useCallback(() => api.notes(settled), [settled]))
  const [picked, setPicked] = useState<string | undefined>()
  const shown = list.data?.notes ?? []
  const path = (shown.find((entry) => entry.path === picked) ?? shown[0])?.path
  const detail = useLoad(useCallback(() => (path ? api.note(path) : Promise.resolve(undefined)), [path]))
  const note = detail.data?.note
  if (list.error) return <Failure message={list.error} />
  if (!list.data) return <Loading />

  return (
    <div>
      <Heading title="Notes">Reference guides for knowledge the code cannot derive.</Heading>
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-4 self-start space-y-3">
          <input className={`${inputClass} w-full`} placeholder="Search notes…" value={query} onChange={(e) => setQuery(e.target.value)} />
          <Card className="overflow-hidden max-h-[640px] overflow-y-auto">
            {shown.length === 0 ? <Empty title="No matches" /> : null}
            {shown.map((entry) => (
              <button
                key={entry.path}
                onClick={() => setPicked(entry.path)}
                className={`w-full text-left px-4 py-2.5 border-b border-[#1D222C] last:border-b-0 ${
                  entry.path === path ? "bg-[#1A1E26]" : "hover:bg-[#171B23]"
                }`}
              >
                <div className="text-sm text-[#F1F5F9] truncate">{entry.title}</div>
                <div className="text-xs font-mono text-[#94A3B8] truncate">{entry.path.replace(/^notes\//, "")}</div>
              </button>
            ))}
          </Card>
        </div>
        <Card className="lg:col-span-8 p-6 min-w-0">
          {note ? (
            <>
              <div className="text-xs font-mono text-[#94A3B8] mb-4 break-words">
                {note.path}
                {note.refs.length > 0 ? ` · refs: ${note.refs.join(", ")}` : ""}
              </div>
              <Markdown text={note.body} />
            </>
          ) : (
            <Empty title={detail.error ?? "Select a note"} />
          )}
        </Card>
      </div>
    </div>
  )
}
