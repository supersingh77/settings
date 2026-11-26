#!/usr/bin/env bun
import { join } from "node:path"
import { findRoot } from "../runtime/files"
import * as api from "./api"

const PORT = Number(process.env.DEV_WEB_PORT ?? 4173)
const HOST = process.env.DEV_WEB_HOST ?? "127.0.0.1"

function json(body: unknown, status = 200): Response {
  return Response.json(body, { status })
}

function sameOrigin(request: Request): boolean {
  const origin = request.headers.get("origin")
  return origin === null || new URL(origin).host === request.headers.get("host")
}

async function runRoute(root: string, request: Request): Promise<Response> {
  const type = request.headers.get("content-type") ?? ""
  if (!type.includes("application/json") || !sameOrigin(request)) return json({ error: "forbidden" }, 403)
  const body = (await request.json()) as { argv?: unknown }
  const argv = body.argv
  if (!Array.isArray(argv) || argv.length === 0 || !argv.every((word) => typeof word === "string")) {
    return json({ error: "argv must be a non-empty string array" }, 400)
  }
  const refusal = api.blocked(argv)
  if (refusal) return json({ code: 2, data: undefined, out: "", err: refusal })
  return json(await api.runArgv(root, argv))
}

async function route(root: string, dist: string, request: Request): Promise<Response> {
  const url = new URL(request.url)
  const path = url.pathname
  if (request.method === "POST" && path === "/api/run") return runRoute(root, request)
  if (request.method !== "GET") return json({ error: "method not allowed" }, 405)
  if (path === "/health") return json({ ok: true })
  if (path === "/api/describe") return json((await api.runArgv(root, ["describe", "--json"])).data)
  if (path === "/api/check") return json((await api.runArgv(root, ["check", "--json"])).data)
  if (path === "/api/device") {
    const detail = await api.deviceDetail(root, url.searchParams.get("id") ?? "")
    return detail ? json(detail) : json({ error: "unknown device" }, 404)
  }
  if (path === "/api/recipes") return json(await api.recipes(root))
  if (path === "/api/fixtures") return json(await api.fixtures(root))
  if (path === "/api/notes") return json(await api.notes(root))
  if (path === "/api/mail") return json(await api.mail(root))
  if (path.startsWith("/api/")) return json({ error: "not found" }, 404)
  const asset = Bun.file(join(dist, path === "/" ? "index.html" : path))
  if (!path.includes("..") && (await asset.exists())) return new Response(asset)
  return new Response(Bun.file(join(dist, "index.html")))
}

const root = await findRoot(process.cwd())
const dist = join(root, "dist", "web")

Bun.serve({
  hostname: HOST,
  port: PORT,
  fetch: async (request) => {
    try {
      return await route(root, dist, request)
    } catch (error) {
      return json({ error: error instanceof Error ? error.message : String(error) }, 500)
    }
  },
})

console.log(`dev web console on http://${HOST}:${PORT}`)
