# Diagnostics Window Design

## Goal

Make real browser/native integration easier to debug without opening Terminal first. ZacksBar should expose a small native diagnostics window from the menu bar that shows whether the local bridge is installed, whether runtime state exists, and what the last browser event was.

## Scope

- Add a testable Swift core diagnostic report.
- Add a native AppKit diagnostics window opened from the existing `Settings and diagnostics...` menu item.
- Keep the window read-only except for Refresh and Copy Report.
- Update local smoke-test docs.

Out of scope:

- Automatic Chrome extension ID discovery.
- Editing watch rules.
- Installing or repairing the native host from inside the app.
- Background file watching.
- Full settings center.

## Diagnostic Report

The report is generated from `AppSupportStore` and local filesystem checks:

- Application Support directory path.
- `native-events.jsonl` exists and byte size.
- `latest-state.json` exists and byte size.
- latest message type.
- latest update timestamp.
- menu status summary.
- native host manifest path.
- native host manifest exists.

The report exposes both structured rows for UI and plain text for copying into bug reports.

## UI

The menu item `Settings and diagnostics...` becomes active and opens a utility-sized native window titled `ZacksBar Diagnostics`.

The window contains:

- Status summary.
- Runtime paths.
- Native host manifest status.
- Latest message information.
- `Refresh` button.
- `Copy Report` button.

The visual style should be quiet and utilitarian, matching a macOS tool window. No marketing layout, no decorative graphics, and no oversized text.

## Testing

- Swift core tests verify report generation with and without latest state.
- Swift core tests verify plain text report output includes important paths and status.
- `swift build` verifies the AppKit window target compiles.
