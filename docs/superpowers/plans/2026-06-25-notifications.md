# Notification Alerts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add captcha and watch-rule macOS notifications with session-level dedupe and direct Chrome page jumps.

**Architecture:** `ZacksBarCore` computes pure `PendingNotification` values from latest state and watch rules. `ZacksBarApp` delivers those values through `UserNotifications` and handles notification clicks by opening the action URL in Chrome, falling back to the default browser when Chrome is unavailable.

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

### Task 2: App Notification Evaluation

**Files:**
- Modify: `apps/macos/Package.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/AppModel.swift`
- Create: `apps/macos/Tests/ZacksBarAppTests/AppModelNotificationTests.swift`

- [ ] Add a `ZacksBarAppTests` test target.
- [ ] Write a failing test that stores a matching availability message, initializes `AppModel` with a mock notification delivery object, and asserts one notification is delivered.
- [ ] Write a failing test that calls `handle(message:)` twice with the same captcha message and asserts delivery happens once.
- [ ] Run `swift test --filter AppModelNotificationTests` and confirm the tests fail because `AppModel` has no delivery injection or notification evaluation.
- [ ] Inject a notification delivery protocol into `AppModel`.
- [ ] Add session-level delivered notification IDs in `AppModel`.
- [ ] Evaluate pending notifications after `reloadLatestState()` and `handle(message:)`.
- [ ] Run `swift test --filter AppModelNotificationTests` and confirm the tests pass.
- [ ] Commit with `feat: evaluate app notifications`.

### Task 3: macOS Notification Delivery

**Files:**
- Create: `apps/macos/Sources/ZacksBarApp/NotificationDelivery.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/ZacksBarApplication.swift`

- [ ] Add an app-layer `NotificationDelivering` protocol.
- [ ] Implement `MacNotificationDelivery` using `UNUserNotificationCenter`.
- [ ] Request notification authorization on app launch.
- [ ] Add a `BrowserOpening` protocol.
- [ ] Implement `ChromeBrowserOpener` using Chrome bundle identifier first and default browser fallback second.
- [ ] Handle notification click responses by opening `actionURL` from notification `userInfo`.
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
