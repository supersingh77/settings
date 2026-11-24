export const Exit = {
  ok: 0,
  found: 1,
  usage: 2,
  precondition: 3,
  failed: 4,
  internal: 5,
} as const

export class DevError extends Error {
  readonly code: number

  constructor(message: string, code: number) {
    super(message)
    this.code = code
  }
}

export class UsageError extends DevError {
  constructor(message: string) {
    super(message, Exit.usage)
  }
}

export class InputError extends DevError {
  constructor(message: string) {
    super(message, Exit.usage)
  }
}

export class PreconditionError extends DevError {
  constructor(message: string) {
    super(message, Exit.precondition)
  }
}

export class ProbeError extends PreconditionError {}
