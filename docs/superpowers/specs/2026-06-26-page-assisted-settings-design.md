# Page Assisted Alert Settings Design

## Goal

Reduce manual input in `Alert Settings...` while keeping the alert rule easy to understand. Users should be able to fill the time range from the latest parsed ydmap page state and then explicitly save it.

## Scope

This iteration adds a `Use Current Page` action to the existing primary alert settings window. It reads the latest persisted `availability.updated` snapshot, finds the earliest continuous available range, and fills Start and End. It does not add date settings, multi-rule management, booking automation, or automatic saving.

Court keywords remain user-controlled. The suggestion exposes the source court internally for status and future UX, but the settings window does not auto-fill keywords because that could narrow the alert unexpectedly.

## Behavior

- If the latest state has at least one available slot, suggest the earliest continuous range on one court.
- If adjacent available slots exist on the same court, merge them into one Start-End range.
- If no latest availability or no available slot exists, leave the form unchanged and show a status message.
- Save remains the only action that persists the rule to `watch-rules.json`.

## Architecture

`ZacksBarCore` owns the message-to-slot parser and suggestion builder so notification matching and settings suggestions share the same protocol interpretation. `ZacksBarApp` exposes a small `AppModel.makeWatchRuleSuggestion()` method that reads `latest-state.json` from `AppSupportStore`. The AppKit window stays thin and only mutates form fields.
