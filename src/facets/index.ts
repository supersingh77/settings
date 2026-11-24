import type { Facet } from "../core/facet"
import { registryApp } from "./windows/registry-app"
import { steam } from "./windows/steam"
import { winget } from "./windows/winget"

export const facets: Facet[] = [winget, steam, registryApp]
