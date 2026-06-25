# Watch Rule Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a menu bar settings window that persists and applies the primary availability alert rule.

**Architecture:** `ZacksBarCore` persists rules in `watch-rules.json` and supplies the default rule when no file exists. `ZacksBarApp` loads rules into `AppModel`, saves edits through `AppModel`, and exposes a compact AppKit settings window from the menu.

**Tech Stack:** Swift Package Manager, XCTest, AppKit, existing `WatchRule` model and `AppSupportStore`.

---

### Task 1: Core Watch Rule Persistence

**Files:**
- Modify: `apps/macos/Sources/ZacksBarCore/WatchRule.swift`
- Modify: `apps/macos/Sources/ZacksBarCore/AppSupportStore.swift`
- Modify: `apps/macos/Tests/ZacksBarCoreTests/AppSupportStoreTests.swift`

- [ ] Write a failing test named `testReadWatchRulesReturnsDefaultWhenFileIsMissing` that expects one rule with id `default-evening`, `dateMode` `.latestBookable`, start `19:00`, end `21:00`, and empty keywords.
- [ ] Write a failing test named `testWriteAndReadWatchRulesRoundTrips` that writes a rule from `18:00` to `20:00` with keyword `1号` and reads it back.
- [ ] Run `swift test --filter AppSupportStoreTests` and confirm the tests fail because watch-rule persistence APIs do not exist.
- [ ] Add `WatchRule.defaultRules` to `WatchRule.swift`.
- [ ] Add `watchRulesFile`, `readWatchRules()`, and `writeWatchRules(_:)` to `AppSupportStore`.
- [ ] Run `swift test --filter AppSupportStoreTests` and confirm the tests pass.
- [ ] Commit with `feat: persist watch rules`.

### Task 2: AppModel Rule Loading and Saving

**Files:**
- Modify: `apps/macos/Sources/ZacksBarApp/AppModel.swift`
- Modify: `apps/macos/Tests/ZacksBarAppTests/AppModelNotificationTests.swift`

- [ ] Write a failing test named `testInitializesWithPersistedWatchRules` that saves a persisted rule before creating `AppModel` and asserts `model.rules` equals that persisted rule.
- [ ] Write a failing test named `testSaveWatchRulePersistsAndUpdatesNotifications` that saves a rule for `18:00-20:00`, then handles matching availability and expects a notification for that saved range.
- [ ] Run `swift test --filter AppModelNotificationTests` and confirm the tests fail because `AppModel` does not load or save persisted rules.
- [ ] Change `AppModel.rules` initialization to load from `store.readWatchRules()` or fall back to `WatchRule.defaultRules`.
- [ ] Add `savePrimaryWatchRule(_:)` that stores one rule, updates `rules`, and reloads latest state.
- [ ] Run `swift test --filter AppModelNotificationTests` and confirm the tests pass.
- [ ] Commit with `feat: wire persisted watch rules into app model`.

### Task 3: Watch Rule Settings Window

**Files:**
- Create: `apps/macos/Sources/ZacksBarApp/WatchRuleSettingsWindowController.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/MenuController.swift`

- [ ] Add `WatchRuleSettingsWindowController` with date mode popup, start field, end field, court keywords field, status label, and Save button.
- [ ] Add `Alert Settings...` menu item that opens the settings window.
- [ ] Keep `Create watch rule from current page` disabled or absent until page-derived drafts are implemented.
- [ ] Run `swift build` and confirm the app target compiles.
- [ ] Commit with `feat: add watch rule settings window`.

### Task 4: Diagnostics and Documentation

**Files:**
- Modify: `apps/macos/Sources/ZacksBarCore/DiagnosticReport.swift`
- Modify: `apps/macos/Tests/ZacksBarCoreTests/DiagnosticReportTests.swift`
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/development-smoke-test.md`
- Modify: `docs/troubleshooting.md`

- [ ] Add diagnostic rows for watch rules file status and primary rule summary.
- [ ] Write and pass a focused diagnostic report test.
- [ ] Document `watch-rules.json`, the alert settings window, and the primary-rule scope.
- [ ] Run `npm test`.
- [ ] Run `cd apps/macos && swift test`.
- [ ] Run `cd apps/macos && swift build`.
- [ ] Run `git ls-files | rg 'prory|wxsports|native-events|native-commands|latest-state|apps/macos/\.build'` and expect no matches.
- [ ] Commit with `docs: document watch rule settings`.
