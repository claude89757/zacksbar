# Time Range Only Alert Settings Design

## Goal

Alert settings should ask for only the time range, plus optional court keywords. Users should not choose a date or date mode.

## Scope

This is a UX simplification of the existing primary watch rule. The saved rule still uses the existing `WatchRule` Codable shape for compatibility, but `dateMode` is no longer user-facing and is normalized to `latestBookable` when the app saves rules.

## Behavior

- `Alert Settings...` shows Start, End, and Court keywords.
- The summary shows only `<start>-<end>` and the court filter.
- Diagnostics `Primary Watch Rule` shows only the time range and court filter.
- Documentation describes time-range settings only.
- Existing persisted files with non-default `dateMode` can still be decoded, but future app saves fix the field to `latestBookable`.

## Out Of Scope

This iteration does not remove `DateMode` or change the on-disk Codable schema. Removing it would require a storage migration and gives little user value while date matching is not currently implemented.

## Remaining Product Work

After this fix, the main remaining work is:

- real browser smoke testing against a logged-in ydmap session;
- page-assisted settings that prefill the current available times/courts;
- pause/snooze controls;
- signed/releasable macOS packaging and auto-update strategy;
- extension release/update flow;
- better parser resilience when ydmap changes its Vue component shape.
