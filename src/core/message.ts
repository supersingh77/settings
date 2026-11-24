import { InputError } from "./errors"
import { parseFrontMatter, splitRefs } from "./frontmatter"
import { MessageHead } from "./types"

export type Message = { head: MessageHead; body: string }

export function parseMessage(text: string, id: string): Message {
  const front = parseFrontMatter(text)
  if (!front) throw new InputError(`${id}: missing front matter`)
  const parsed = MessageHead.safeParse({
    id,
    from: front.head.from,
    to: front.head.to,
    kind: front.head.kind,
    refs: splitRefs(front.head.refs),
  })
  if (!parsed.success) {
    throw new InputError(`${id}: ${parsed.error.issues[0]?.message ?? "invalid message"}`)
  }
  return { head: parsed.data, body: front.body.replace(/^\n/, "") }
}

export function formatMessage(message: Message): string {
  const { from, to, kind, refs } = message.head
  const head = [`from: ${from}`, `to: ${to}`, `kind: ${kind}`, `refs: ${refs.join(", ")}`]
  return `---\n${head.join("\n")}\n---\n\n${message.body.trimEnd()}\n`
}

export function messageId(now: Date, slug: string): string {
  const stamp = now.toISOString().replace(/[-:]/g, "").replace(/\.\d+Z$/, "Z")
  return `${stamp}-${slug}`
}
