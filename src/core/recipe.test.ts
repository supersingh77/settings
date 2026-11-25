import { expect, test } from "bun:test"
import { antigravityLatest, expand, githubLatest, matchAsset } from "./recipe"

const release = {
  tag_name: "v1.2.3",
  assets: [
    { name: "checksums.txt", browser_download_url: "https://example.test/sums" },
    { name: "app-linux-x86_64.AppImage", browser_download_url: "https://example.test/app" },
  ],
}

test("templates expand only known values", () => {
  expect(expand("{home}/.local/bin/app", { home: "/home/toy" })).toBe("/home/toy/.local/bin/app")
  expect(expand("{missing}/x", { home: "/home/toy" })).toBe("{missing}/x")
})

test("assets match by exact name or by prefix and suffix", () => {
  expect(matchAsset(release, { name: "checksums.txt" })).toBe("https://example.test/sums")
  expect(matchAsset(release, { prefix: "app-linux", suffix: ".AppImage" })).toBe("https://example.test/app")
  expect(matchAsset(release, { name: "absent" })).toBe("")
})

test("github releases strip v from the tag and require an asset", () => {
  expect(githubLatest(release, { prefix: "app-linux", suffix: ".AppImage" })).toEqual({
    version: "1.2.3",
    url: "https://example.test/app",
  })
  expect(() => githubLatest(release, { name: "absent" })).toThrow()
})

test("antigravity releases use version and execution id", () => {
  const result = antigravityLatest(
    [{ version: "2.0.0", execution_id: "42" }],
    "https://example.test/{version}-{execution}/app.tar.gz",
  )
  expect(result).toEqual({ version: "2.0.0-42", url: "https://example.test/2.0.0-42/app.tar.gz" })
  expect(() => antigravityLatest([], "x")).toThrow()
})
