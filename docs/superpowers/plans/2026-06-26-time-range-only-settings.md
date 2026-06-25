# Time Range Only Alert Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove date mode from alert settings while preserving storage compatibility.

**Architecture:** Keep `WatchRule.dateMode` in the model for compatibility, but normalize app-saved rules to `.latestBookable`. Update UI, diagnostics, and docs so users only see time range plus optional court keywords.

**Tech Stack:** Swift Package Manager, XCTest, AppKit, existing `WatchRule`, `AppModel`, and diagnostics code.

---

### Task 1: AppModel Normalization

**Files:**
- Modify: `apps/macos/Tests/ZacksBarAppTests/AppModelNotificationTests.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/AppModel.swift`

- [ ] Write a failing assertion that `savePrimaryWatchRule` persists a rule with `.latestBookable` even if the caller passes `.tomorrow`.
- [ ] Run `swift test --filter AppModelNotificationTests` and confirm the assertion fails.
- [ ] Normalize saved rules inside `AppModel.savePrimaryWatchRule(_:)`.
- [ ] Run `swift test --filter AppModelNotificationTests` and confirm the tests pass.
- [ ] Commit with `feat: normalize saved watch rules to time range`.

### Task 2: Date-Free UI and Diagnostics

**Files:**
- Modify: `apps/macos/Sources/ZacksBarApp/WatchRuleSettingsWindowController.swift`
- Modify: `apps/macos/Tests/ZacksBarCoreTests/DiagnosticReportTests.swift`
- Modify: `apps/macos/Sources/ZacksBarCore/DiagnosticReport.swift`

- [ ] Update the diagnostic test to expect `18:00-20:00 1号, 室内`.
- [ ] Run `swift test --filter DiagnosticReportTests` and confirm the test fails.
- [ ] Remove the date mode popup and date-mode summary from the settings window.
- [ ] Update diagnostic summary formatting to omit `dateMode`.
- [ ] Run `swift test --filter DiagnosticReportTests` and `swift build`.
- [ ] Commit with `feat: make alert settings time range only`.

### Task 3: Documentation and Verification

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/development-smoke-test.md`
- Modify: `docs/troubleshooting.md`
- Modify: `docs/superpowers/specs/2026-06-26-watch-rule-settings-design.md`
- Modify: `docs/superpowers/plans/2026-06-26-watch-rule-settings.md`

- [ ] Remove user-facing date-mode references from current docs.
- [ ] Keep old product-planning docs unchanged unless they describe current behavior.
- [ ] Run `npm test`.
- [ ] Run `cd apps/macos && swift test`.
- [ ] Run `cd apps/macos && swift build`.
- [ ] Run `git ls-files | rg 'prory|wxsports|native-events|native-commands|latest-state|apps/macos/\.build'` and expect no matches.
- [ ] Commit with `docs: document time range only settings`.
