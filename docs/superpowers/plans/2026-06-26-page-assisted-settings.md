# Page Assisted Alert Settings Implementation Plan

## Summary

Add a tested core helper that turns the latest availability snapshot into a time-range suggestion, expose it through `AppModel`, and wire it to a `Use Current Page` button in the alert settings window.

## Steps

- [x] Add `WatchRuleSuggestion` and `WatchRuleSuggestionBuilder`.
- [x] Move availability slot parsing to shared core code.
- [x] Reuse the shared parser from notification decisions.
- [x] Add core tests for merged continuous ranges and empty availability.
- [x] Add an app model test for suggestions from persisted latest state.
- [x] Add `Use Current Page` to `Alert Settings...`.
- [x] Update README, architecture, smoke test, and troubleshooting docs.
- [x] Run full verification before merge.
