import { useCallback, useState } from "react"
import { api, useLoad, type DeviceDetail } from "../api"
import { verbs } from "../verbs"
import { RawState, StateStore } from "./StateStore"
import { Card, Empty, Failure, Heading, Loading, Segmented, Th, ghostButton } from "./ui"

type Tab = "state" | "tasks" | "jsonl"

function Tasks({ detail, onConsole }: { detail: DeviceDetail; onConsole: (argv: string[]) => void }) {
  const id = detail.device.id
  return (
    <Card className="overflow-hidden">
      <div className="p-3 flex items-center justify-between gap-3 border-b border-[#232834]">
        <div className="text-xs font-mono text-[#94A3B8]">data/devices/{id}/tasks.json</div>
        <div className="flex gap-2">
          <button className={ghostButton} onClick={() => onConsole(verbs.preview("update", id))}>
            Preview Update
          </button>
          <button className={ghostButton} onClick={() => onConsole(verbs.preview("cleanup", id))}>
            Preview Cleanup
          </button>
        </div>
      </div>
      {detail.tasks.length === 0 ? (
        <Empty title="No tasks">This device has no tasks.json entries.</Empty>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="border-b border-[#232834]">
              <tr>
                <Th>Task</Th>
                <Th>Group</Th>
                <Th>Command</Th>
                <Th>Flags</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1D222C]">
              {detail.tasks.map((task) => (
                <tr key={task.id} className="hover:bg-[#171B23] transition-colors align-top">
                  <td className="py-2.5 px-4 font-mono text-xs text-[#F1F5F9] whitespace-nowrap">{task.id}</td>
                  <td className="py-2.5 px-4 text-xs text-[#CBD5E1]">{task.group}</td>
                  <td className="py-2.5 px-4 font-mono text-xs text-[#94A3B8] break-all">{task.argv.join(" ")}</td>
                  <td className="py-2.5 px-4 text-xs whitespace-nowrap">
                    {task.destructive ? <span className="text-[#FCA5A5]">destructive</span> : <span className="text-[#86EFAC]">safe</span>}
                    {task.needs ? <span className="ml-2 text-[#FBBF24]">needs {task.needs}</span> : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Card>
  )
}

export function DevicesView({ deviceId, onConsole }: { deviceId: string; onConsole: (argv: string[]) => void }) {
  const [rev, setRev] = useState(0)
  const { data, error } = useLoad(useCallback(() => api.device(deviceId), [deviceId, rev]))
  const [tab, setTab] = useState<Tab>("state")
  const [picked, setPicked] = useState<string | undefined>()

  if (error) return <Failure message={error} />
  if (!data) return <Loading />

  const { device, counts, tasks } = data
  const facet = picked && device.facets.includes(picked) ? picked : device.facets[0]
  const stored = Object.values(counts).reduce((sum, count) => sum + count, 0)
  const meta = [
    device.platform,
    device.match.hostname,
    device.match.board,
    device.match.serial,
    device.via ? `via ${device.via}` : undefined,
    `${device.facets.length} facets`,
    `${stored} stored items`,
  ].filter((part): part is string => part !== undefined && part !== "")

  return (
    <div>
      <div className="flex flex-wrap items-start justify-between gap-4 mb-6">
        <Heading title={device.id}>
          <span className="font-mono text-xs">{meta.join(" · ")}</span>
        </Heading>
        <Segmented
          label="Device view"
          value={tab}
          onChange={setTab}
          options={[
            { id: "state", label: "State Store" },
            { id: "tasks", label: `Tasks (${tasks.length})` },
            { id: "jsonl", label: "JSONL Raw" },
          ]}
        />
      </div>

      {tab === "tasks" ? <Tasks detail={data} onConsole={onConsole} /> : null}

      {tab !== "tasks" ? (
        <>
          <div role="tablist" aria-label="Facets" className="flex flex-wrap gap-2 mb-4">
            {device.facets.map((name) => (
              <button
                key={name}
                role="tab"
                aria-selected={name === facet}
                onClick={() => setPicked(name)}
                className={`px-3 py-1.5 text-xs font-medium rounded-md border ${
                  name === facet
                    ? "bg-[#2563EB] border-[#2563EB] text-white"
                    : "bg-[#12151B] border-[#232834] text-[#CBD5E1] hover:bg-[#1A1E26]"
                }`}
              >
                {name} <span className="font-mono opacity-80">({counts[name] ?? 0})</span>
              </button>
            ))}
          </div>
          {facet && tab === "state" ? (
            <StateStore key={facet} deviceId={device.id} facet={facet} rev={rev} onChanged={() => setRev(rev + 1)} />
          ) : null}
          {facet && tab === "jsonl" ? <RawState deviceId={device.id} facet={facet} rev={rev} /> : null}
        </>
      ) : null}
    </div>
  )
}
