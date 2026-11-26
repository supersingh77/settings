import { Menu, Terminal, ShieldCheck, Server, BookOpen, FlaskConical, Mail } from "lucide-react"
import { useCallback, useState } from "react"
import { api, useLoad } from "./api"
import { CheckView } from "./components/CheckView"
import { ConsoleView } from "./components/ConsoleView"
import { DevicesView } from "./components/DevicesView"
import { MailView } from "./components/MailView"
import { NotesView } from "./components/NotesView"
import { RecipesFixturesView } from "./components/RecipesFixturesView"
import { Failure, Loading, ghostButton, primaryButton } from "./components/ui"

type Section = "devices" | "console" | "checks" | "recipes" | "notes" | "mail"

const sections: { id: Section; label: string; icon: typeof Server }[] = [
  { id: "devices", label: "Devices", icon: Server },
  { id: "console", label: "CLI Console", icon: Terminal },
  { id: "checks", label: "Checks", icon: ShieldCheck },
  { id: "recipes", label: "Recipes/Fixtures", icon: FlaskConical },
  { id: "notes", label: "Notes", icon: BookOpen },
  { id: "mail", label: "Mailbox", icon: Mail },
]

export function App() {
  const describe = useLoad(useCallback(() => api.describe(), []))
  const [section, setSection] = useState<Section>("devices")
  const [deviceId, setDeviceId] = useState<string | undefined>()
  const [menu, setMenu] = useState(false)
  const [argv, setArgv] = useState<string[] | undefined>()
  const [checkRun, setCheckRun] = useState(0)

  const devices = describe.data?.devices ?? []
  const activeId = deviceId ?? devices[0]?.id
  const label = sections.find((entry) => entry.id === section)?.label ?? ""

  function go(next: Section) {
    setSection(next)
    setMenu(false)
  }

  function openConsole(next?: string[]) {
    setArgv(next)
    go("console")
  }

  function runCheck() {
    setCheckRun((value) => value + 1)
    go("checks")
  }

  function pickDevice(id: string) {
    setDeviceId(id)
    go("devices")
  }

  return (
    <div className="min-h-screen flex bg-[#0B0D10] text-[#F1F5F9]">
      {menu ? <div className="fixed inset-0 z-30 bg-black/60 lg:hidden" onClick={() => setMenu(false)} /> : null}
      <aside
        className={`fixed lg:static inset-y-0 left-0 z-40 w-64 bg-[#101319] border-r border-[#232834] flex flex-col transition-transform lg:translate-x-0 ${
          menu ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        <div className="h-14 px-5 flex items-center justify-between border-b border-[#232834]">
          <a href="/" className="text-base font-semibold tracking-tight text-[#F1F5F9] whitespace-nowrap shrink-0">
            settings
          </a>
        </div>
        <nav className="p-3 space-y-1">
          {sections.map(({ id, label: name, icon: Icon }) => (
            <button
              key={id}
              onClick={() => go(id)}
              className={`w-full flex items-center gap-2.5 px-3 py-2 text-sm rounded-md ${
                section === id ? "bg-[#1A1E26] text-[#F1F5F9]" : "text-[#CBD5E1] hover:bg-[#171B23]"
              }`}
            >
              <Icon className="w-4 h-4 text-[#94A3B8]" />
              {name}
            </button>
          ))}
        </nav>
        <div className="mt-4 px-5 pt-4 border-t border-[#232834] flex-1 overflow-y-auto">
          <div className="text-xs font-medium text-[#94A3B8] mb-2">Managed Devices</div>
          <div className="space-y-1 -mx-2">
            {devices.map((device) => (
              <button
                key={device.id}
                onClick={() => pickDevice(device.id)}
                className={`w-full flex items-center justify-between gap-2 px-2 py-1.5 text-sm rounded-md ${
                  section === "devices" && activeId === device.id
                    ? "bg-[#1A1E26] text-[#F1F5F9]"
                    : "text-[#CBD5E1] hover:bg-[#171B23]"
                }`}
              >
                <span className="truncate">{device.id}</span>
                <span className="text-xs font-mono text-[#94A3B8]">{device.platform}</span>
              </button>
            ))}
          </div>
        </div>
      </aside>

      <div className="flex-1 flex flex-col min-w-0">
        <header className="h-14 px-6 border-b border-[#232834] bg-[#0B0D10] flex items-center justify-between gap-8">
          <div className="flex items-center gap-3 min-w-0">
            <button className="lg:hidden text-[#94A3B8]" aria-label="Menu" onClick={() => setMenu(true)}>
              <Menu className="w-5 h-5" />
            </button>
            <div className="text-sm text-[#94A3B8] truncate font-mono">
              <span className="hidden sm:inline">settings</span>
              <span className="mx-2 hidden sm:inline">/</span>
              <span className="text-[#F1F5F9]">{label}</span>
              {section === "devices" && activeId ? (
                <>
                  <span className="mx-2">/</span>
                  <span className="text-[#F1F5F9]">{activeId}</span>
                </>
              ) : null}
            </div>
          </div>
          <div className="flex items-center gap-3 shrink-0">
            <button className={ghostButton} onClick={runCheck}>
              Run Check
            </button>
            <button className={primaryButton} onClick={() => openConsole()}>
              Open Console
            </button>
          </div>
        </header>

        <main className="flex-1 p-6 lg:p-8 max-w-[1200px] w-full mx-auto">
          {describe.error ? <Failure message={describe.error} /> : null}
          {!describe.data && !describe.error ? <Loading /> : null}
          {describe.data && section === "devices" && activeId ? (
            <DevicesView key={activeId} deviceId={activeId} onConsole={openConsole} />
          ) : null}
          {describe.data && section === "console" ? <ConsoleView describe={describe.data} initial={argv} /> : null}
          {describe.data && section === "checks" ? <CheckView key={checkRun} describe={describe.data} /> : null}
          {section === "recipes" ? <RecipesFixturesView /> : null}
          {section === "notes" ? <NotesView /> : null}
          {section === "mail" ? <MailView /> : null}
        </main>
      </div>
    </div>
  )
}
