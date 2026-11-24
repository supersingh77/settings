import { beforeEach, expect, test } from "bun:test"
import { PreconditionError, ProbeError } from "./errors"
import { capture, compare, restore, statePath } from "./pipeline"
import { pending } from "./plan"
import { fakeEnv, makeWorld, toyDevice, toyFacet, type World } from "../testing/world"

const facets = [toyFacet]
const opts = { strict: false }
const path = statePath("toybox", "toy")
let world: World

beforeEach(() => {
  world = makeWorld({ alpha: "1", beta: "2", "tmp-x": "9" })
})

test("capture twice produces byte-identical files", async () => {
  const env = fakeEnv(world)
  await capture(env, toyDevice, facets, false)
  const first = world.files.get(path)
  await capture(env, toyDevice, facets, false)
  expect(world.files.get(path)).toBe(first)
  expect(first).toContain("toy:alpha")
  expect(first).not.toContain("tmp-x")
})

test("capture then drift is clean, and capture then restore plans nothing", async () => {
  const env = fakeEnv(world)
  await capture(env, toyDevice, facets, false)
  expect(pending(await compare(env, toyDevice, facets, { strict: true }))).toBe(false)
  const result = await restore(env, toyDevice, facets, { ...opts, dryRun: true })
  expect(result.plan.steps).toEqual([])
})

test("capture --dry-run writes nothing", async () => {
  const deltas = await capture(fakeEnv(world), toyDevice, facets, true)
  expect(world.files.size).toBe(0)
  expect(deltas[0]?.changes.length).toBe(2)
})

test("restore converges, and a second restore has an empty plan", async () => {
  const env = fakeEnv(world)
  await capture(env, toyDevice, facets, false)
  world.items.delete("alpha")
  world.items.set("beta", "changed")
  world.items.set("gamma", "3")
  const first = await restore(env, toyDevice, facets, { ...opts, dryRun: false })
  expect(first.plan.steps.length).toBe(3)
  expect(pending(first.remaining)).toBe(false)
  expect(Object.fromEntries(world.items)).toEqual({ alpha: "1", beta: "2", "tmp-x": "9" })
  const second = await restore(env, toyDevice, facets, { ...opts, dryRun: false })
  expect(second.plan.steps).toEqual([])
})

test("dry-run restore reports steps and mutates nothing", async () => {
  const env = fakeEnv(world)
  await capture(env, toyDevice, facets, false)
  world.items.set("gamma", "3")
  const result = await restore(env, toyDevice, facets, { ...opts, dryRun: true })
  expect(result.plan.steps.map((step) => step.id)).toEqual(["del-gamma"])
  expect(world.mutations).toEqual([])
  expect(world.items.has("gamma")).toBe(true)
})

test("a failing step stops the run and later steps do not execute", async () => {
  const env = fakeEnv(world)
  await capture(env, toyDevice, facets, false)
  world.items.delete("alpha")
  world.items.delete("beta")
  world.failOn = "alpha"
  const result = await restore(env, toyDevice, facets, { ...opts, dryRun: false })
  expect(result.results.length).toBe(1)
  expect(result.results[0]?.code).toBe(1)
  expect(result.results[0]?.err).toBe("boom")
  expect(world.mutations.length).toBe(1)
})

test("drift without a captured store is a precondition failure", async () => {
  expect(compare(fakeEnv(world), toyDevice, facets, opts)).rejects.toBeInstanceOf(PreconditionError)
})

test("a failing probe is reported as a probe error naming the facet", async () => {
  const broken = { ...toyFacet, command: () => ({ argv: ["nothing"] }) }
  expect(compare(fakeEnv(world), toyDevice, [broken], opts)).rejects.toBeInstanceOf(ProbeError)
})
