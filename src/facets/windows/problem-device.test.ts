import { expect, test } from "bun:test"
import { problemDevice } from "./problem-device"

const healthy = JSON.stringify({ text: "Microsoft PnP Utility\n\nNo devices were found.\n" })

const twoProblems = JSON.stringify({
  text: [
    "Microsoft PnP Utility",
    "",
    "Instance ID:                USB\\VID_1",
    "Device Description:         Broken Thing",
    "Class Name:                 USB",
    "Problem Code:               0x0000000A",
    "Status:                     Error",
    "",
    "Instance ID:                PCI\\VEN_2",
    "Device Description:         Other Thing",
    "Class Name:                 Display",
    "Problem Code:               28",
    "Status:                     Error",
    "",
  ].join("\n"),
})

test("no problem devices parses to nothing", () => {
  expect(problemDevice.parse(healthy)).toEqual([])
})

test("each problem device becomes one item with its code and status", () => {
  const items = problemDevice.parse(twoProblems)
  expect(items.map((item) => item.id)).toEqual(["problem-device:PCI\\VEN_2", "problem-device:USB\\VID_1"])
  expect(items[0]?.a).toEqual({ class: "Display", description: "Other Thing", problemCode: 28 })
  expect(items[1]?.a).toEqual({ class: "USB", description: "Broken Thing", problemCode: 10 })
  expect(items[1]?.o).toEqual({ status: "Error" })
})