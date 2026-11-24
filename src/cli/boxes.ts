import { Exit, PreconditionError, UsageError } from "../core/errors"
import { formatMessage, messageId, parseMessage } from "../core/message"
import { MessageHead } from "../core/types"
import { listBox, readBox, removeFromBox, writeToBox } from "../runtime/files"
import type { Ctx, Outcome, Verb } from "./ctx"

async function resolveName(ctx: Ctx, box: string, wanted: string | undefined): Promise<string> {
  if (!wanted) throw new UsageError(`usage: ${box} show|ack <name>`)
  const names = await listBox(ctx.root, box)
  const hits = names.filter((name) => name === wanted || name.replace(/\.[^.]+$/, "") === wanted)
  if (hits.length !== 1 || !hits[0]) throw new PreconditionError(`${wanted}: ${hits.length} matches in ${box}/`)
  return hits[0]
}

async function list(ctx: Ctx, box: string): Promise<Outcome> {
  const entries = []
  for (const name of await listBox(ctx.root, box)) {
    if (!name.endsWith(".md")) {
      entries.push({ name, kind: "file" })
      continue
    }
    try {
      const message = parseMessage(await readBox(ctx.root, box, name), name.replace(/\.md$/, ""))
      entries.push({ name, ...message.head })
    } catch {
      entries.push({ name, kind: "unreadable" })
    }
  }
  const text = entries.map((entry) => `${entry.name}  ${entry.kind}`).join("\n") || `${box} is empty`
  return { code: Exit.ok, data: { entries }, text }
}

async function put(ctx: Ctx, box: string): Promise<Outcome> {
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
  await writeToBox(ctx.root, box, `${id}.md`, formatMessage({ head, body }))
  return { code: Exit.ok, data: { id, path: `${box}/${id}.md` }, text: `wrote ${box}/${id}.md` }
}

function boxVerb(box: "inbox" | "outbox"): Verb {
  const actions = box === "inbox" ? "list|show|ack" : "list|show|ack|put"
  return {
    name: box,
    usage: `${box} ${actions}${box === "outbox" ? " --to <id> --subject <slug> [--kind k] [--ref r] [--body text]" : " [name]"}`,
    mutates: "no",
    run: async (ctx) => {
      const [action, wanted] = ctx.args.positional
      if (action === "list") return list(ctx, box)
      if (action === "put" && box === "outbox") return put(ctx, box)
      if (action === "show") {
        const name = await resolveName(ctx, box, wanted)
        const text = await readBox(ctx.root, box, name)
        return { code: Exit.ok, data: { name, text }, text }
      }
      if (action === "ack") {
        const name = await resolveName(ctx, box, wanted)
        await removeFromBox(ctx.root, box, name)
        return { code: Exit.ok, data: { acked: name }, text: `removed ${box}/${name}` }
      }
      throw new UsageError(`usage: ${box} ${actions}`)
    },
  }
}

export const boxVerbs: Verb[] = [boxVerb("inbox"), boxVerb("outbox")]
