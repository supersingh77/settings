import type { Facet } from "../core/facet"
import { appx } from "./windows/appx"
import { association } from "./windows/association"
import { display } from "./windows/display"
import { hardware } from "./windows/hardware"
import { os } from "./windows/os"
import { pathApp } from "./windows/path-app"
import { problemDevice } from "./windows/problem-device"
import { registryApp } from "./windows/registry-app"
import { steam } from "./windows/steam"
import { volume } from "./windows/volume"
import { winget } from "./windows/winget"

export const facets: Facet[] = [winget, steam, registryApp, appx, pathApp, os, volume, hardware, display, problemDevice, association]
