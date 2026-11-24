import { boxVerbs } from "./boxes"
import { checkVerbs } from "./check"
import type { Verb } from "./ctx"
import { describeVerbs } from "./describe"
import { fixtureVerbs } from "./fixtures"
import { syncVerbs } from "./sync"
import { wantVerbs } from "./want"

export const verbs: Verb[] = [
  ...describeVerbs,
  ...checkVerbs,
  ...syncVerbs,
  ...wantVerbs,
  ...fixtureVerbs,
  ...boxVerbs,
]
