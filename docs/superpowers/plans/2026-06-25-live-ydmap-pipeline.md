# Live ydmap Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make real ydmap availability flow from Chrome into local native state and the menu bar app.

**Architecture:** The Chrome content script extracts ydmap Vue schedule state and emits normalized protocol messages. The Swift native host appends every event and updates a compact `latest-state.json` that the menu bar app can load.

**Tech Stack:** Chrome MV3 JavaScript, Node test runner, Swift Package Manager, AppKit menu bar app.

---

### Task 1: Real ydmap Vue Parser

**Files:**
- Modify: `extensions/chrome/src/content/ydmap_content.js`
- Modify: `extensions/chrome/test/ydmap_content.test.js`

- [ ] Write a failing JavaScript test with a fake Vue component tree containing schedule parent, table rows, platform metadata, and `isAvailableStatic`.
- [ ] Run `npm test` and verify the new parser test fails because `extractYdmapAvailability` is not defined.
- [ ] Implement Vue component discovery, time formatting, and snapshot extraction in `ydmap_content.js`.
- [ ] Run `npm test` and verify all JavaScript/protocol tests pass.
- [ ] Commit with `feat: parse live ydmap vue availability`.

### Task 2: Polling And Deduped Availability Sending

**Files:**
- Modify: `extensions/chrome/src/content/ydmap_content.js`
- Modify: `extensions/chrome/test/ydmap_content.test.js`

- [ ] Write a failing JavaScript test proving `inspectCurrentPage` sends one `availability.updated` message for an unchanged snapshot across two inspections.
- [ ] Run `npm test` and verify the new dedupe test fails.
- [ ] Update `inspectCurrentPage` to emit captcha events and deduped availability snapshots.
- [ ] Run `npm test` and verify all JavaScript/protocol tests pass.
- [ ] Commit with `feat: send deduped live availability updates`.

### Task 3: Native Latest State Store

**Files:**
- Modify: `apps/macos/Sources/ZacksBarCore/AppSupportStore.swift`
- Create: `apps/macos/Tests/ZacksBarCoreTests/AppSupportStoreTests.swift`

- [ ] Write a failing Swift test that appends an availability message and reads `latest-state.json`.
- [ ] Run `swift test` in `apps/macos` and verify the test fails because latest state APIs do not exist.
- [ ] Implement `LatestAppState` and update `AppSupportStore.appendEvent(_:)` to write latest state for supported message types.
- [ ] Run `swift test` and verify all Swift tests pass.
- [ ] Commit with `feat: persist latest native app state`.

### Task 4: Menu App Loads Latest State

**Files:**
- Modify: `apps/macos/Sources/ZacksBarApp/AppModel.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/MenuController.swift`
- Create: `apps/macos/Tests/ZacksBarAppTests/AppModelTests.swift`
- Modify: `apps/macos/Package.swift`

- [ ] Write a failing Swift test that loads availability and captcha latest state into `AppModel`.
- [ ] Run `swift test` and verify the app model test fails.
- [ ] Make `AppModel` load `LatestAppState`, derive status text and alert text, and expose a refresh method.
- [ ] Add a Refresh menu item that reloads state and rebuilds the menu.
- [ ] Run `swift test` and `swift build`.
- [ ] Commit with `feat: show latest native state in menu bar`.

### Task 5: Documentation And Final Verification

**Files:**
- Modify: `docs/development-smoke-test.md`
- Modify: `docs/architecture.md`
- Modify: `README.md`

- [ ] Update docs to describe live Vue parsing and `latest-state.json`.
- [ ] Run `npm test`.
- [ ] Run `swift test` in `apps/macos`.
- [ ] Run `swift build` in `apps/macos`.
- [ ] Confirm no ignored local reference files or build artifacts are tracked with `git ls-files | rg 'prory|wxsports|native-events|native-commands|latest-state|apps/macos/\\.build'`.
- [ ] Commit with `docs: document live ydmap pipeline`.
