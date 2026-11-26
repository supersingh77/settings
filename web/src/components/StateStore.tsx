import { Plus, Trash2 } from "lucide-react"
import { useMemo, useState } from "react"
import { api, formatRecord, type DeviceDetail, type Item } from "../api"
import { Card, Empty, Segmented, Th, inputClass, primaryButton } from "./ui"

type Filter = "all" | "asserted" | "observed"

function AddForm({ device, facet, onDone }: { device: string; facet: string; onDone: () => void }) {
  const [id, setId] = useState("")
  const [pairs, setPairs] = useState("")
  const [error, setError] = useState("")
  const [busy, setBusy] = useState(false)

  async function submit() {
    const sets = pairs
      .split("\n")
      .map((line) => line.trim())
      .filter((line) => line !== "")
      .flatMap((line) => ["--set", line])
    setBusy(true)
    const res = await api.run(["want", "add", id.trim(), "--facet", facet, "--device", device, ...sets, "--json"])
    setBusy(false)
    if (res.code === 0) {
      setId("")
      setPairs("")
      setError("")
      onDone()
    } else {
      setError(res.err || res.out)
    }
  }

  return (
    <div className="p-4 bg-[#0E1116] border-b border-[#232834] grid gap-3 sm:grid-cols-[1fr_1fr_auto] items-start">
      <input className={`${inputClass} font-mono`} placeholder={`${facet}:item-id`} value={id} onChange={(e) => setId(e.target.value)} />
      <textarea
        className={`${inputClass} font-mono text-xs h-[34px] min-h-[34px] resize-y`}
        placeholder="key=value (one per line)"
        value={pairs}
        onChange={(e) => setPairs(e.target.value)}
      />
      <button className={primaryButton} disabled={busy || id.trim() === ""} onClick={submit}>
        Add Item
      </button>
      {error ? <div className="sm:col-span-3 text-xs font-mono text-[#FCA5A5] whitespace-pre-wrap">{error}</div> : null}
    </div>
  )
}

export function StateStore({
  detail,
  facet,
  onRefresh,
}: {
  detail: DeviceDetail
  facet: string
  onRefresh: () => void
}) {
  const [query, setQuery] = useState("")
  const [filter, setFilter] = useState<Filter>("all")
  const [adding, setAdding] = useState(false)
  const items = detail.state[facet] ?? []

  const shown = useMemo(() => {
    const needle = query.trim().toLowerCase()
    return items.filter((item: Item) => {
      if (filter === "observed" && !item.o) return false
      const haystack = `${item.id} ${formatRecord(item.a)} ${formatRecord(item.o)}`.toLowerCase()
      return haystack.includes(needle)
    })
  }, [items, query, filter])

  async function remove(id: string) {
    if (!window.confirm(`Remove ${id} from ${facet}?`)) return
    const res = await api.run(["want", "rm", id, "--facet", facet, "--device", detail.device.id, "--json"])
    if (res.code === 0) onRefresh()
  }

  return (
    <Card className="overflow-hidden">
      <div className="p-3 flex flex-wrap items-center gap-3 border-b border-[#232834]">
        <input
          className={`${inputClass} flex-1 min-w-[180px]`}
          placeholder="Search items…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        <Segmented
          label="Filter"
          value={filter}
          onChange={setFilter}
          options={[
            { id: "all", label: "All" },
            { id: "asserted", label: "Asserted" },
            { id: "observed", label: "Observed" },
          ]}
        />
        <button className={`${primaryButton} flex items-center gap-1.5`} onClick={() => setAdding(!adding)}>
          <Plus className="w-3.5 h-3.5" /> Add
        </button>
      </div>
      {adding ? <AddForm device={detail.device.id} facet={facet} onDone={onRefresh} /> : null}
      {shown.length === 0 ? (
        <Empty title={items.length === 0 ? "No stored items" : "No matches"}>
          {items.length === 0
            ? `Nothing is recorded for ${facet} yet. Run capture on the device or add an item above.`
            : "Try a different search or filter."}
        </Empty>
      ) : (
        <div className="overflow-x-auto max-h-[560px] overflow-y-auto">
          <table className="w-full text-left">
            <thead className="sticky top-0 bg-[#12151B] border-b border-[#232834]">
              <tr>
                <Th>Item ID</Th>
                {filter !== "observed" ? <Th>Asserted (a)</Th> : null}
                {filter !== "asserted" ? <Th>Observed (o)</Th> : null}
                <Th className="text-right">Act</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1D222C]">
              {shown.map((item) => (
                <tr key={item.id} className="hover:bg-[#171B23] transition-colors">
                  <td className="py-2.5 px-4 font-mono text-xs text-[#F1F5F9] whitespace-nowrap">{item.id}</td>
                  {filter !== "observed" ? (
                    <td className="py-2.5 px-4 font-mono text-xs text-[#CBD5E1]">{formatRecord(item.a)}</td>
                  ) : null}
                  {filter !== "asserted" ? (
                    <td className="py-2.5 px-4 font-mono text-xs text-[#94A3B8]">{formatRecord(item.o)}</td>
                  ) : null}
                  <td className="py-2.5 px-4 text-right">
                    <button
                      aria-label={`Remove ${item.id}`}
                      onClick={() => remove(item.id)}
                      className="text-xs text-[#94A3B8] hover:text-[#FCA5A5]"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <div className="px-4 py-2 border-t border-[#232834] text-xs font-mono text-[#94A3B8]">
        {shown.length} of {items.length} items
      </div>
    </Card>
  )
}
