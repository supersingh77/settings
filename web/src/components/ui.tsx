import type { ReactNode } from "react"

export const inputClass =
  "bg-[#0B0D10] border border-[#232834] rounded-md px-3 py-1.5 text-sm text-[#F1F5F9] placeholder:text-[#94A3B8] focus:border-[#2563EB]"

export const primaryButton =
  "px-3.5 py-1.5 text-xs font-medium bg-[#2563EB] hover:bg-[#1D4ED8] text-white rounded-md whitespace-nowrap shrink-0 disabled:opacity-50"

export const ghostButton =
  "px-3.5 py-1.5 text-xs font-medium bg-[#12151B] hover:bg-[#1A1E26] border border-[#232834] text-[#F1F5F9] rounded-md whitespace-nowrap shrink-0 disabled:opacity-50"

export function Card({ children, className = "" }: { children: ReactNode; className?: string }) {
  return <div className={`bg-[#12151B] border border-[#232834] rounded-lg ${className}`}>{children}</div>
}

export function Segmented<T extends string>({
  value,
  options,
  onChange,
  label,
}: {
  value: T
  options: { id: T; label: string }[]
  onChange: (id: T) => void
  label: string
}) {
  return (
    <div role="tablist" aria-label={label} className="inline-flex p-0.5 bg-[#12151B] border border-[#232834] rounded-md">
      {options.map((option) => (
        <button
          key={option.id}
          role="tab"
          aria-selected={option.id === value}
          onClick={() => onChange(option.id)}
          className={`px-3 py-1 text-xs font-medium rounded whitespace-nowrap ${
            option.id === value ? "bg-[#1E2430] text-[#F1F5F9]" : "text-[#94A3B8] hover:text-[#F1F5F9]"
          }`}
        >
          {option.label}
        </button>
      ))}
    </div>
  )
}

export function Empty({ title, children }: { title: string; children?: ReactNode }) {
  return (
    <div className="py-12 px-6 text-center">
      <div className="text-sm font-medium text-[#F1F5F9]">{title}</div>
      {children ? <div className="mt-1.5 text-xs text-[#94A3B8] max-w-md mx-auto leading-relaxed">{children}</div> : null}
    </div>
  )
}

export function Failure({ message }: { message: string }) {
  return (
    <div className="p-4 text-sm text-[#FCA5A5] bg-[#12151B] border border-[#DC2626]/40 rounded-lg font-mono">{message}</div>
  )
}

export function Loading() {
  return <div className="p-6 text-sm text-[#94A3B8]">Loading…</div>
}

export function Heading({ title, children }: { title: string; children?: ReactNode }) {
  return (
    <div className="mb-6">
      <h1 className="text-2xl font-bold text-[#F1F5F9]">{title}</h1>
      {children ? <div className="mt-1 text-sm text-[#94A3B8]">{children}</div> : null}
    </div>
  )
}

export function Th({ children, className = "" }: { children?: ReactNode; className?: string }) {
  return <th className={`py-2.5 px-4 text-left text-xs font-medium text-[#94A3B8] ${className}`}>{children}</th>
}

export function Pre({ children, className = "" }: { children: ReactNode; className?: string }) {
  return (
    <pre
      className={`bg-[#0B0D10] border border-[#232834] rounded-md p-3 text-xs font-mono text-[#CBD5E1] overflow-auto whitespace-pre-wrap break-words ${className}`}
    >
      {children}
    </pre>
  )
}

function cells(row: string): string[] {
  return row
    .replace(/^\||\|$/g, "")
    .split("|")
    .map((cell) => cell.trim().replace(/\[([^\]]+)\]\([^)]+\)/g, "$1"))
}

function MarkdownTable({ rows }: { rows: string[] }) {
  const [head = "", , ...body] = rows
  return (
    <div className="overflow-x-auto border border-[#232834] rounded-md">
      <table className="w-full text-left">
        <thead className="border-b border-[#232834]">
          <tr>
            {cells(head).map((cell, at) => (
              <Th key={at}>{cell}</Th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-[#1D222C]">
          {body.map((row, at) => (
            <tr key={at}>
              {cells(row).map((cell, index) => (
                <td key={index} className={`py-2 px-4 text-xs ${index === 0 ? "font-mono text-[#F1F5F9] whitespace-nowrap" : "text-[#CBD5E1]"}`}>
                  {cell}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export function Markdown({ text }: { text: string }) {
  const blocks: ReactNode[] = []
  const lines = text.split("\n")
  let index = 0
  const inline = (value: string) =>
    value.split(/(`[^`]+`)/).map((part, at) =>
      part.startsWith("`") && part.endsWith("`") && part.length > 1 ? (
        <code key={at} className="font-mono text-xs bg-[#0B0D10] border border-[#232834] rounded px-1 py-0.5 text-[#F1F5F9]">
          {part.slice(1, -1)}
        </code>
      ) : (
        part
      ),
    )
  while (index < lines.length) {
    const line = lines[index] ?? ""
    if (line.startsWith("```")) {
      const code: string[] = []
      index += 1
      while (index < lines.length && !(lines[index] ?? "").startsWith("```")) code.push(lines[index++] ?? "")
      index += 1
      blocks.push(<Pre key={blocks.length}>{code.join("\n")}</Pre>)
    } else if (/^#{1,4} /.test(line)) {
      const level = line.indexOf(" ")
      blocks.push(
        <h3
          key={blocks.length}
          className={`font-semibold text-[#F1F5F9] mt-5 ${level <= 1 ? "text-lg" : "text-sm"}`}
        >
          {line.slice(level + 1)}
        </h3>,
      )
      index += 1
    } else if (/^\s*[-*] /.test(line)) {
      const items: string[] = []
      while (index < lines.length && /^\s*[-*] /.test(lines[index] ?? "")) items.push((lines[index++] ?? "").replace(/^\s*[-*] /, ""))
      blocks.push(
        <ul key={blocks.length} className="list-disc pl-5 space-y-1 text-sm text-[#CBD5E1]">
          {items.map((item, at) => (
            <li key={at}>{inline(item)}</li>
          ))}
        </ul>,
      )
    } else if (line.startsWith("|")) {
      const rows: string[] = []
      while (index < lines.length && (lines[index] ?? "").startsWith("|")) rows.push(lines[index++] ?? "")
      blocks.push(<MarkdownTable key={blocks.length} rows={rows} />)
    } else if (line.trim() === "") {
      index += 1
    } else {
      const paragraph: string[] = []
      while (index < lines.length && (lines[index] ?? "").trim() !== "" && !/^(#{1,4} |```|\s*[-*] |\|)/.test(lines[index] ?? "")) {
        paragraph.push(lines[index++] ?? "")
      }
      blocks.push(
        <p key={blocks.length} className="text-sm text-[#CBD5E1] leading-relaxed">
          {inline(paragraph.join(" "))}
        </p>,
      )
    }
  }
  return <div className="space-y-3">{blocks}</div>
}
