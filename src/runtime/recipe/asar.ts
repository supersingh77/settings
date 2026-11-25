import { open } from "node:fs/promises"

type AsarNode = { files?: Record<string, AsarNode>; offset?: string; size?: number }

export async function asarEntry(path: string, name: string): Promise<Uint8Array | null> {
  try {
    const handle = await open(path, "r")
    try {
      const head = Buffer.alloc(16)
      await handle.read(head, 0, head.length, 0)
      const headerSize = head.readUInt32LE(4)
      const jsonLength = head.readUInt32LE(12)
      const json = Buffer.alloc(jsonLength)
      await handle.read(json, 0, json.length, 16)
      let node: AsarNode = { files: JSON.parse(json.toString("utf8")).files }
      for (const part of name.split("/")) {
        const next = node.files?.[part]
        if (!next) return null
        node = next
      }
      if (node.size === undefined || node.offset === undefined) return null
      const data = Buffer.alloc(node.size)
      await handle.read(data, 0, data.length, 8 + headerSize + Number(node.offset))
      return data
    } finally {
      await handle.close()
    }
  } catch {
    return null
  }
}
