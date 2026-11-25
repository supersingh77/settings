import { Exit, PreconditionError, UsageError } from "../core/errors"
import { formatMessage, messageId, parseMessage } from "../core/message"
import { MessageHead } from "../core/types"
import { listBox, readBox, removeFromBox, writeToBox } from "../runtime/files"
import type { Ctx, Outcome, Verb } from "./ctx"

async function resolveName(ctx: Ctx, directory: string, wanted: string | undefined): Promise<string> {
  if (!wanted) throw new UsageError("usage: show|ack <name>")
  const names = await listBox(ctx.root, directory)
  const hits = names.filter((name) => name === wanted || name.replace(/\.[^.]+$/, "") === wanted)
  if (hits.length !== 1 || !hits[0]) throw new PreconditionError(`${wanted}: ${hits.length} matches in ${directory}/`)
  return hits[0]
}

async function list(ctx: Ctx, label: string, directory: string): Promise<Outcome> {
  const entries = []
  for (const name of await listBox(ctx.root, directory)) {
    if (!name.endsWith(".md")) {
      entries.push({ name, kind: "file" })
      continue
    }
    try {
      const message = parseMessage(await readBox(ctx.root, directory, name), name.replace(/\.md$/, ""))
      entries.push({ name, ...message.head })
    } catch {
      entries.push({ name, kind: "unreadable" })
    }
  }
  const text = entries.map((entry) => `${entry.name}  ${entry.kind}`).join("\n") || `${label} is empty`
  return { code: Exit.ok, data: { entries }, text }
}

async function put(ctx: Ctx, directory: string): Promise<Outcome> {
  const one = (key: string) => ctx.args.values[key]?.[0]
  const to = one("to")
  const subject = one("subject")
  if (!to || !subject) throw new UsageError("outbox put needs --to and --subject")
  if (!/^[a-z0-9-]+$/.test(subject)) throw new UsageError("--subject must be a lowercase slug")
  const id = messageId(ctx.io.now(), subject)
  const head = MessageHead.parse({
    id,
    from: one("from") ?? ctx.io.hostname(),
    to,
    kind: one("kind") ?? "note",
    refs: ctx.args.values.ref ?? [],
  })
  const body = one("body") ?? (await ctx.io.stdin())
  await writeToBox(ctx.root, directory, `${id}.md`, formatMessage({ head, body }))
  return { code: Exit.ok, data: { id, path: `${directory}/${id}.md` }, text: `wrote ${directory}/${id}.md` }
}

function boxVerb(name: "inbox" | "outbox", directory: string): Verb {
  const actions = name === "inbox" ? "list|show|ack" : "list|show|ack|put"
  return {
    name,
    usage: `${name} ${actions}${name === "outbox" ? " --to <id> --subject <slug> [--kind k] [--ref r] [--body text]" : " [name]"}`, 
    mutates: "no",
    run: async (ctx) => {
      const [action, wanted] = ctx.args.positional
      if (action === "list") return list(ctx, name, directory)
      if (action === "put" && name === "outbox") return put(ctx, directory)
      if (action === "show") {
        const resolved = await resolveName(ctx, directory, wanted)
        const text = await readBox(ctx.root, directory, resolved)
        return { code: Exit.ok, data: { name: resolved, text }, text }
      }
      if (action === "ack") {
        const resolved = await resolveName(ctx, directory, wanted)
        await removeFromBox(ctx.root, directory, resolved)
        return { code: Exit.ok, data: { acked: resolved }, text: `removed ${directory}/${resolved}` }
      }
      throw new UsageError(`usage: ${name} ${actions}`)
    },
  }
}

export const boxVerbs: Verb[] = [boxVerb("inbox", "mail/inbox"), boxVerb("outbox", "mail/outbox")]