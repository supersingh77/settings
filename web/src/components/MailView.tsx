import { useCallback, useState } from "react"
import { api, useLoad, type Mail } from "../api"
import { Card, Empty, Failure, Heading, Loading, Pre, Segmented, inputClass, primaryButton, ghostButton } from "./ui"

type Box = "inbox" | "outbox"

function Compose({ devices, onDone }: { devices: string[]; onDone: () => void }) {
  const [to, setTo] = useState(devices[0] ?? "")
  const [subject, setSubject] = useState("")
  const [kind, setKind] = useState("note")
  const [body, setBody] = useState("")
  const [error, setError] = useState("")

  async function send() {
    const res = await api.run(["outbox", "put", "--to", to, "--subject", subject, "--kind", kind, "--body", body, "--json"])
    if (res.code === 0) {
      setSubject("")
      setBody("")
      setError("")
      onDone()
    } else {
      setError(res.err || res.out)
    }
  }

  return (
    <Card className="p-4 mb-6 space-y-3">
      <div className="text-sm font-semibold">New Message</div>
      <div className="grid gap-3 sm:grid-cols-3">
        <input className={`${inputClass} font-mono`} list="mail-targets" placeholder="to" value={to} onChange={(e) => setTo(e.target.value)} />
        <datalist id="mail-targets">
          {devices.map((id) => (
            <option key={id} value={id} />
          ))}
        </datalist>
        <input
          className={`${inputClass} font-mono`}
          placeholder="subject-slug"
          value={subject}
          onChange={(e) => setSubject(e.target.value)}
        />
        <input className={`${inputClass} font-mono`} placeholder="kind" value={kind} onChange={(e) => setKind(e.target.value)} />
      </div>
      <textarea className={`${inputClass} w-full h-24 font-mono text-xs`} placeholder="Message body" value={body} onChange={(e) => setBody(e.target.value)} />
      {error ? <div className="text-xs font-mono text-[#FCA5A5] whitespace-pre-wrap">{error}</div> : null}
      <button className={primaryButton} disabled={to === "" || subject === "" || body === ""} onClick={send}>
        Send to Outbox
      </button>
    </Card>
  )
}

export function MailView() {
  const { data, error, reload } = useLoad(useCallback(() => api.mail(), []))
  const describe = useLoad(useCallback(() => api.describe(), []))
  const [box, setBox] = useState<Box>("inbox")
  const [composing, setComposing] = useState(false)
  const [open, setOpen] = useState<{ name: string; text: string } | undefined>()

  if (error) return <Failure message={error} />
  if (!data) return <Loading />
  const messages: Mail[] = data[box]

  async function show(name: string) {
    const res = await api.run([box, "show", name, "--json"])
    const text = (res.data as { text?: string } | undefined)?.text ?? res.err
    setOpen({ name, text })
  }

  async function ack(name: string) {
    if (!window.confirm(`Remove ${name} from ${box}?`)) return
    await api.run([box, "ack", name, "--json"])
    setOpen(undefined)
    reload()
  }

  return (
    <div>
      <div className="flex flex-wrap items-start justify-between gap-4">
        <Heading title="Mailbox">Drop folders for messages between agents. Contents stay local and gitignored.</Heading>
        <div className="flex items-center gap-3">
          <Segmented
            label="Mailbox"
            value={box}
            onChange={(id) => {
              setBox(id)
              setOpen(undefined)
            }}
            options={[
              { id: "inbox", label: `Inbox (${data.inbox.length})` },
              { id: "outbox", label: `Outbox (${data.outbox.length})` },
            ]}
          />
          <button className={ghostButton} onClick={() => setComposing(!composing)}>
            New Message
          </button>
        </div>
      </div>

      {composing ? (
        <Compose
          devices={describe.data?.devices.map((device) => device.id) ?? []}
          onDone={() => {
            setComposing(false)
            setBox("outbox")
            reload()
          }}
        />
      ) : null}

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <Card className={`${open ? "lg:col-span-5" : "lg:col-span-12"} overflow-hidden self-start`}>
          {messages.length === 0 ? (
            <Empty title={`${box === "inbox" ? "Inbox" : "Outbox"} is empty`}>
              {box === "inbox"
                ? "Agents drop messages into mail/inbox/. Nothing has arrived yet; you can write to another agent from New Message."
                : "Nothing is waiting to be sent. Compose a message to hand work to another agent."}
              <div className="mt-4">
                <button className={primaryButton} onClick={() => setComposing(true)}>
                  Compose a message
                </button>
              </div>
            </Empty>
          ) : (
            messages.map((message) => (
              <div
                key={message.name}
                className={`px-4 py-3 border-b border-[#1D222C] last:border-b-0 flex items-center justify-between gap-3 ${
                  open?.name === message.name ? "bg-[#1A1E26]" : "hover:bg-[#171B23]"
                }`}
              >
                <div className="min-w-0">
                  <div className="font-mono text-xs text-[#F1F5F9] truncate">{message.name}</div>
                  <div className="text-xs text-[#94A3B8] mt-0.5 truncate">
                    {message.from ? `${message.from} → ${message.to}` : message.kind}
                    {message.kind && message.from ? ` · ${message.kind}` : ""}
                  </div>
                </div>
                <div className="flex gap-2 shrink-0">
                  <button className={ghostButton} onClick={() => show(message.name)}>
                    Show
                  </button>
                  <button className={ghostButton} onClick={() => ack(message.name)}>
                    Ack
                  </button>
                </div>
              </div>
            ))
          )}
        </Card>
        {open ? (
          <Card className="lg:col-span-7 p-4 min-w-0">
            <div className="text-xs font-mono text-[#94A3B8] mb-3">{open.name}</div>
            <Pre className="max-h-[520px]">{open.text}</Pre>
          </Card>
        ) : null}
      </div>
    </div>
  )
}
