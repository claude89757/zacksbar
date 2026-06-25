# Watch Rule Settings Design

## Goal

Let users configure the availability alert rule from the macOS menu bar instead of relying on the current hard-coded 19:00-21:00 default.

## Scope

This iteration supports one primary watch rule. The user-facing rule contains start time, end time, and optional court keywords. It is saved locally and used immediately by notification matching. Multi-rule management, page-derived rule drafts, and advanced recurrence are future work.

## Approach

`ZacksBarCore` owns the watch-rule data model and local persistence. `AppSupportStore` reads and writes `watch-rules.json` under the same Application Support directory as `latest-state.json`. If the file does not exist, the store returns the existing default rule.

`ZacksBarApp` owns the editing experience. `AppModel` loads rules from the store during initialization and exposes a save method for the settings window. The menu bar gets an `Alert Settings...` item that opens a compact AppKit form.

## User Experience

The settings window is optimized for low input:

- Start and end are small text fields prefilled from the current rule.
- Court keywords is one text field that accepts comma-separated values. Empty means any court.
- Save persists the rule and updates the in-memory notification matcher immediately.

The window displays the current saved rule summary so users can verify what will trigger alerts.

## Data Format

`watch-rules.json` stores an array of `WatchRule` values using the existing Codable model:

```json
[
  {
    "id": "default-evening",
    "dateMode": "latestBookable",
    "start": "19:00",
    "end": "21:00",
    "courtKeywords": []
  }
]
```

`dateMode` is retained as a compatibility field in the stored model and is fixed to `latestBookable` by app saves. It is not shown in the settings UI.

## Validation

This iteration uses lightweight validation:

- Start and end must be non-empty.
- Empty court keywords means all courts.
- Keywords are trimmed, split on comma or Chinese comma, and empty tokens are dropped.

Time ordering and exact slot-boundary validation stay out of scope because available slot labels come from ydmap snapshots and vary by venue.

## Testing

Core tests cover reading defaults, writing rules, and reading persisted rules. App tests cover loading persisted rules, saving user edits, and using saved rules for notifications. Build verification covers the AppKit window.
