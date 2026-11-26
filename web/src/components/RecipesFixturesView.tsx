import { useCallback, useState } from "react"
import { api, useLoad, type Fixture } from "../api"
import { Card, Empty, Failure, Heading, Loading, Pre, Segmented } from "./ui"

type Kind = "recipes" | "fixtures"
type Platform = "all" | "windows" | "linux" | "android"

function listButton(active: boolean): string {
  return `w-full text-left px-4 py-2.5 text-sm border-b border-[#1D222C] last:border-b-0 ${
    active ? "bg-[#1A1E26] text-[#F1F5F9]" : "text-[#CBD5E1] hover:bg-[#171B23]"
  }`
}

function Recipes() {
  const { data, error } = useLoad(useCallback(() => api.recipes(), []))
  const [picked, setPicked] = useState<string | undefined>()
  if (error) return <Failure message={error} />
  if (!data) return <Loading />
  const recipe = data.recipes.find((entry) => entry.id === picked) ?? data.recipes[0]
  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
      <Card className="lg:col-span-4 overflow-hidden self-start">
        {data.recipes.map((entry) => (
          <button key={entry.id} className={listButton(entry.id === recipe?.id)} onClick={() => setPicked(entry.id)}>
            <span className="font-mono text-xs">{entry.id}</span>
          </button>
        ))}
      </Card>
      <Card className="lg:col-span-8 p-4">
        {recipe ? (
          <>
            <div className="text-xs font-mono text-[#94A3B8] mb-3">data/recipes/{recipe.id}.json</div>
            <Pre className="max-h-[640px]">{JSON.stringify(recipe, null, 2)}</Pre>
          </>
        ) : (
          <Empty title="No recipes" />
        )}
      </Card>
    </div>
  )
}

function Fixtures() {
  const { data, error } = useLoad(useCallback(() => api.fixtures(), []))
  const [platform, setPlatform] = useState<Platform>("all")
  const [picked, setPicked] = useState<string | undefined>()
  if (error) return <Failure message={error} />
  if (!data) return <Loading />
  const shown = data.fixtures.filter((entry) => platform === "all" || entry.platform === platform)
  const fixture: Fixture | undefined = shown.find((entry) => entry.path === picked) ?? shown[0]
  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
      <div className="lg:col-span-4 self-start space-y-3">
        <Segmented
          label="Platform"
          value={platform}
          onChange={setPlatform}
          options={[
            { id: "all", label: "All" },
            { id: "windows", label: "Windows" },
            { id: "linux", label: "Linux" },
            { id: "android", label: "Android" },
          ]}
        />
        <Card className="overflow-hidden">
          {shown.map((entry) => (
            <button key={entry.path} className={listButton(entry.path === fixture?.path)} onClick={() => setPicked(entry.path)}>
              <span className="font-mono text-xs">{entry.facet}</span>
              <span className="ml-2 text-xs text-[#94A3B8]">
                {entry.platform} · {entry.name}
              </span>
            </button>
          ))}
        </Card>
      </div>
      <div className="lg:col-span-8 space-y-4">
        {fixture ? (
          <>
            <Card className="p-4">
              <div className="text-xs font-mono text-[#94A3B8] mb-3">{fixture.path}</div>
              <Pre className="max-h-[300px]">{fixture.raw || "empty"}</Pre>
            </Card>
            <Card className="p-4">
              <div className="text-xs font-mono text-[#94A3B8] mb-3">{fixture.path.replace(/\.txt$/, ".golden.jsonl")}</div>
              <Pre className="max-h-[300px]">{fixture.golden || "missing golden file; run fixtures update"}</Pre>
            </Card>
          </>
        ) : (
          <Card>
            <Empty title="No fixtures for this platform" />
          </Card>
        )}
      </div>
    </div>
  )
}

export function RecipesFixturesView() {
  const [kind, setKind] = useState<Kind>("recipes")
  return (
    <div>
      <div className="flex flex-wrap items-start justify-between gap-4">
        <Heading title="Recipes & Fixtures">Install recipes and recorded command output with parsed golden files.</Heading>
        <Segmented
          label="Kind"
          value={kind}
          onChange={setKind}
          options={[
            { id: "recipes", label: "Recipes" },
            { id: "fixtures", label: "Fixtures" },
          ]}
        />
      </div>
      {kind === "recipes" ? <Recipes /> : <Fixtures />}
    </div>
  )
}
