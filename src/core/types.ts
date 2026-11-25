import { z } from "zod"

export const Scalar = z.union([z.string(), z.number(), z.boolean()])
export type Scalar = z.infer<typeof Scalar>

export const ItemId = z.string().regex(/^[a-z][a-z0-9-]*:.+$/)

export const Item = z.strictObject({
  id: ItemId,
  a: z.record(z.string(), z.union([Scalar, z.array(Scalar)])),
  o: z.record(z.string(), Scalar).optional(),
})
export type Item = z.infer<typeof Item>

export const Platform = z.enum(["linux", "windows", "android"])
export type Platform = z.infer<typeof Platform>

export const Needs = z.enum(["admin", "toolbox"])
export type Needs = z.infer<typeof Needs>

const Name = z.string().regex(/^[a-z][a-z0-9-]*$/)

export const Device = z.strictObject({
  id: Name,
  platform: Platform,
  match: z.strictObject({
    hostname: z.string().optional(),
    board: z.string().optional(),
  }),
  via: Name.optional(),
  facets: z.array(Name),
  ignore: z.array(z.string()),
})
export type Device = z.infer<typeof Device>

export const Task = z.strictObject({
  id: Name,
  group: z.enum(["update", "cleanup"]),
  argv: z.array(z.string()).min(1),
  needs: Needs.optional(),
  destructive: z.boolean(),
})
export const Tasks = z.array(Task)
export type Task = z.infer<typeof Task>

export const Step = z.strictObject({
  id: z.string().min(1),
  item: ItemId,
  argv: z.array(z.string()).min(1).optional(),
  recipe: z.string().min(1).optional(),
  action: z.enum(["install", "remove"]).optional(),
  needs: Needs.optional(),
  destructive: z.boolean(),
})
export type Step = z.infer<typeof Step>

export const Plan = z.strictObject({
  device: Name,
  steps: z.array(Step),
})
export type Plan = z.infer<typeof Plan>

export const MessageHead = z.strictObject({
  id: z.string().min(1),
  from: z.string().min(1),
  to: z.string().min(1),
  kind: z.enum(["request", "result", "note"]),
  refs: z.array(z.string()),
})
export type MessageHead = z.infer<typeof MessageHead>
