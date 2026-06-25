# Parser Diagnostics Design

## Goal

Make the first real ydmap browser smoke test debuggable. When availability does not appear, ZacksBar should show whether the content script found the Vue root, schedule table, rows, courts, slots, and available slots.

## Scope

- Add `parser.diagnostics` messages from the Chrome content script.
- Deduplicate unchanged parser diagnostics.
- Persist the latest parser diagnostics in native `latest-state.json`.
- Show parser diagnostics in the native diagnostics report and setup checklist.
- Update smoke-test docs.

Out of scope:

- Automated Chrome control.
- Capturing real ydmap HTML/Vue fixtures from the user's logged-in browser.
- Watch-rule alerts.

## Message

`parser.diagnostics` payload:

```json
{
  "pageUrl": "https://bawtt.ydmap.cn/booking/schedule/example",
  "vueRootFound": true,
  "componentCount": 12,
  "scheduleParentFound": true,
  "scheduleTableFound": true,
  "rowCount": 16,
  "columnCount": 4,
  "courtCount": 4,
  "slotCount": 64,
  "availableSlotCount": 3
}
```

The content script sends diagnostics before availability/captcha in each inspection. If diagnostics are unchanged, it does not resend them.

## Native State

`LatestAppState` stores `latestParserDiagnostics`. Diagnostics are local-only support data; they do not include cookies, query strings, or credentials.

## UI

Diagnostics report adds rows for parser health:

- Parser Vue Root
- Parser Table
- Parser Rows
- Parser Slots
- Parser Available Slots

Setup checklist adds a parser diagnostics step so the user can distinguish "Chrome/native connected" from "ydmap parser has not found the schedule yet".
