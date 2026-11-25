import { boxVerbs } from "./boxes"
import { checkVerbs } from "./check"
import type { Verb } from "./ctx"
import { describeVerbs } from "./describe"
import { fixtureVerbs } from "./fixtures"
import { maintenanceVerbs } from "./maintenance"
import { mediaVerbs } from "./media"
import { shellVerbs } from "./shell"
import { syncVerbs } from "./sync"
import { uadVerbs } from "./uad"
import { wantVerbs } from "./want"

export const verbs: Verb[] = [
  ...describeVerbs,
  ...checkVerbs,
  ...syncVerbs,
  ...maintenanceVerbs,
  ...mediaVerbs,
  ...shellVerbs,
  ...uadVerbs,
  ...wantVerbs,
  ...fixtureVerbs,
  ...boxVerbs,
]
