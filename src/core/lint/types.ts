export type SourceFile = { path: string; text: string }

export type Violation = { rule: string; path: string; line: number; message: string; group?: string }

export type Rule = (files: readonly SourceFile[]) => Violation[]

export function lineCount(text: string): number {
  if (text === "") return 0
  return text.split("\n").length - (text.endsWith("\n") ? 1 : 0)
}

export function isSource(file: SourceFile): boolean {
  return file.path.endsWith(".ts") || file.path.endsWith(".tsx")
}

export function isTest(file: SourceFile): boolean {
  return file.path.endsWith(".test.ts")
}
