# Live ydmap Pipeline Design

## Goal

Build the first real v1 vertical slice: a supported ydmap booking page in Chrome emits live availability and captcha events, the native host stores the latest state locally, and the menu bar app can read that state.

## Scope

- Parse ydmap schedule state from the page's Vue component tree.
- Emit `availability.updated` only when the normalized snapshot changes.
- Keep existing captcha detection and include captcha events in local state.
- Store latest availability/captcha status in Application Support.
- Let the menu bar app load the latest stored state at launch and expose a refresh path.

Out of scope:

- Booking submission.
- Captcha bypass.
- Tampermonkey script mutation or installation.
- Full settings UI.
- Multi-venue product polish.

## Parser

The userscript reference shows ydmap exposes reliable schedule state through Vue components:

- table component: methods include `onSelect`, data includes `rows`.
- parent schedule component: methods include `sure` and `agreementSure`.
- court metadata comes from `table.platformInColumns`.
- availability is computed by `table.isAvailableStatic(cell)`.

The Chrome content script will keep the current self-contained IIFE shape, but add focused helpers:

- `findVueRoot(document)`
- `walkVueComponents(root)`
- `findScheduleTable(document)`
- `findScheduleParent(document)`
- `formatYdmapTime(value)`
- `extractYdmapAvailability(document, location)`

The extractor will produce the existing normalized payload shape:

```json
{
  "venue": "ydmap venue",
  "pageUrl": "https://bawtt.ydmap.cn/booking/schedule/example",
  "dateLabel": "6-26",
  "courts": [{ "id": "court-1", "name": "1号场" }],
  "slots": [
    { "courtId": "court-1", "start": "19:00", "end": "20:00", "available": true }
  ]
}
```

If the Vue state is not ready, the script sends no availability event and waits for the next polling cycle.

## Native State

`AppSupportStore` already appends all native events to `native-events.jsonl`. It will additionally maintain `latest-state.json` with this shape:

```json
{
  "updatedAt": "2026-06-25T15:00:00Z",
  "latestAvailability": { "message": "availability.updated payload" },
  "latestCaptcha": { "message": "captcha.detected payload" },
  "latestMessageType": "availability.updated"
}
```

The store writes this file when it receives `availability.updated`, `captcha.detected`, or `health.ping`. The menu bar app reads it at launch and on manual refresh.

## Menu Bar

The menu remains a compact status surface:

- `Connected` when only health is known.
- `Captcha required` when the latest stored message is captcha.
- `Monitoring <dateLabel>` when availability exists.
- `Alert: <venue> <available-count> available slots` for availability snapshots.

This keeps UI scope small while proving live data reaches the native app.

## Testing

- JavaScript tests use a fake Vue component tree and verify normalized court slots.
- JavaScript tests verify `inspectCurrentPage` sends `availability.updated` only once for an unchanged snapshot.
- Swift tests verify `AppSupportStore` writes and reads `latest-state.json`.
- Swift tests verify `AppModel` loads latest availability and captcha state.
