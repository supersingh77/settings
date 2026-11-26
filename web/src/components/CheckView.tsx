import { CheckCircle2, XCircle } from "lucide-react"
import { useCallback } from "react"
import { api, useLoad, type Describe } from "../api"
import { Card, Failure, Heading, Loading, Th, ghostButton } from "./ui"

export function CheckView({ describe }: { describe: Describe }) {
  const { data, error, reload } = useLoad(useCallback(() => api.check(), []))
  if (error) return <Failure message={error} />
  if (!data) return <Loading />
  const clean = data.violations.length === 0

  return (
    <div>
      <Heading title="Checks">Schema, lint, fixture and note-reference checks over {data.files} files.</Heading>
      <Card className={`p-5 mb-6 flex items-center justify-between gap-4 ${clean ? "" : "border-[#DC2626]/50"}`}>
        <div className="flex items-center gap-3">
          {clean ? <CheckCircle2 className="w-6 h-6 text-[#86EFAC]" /> : <XCircle className="w-6 h-6 text-[#FCA5A5]" />}
          <div>
            <div className={`text-sm font-semibold ${clean ? "text-[#86EFAC]" : "text-[#FCA5A5]"}`}>
              {clean ? "Nominal" : `${data.violations.length} violation${data.violations.length === 1 ? "" : "s"}`}
            </div>
            <div className="text-xs text-[#94A3B8] font-mono mt-0.5">{data.files} files scanned</div>
          </div>
        </div>
        <button className={ghostButton} onClick={reload}>
          Re-run Check
        </button>
      </Card>

      {clean ? null : (
        <Card className="overflow-hidden mb-6">
          <table className="w-full text-left">
            <thead className="border-b border-[#232834]">
              <tr>
                <Th>Location</Th>
                <Th>Rule</Th>
                <Th>Message</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1D222C]">
              {data.violations.map((violation, index) => (
                <tr key={index} className="hover:bg-[#171B23]">
                  <td className="py-2.5 px-4 font-mono text-xs text-[#F1F5F9] whitespace-nowrap">
                    {violation.path}:{violation.line}
                  </td>
                  <td className="py-2.5 px-4 font-mono text-xs text-[#FBBF24]">{violation.rule}</td>
                  <td className="py-2.5 px-4 text-xs text-[#CBD5E1]">{violation.message}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}

      <Card className="overflow-hidden">
        <div className="px-4 py-3 border-b border-[#232834] text-sm font-semibold">Enforced Lint Rules</div>
        <table className="w-full text-left">
          <thead className="border-b border-[#232834]">
            <tr>
              <Th>Rule</Th>
              <Th>Enforces</Th>
              <Th className="text-right">Status</Th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#1D222C]">
            {Object.entries(describe.lint).map(([rule, description]) => {
              const failing = data.violations.some((violation) => (violation.group ?? violation.rule) === rule)
              return (
                <tr key={rule} className="hover:bg-[#171B23]">
                  <td className="py-2.5 px-4 font-mono text-xs text-[#F1F5F9] whitespace-nowrap">{rule}</td>
                  <td className="py-2.5 px-4 text-xs text-[#CBD5E1]">{description}</td>
                  <td className={`py-2.5 px-4 text-xs text-right ${failing ? "text-[#FCA5A5]" : "text-[#86EFAC]"}`}>
                    {failing ? "failing" : "passing"}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </Card>
    </div>
  )
}
