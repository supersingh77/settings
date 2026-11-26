export type Box = "inbox" | "outbox"
export type OnlyFilter = "all" | "asserted" | "observed"

const optional = (flag: string, value: string | undefined): string[] => (value ? [flag, value] : [])

export const verbs = {
  describe: () => ["describe", "--json"],
  check: () => ["check", "--json"],
  device: (id: string) => ["devices", "show", id, "--json"],
  state: (device: string, facet: string, query: string, only: OnlyFilter) => [
    "state",
    "list",
    device,
    "--facet",
    facet,
    ...optional("--query", query.trim()),
    ...(only === "all" ? [] : ["--only", only]),
    "--json",
  ],
  want: {
    add: (device: string, facet: string, id: string, sets: string[]) => [
      "want",
      "add",
      id,
      "--facet",
      facet,
      "--device",
      device,
      ...sets.flatMap((set) => ["--set", set]),
      "--json",
    ],
    rm: (device: string, facet: string, id: string) => ["want", "rm", id, "--facet", facet, "--device", device, "--json"],
  },
  preview: (group: "update" | "cleanup", device: string) => [group, device, "--dry-run", "--json"],
  recipes: () => ["recipes", "list", "--json"],
  recipe: (id: string) => ["recipes", "show", id, "--json"],
  fixtures: (platform: string) => ["fixtures", "list", ...(platform === "all" ? [] : ["--platform", platform]), "--json"],
  fixture: (key: string) => ["fixtures", "show", key, "--json"],
  notes: (query: string) => ["notes", "list", ...optional("--query", query.trim()), "--json"],
  note: (path: string) => ["notes", "show", path, "--json"],
  mail: {
    list: (box: Box) => [box, "list", "--json"],
    show: (box: Box, name: string) => [box, "show", name, "--json"],
    ack: (box: Box, name: string) => [box, "ack", name, "--json"],
    put: (to: string, subject: string, kind: string, body: string) => [
      "outbox",
      "put",
      "--to",
      to,
      "--subject",
      subject,
      "--kind",
      kind,
      "--body",
      body,
      "--json",
    ],
  },
}
