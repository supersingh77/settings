import type { Facet } from "../core/facet"
import { appx } from "./windows/appx"
import { os } from "./windows/os"
import { pathApp } from "./windows/path-app"
import { registryApp } from "./windows/registry-app"
import { steam } from "./windows/steam"
import { volume } from "./windows/volume"
import { winget } from "./windows/winget"

export const facets: Facet[] = [winget, steam, registryApp, appx, pathApp, os, volume]
