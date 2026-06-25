# Notification Alerts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add captcha and watch-rule macOS notifications with session-level dedupe and Chrome page jump commands.

**Architecture:** `ZacksBarCore` computes pure `PendingNotification` values from latest state and watch rules. `ZacksBarApp` delivers those values through `UserNotifications` and writes `tab.open` commands through the existing app support store.

**Tech Stack:** Swift Package Manager, XCTest, AppKit, UserNotifications, existing Chrome native messaging files.

---

### Task 1: Core Notification Decisions

**Files:**
- Create: `apps/macos/Sources/ZacksBarCore/NotificationDecision.swift`
- Create: `apps/macos/Tests/ZacksBarCoreTests/NotificationDecisionTests.swift`
- Modify: `apps/macos/Sources/ZacksBarCore/WatchRule.swift`

- [ ] Write tests for captcha notification creation, availability match creation, non-match suppression, and dedupe.
- [ ] Run `swift test --filter NotificationDecisionTests` and confirm the tests fail because `NotificationDecision` does not exist.
- [ ] Add `PendingNotification`, `NotificationDecision`, and small JSON helpers needed to read slots and page URLs.
- [ ] Keep rule matching on existing `WatchRule.match(slots:)`.
- [ ] Run `swift test --filter NotificationDecisionTests` and confirm the tests pass.
- [ ] Commit with `feat: add notification decision model`.

### Task 2: Store Browser Commands

**Files:**
- Modify: `apps/macos/Sources/ZacksBarCore/AppSupportStore.swift`
- Modify: `apps/macos/Tests/ZacksBarCoreTests/AppSupportStoreTests.swift`

- [ ] Write a failing test that calls `appendCommand` with a `tab.open` command and asserts `native-commands.jsonl` contains one encoded line.
- [ ] Run `swift test --filter AppSupportStoreTests` and confirm the new test fails because `appendCommand` does not exist.
- [ ] Implement `appendCommand(_:)` by reusing the existing private line append helper.
- [ ] Run `swift test --filter AppSupportStoreTests` and confirm the tests pass.
- [ ] Commit with `feat: persist browser open commands`.

### Task 3: macOS Notification Delivery

**Files:**
- Create: `apps/macos/Sources/ZacksBarApp/NotificationDelivery.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/AppModel.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/ZacksBarApplication.swift`

- [ ] Add an app-layer `NotificationDelivering` protocol.
- [ ] Implement `MacNotificationDelivery` using `UNUserNotificationCenter`.
- [ ] Request notification authorization on app launch.
- [ ] Add `AppModel.evaluateNotifications()` that uses Core decisions, delivery, and command persistence.
- [ ] Call evaluation after `reloadLatestState()` and `handle(message:)`.
- [ ] Run `swift build` and `swift test`.
- [ ] Commit with `feat: deliver macos notifications`.

### Task 4: Documentation and Full Verification

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/development-smoke-test.md`
- Modify: `docs/troubleshooting.md`

- [ ] Document captcha and availability notifications.
- [ ] Document notification permission and browser jump behavior.
- [ ] Run `npm test`.
- [ ] Run `cd apps/macos && swift test`.
- [ ] Run `cd apps/macos && swift build`.
- [ ] Run `git ls-files | rg 'prory|wxsports|native-events|native-commands|latest-state|apps/macos/\.build'` and expect no matches.
- [ ] Commit with `docs: document notification alerts`.
