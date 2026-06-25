# Browser Companion Reload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Chrome companion version visibility and a local reload command path from the macOS Setup Assistant to the extension service worker.

**Architecture:** `ZacksBarCore` persists queued native commands in `native-commands.jsonl`. `ZacksBarNativeHost` drains queued commands on the next browser message and sends them back to Chrome. `ZacksBarApp` queues `extension.reload`, while the MV3 service worker handles that command with `chrome.runtime.reload()`.

**Tech Stack:** Swift Package Manager, AppKit, Chrome MV3 JavaScript, Node.js `node:test`.

---

### Task 1: Core Command Queue

**Files:**
- Modify: `apps/macos/Sources/ZacksBarCore/AppSupportStore.swift`
- Modify: `apps/macos/Tests/ZacksBarCoreTests/AppSupportStoreTests.swift`

- [x] **Step 1: Write failing queue tests**

Add tests that append two `NativeMessage` commands, drain them, verify ordering, verify the file is removed after drain, and verify malformed JSONL lines are skipped.

- [x] **Step 2: Run the tests and verify failure**

Run: `swift test --filter AppSupportStoreTests`
Expected: failure because `appendCommand` and `drainCommands` do not exist.

- [x] **Step 3: Implement queue methods**

Add `appendCommand(_:)` using the existing private `appendLine` helper. Add `drainCommands()` that reads `native-commands.jsonl`, decodes valid command lines, removes the file, and returns valid commands in file order.

- [x] **Step 4: Run tests and commit**

Run: `swift test --filter AppSupportStoreTests`
Expected: all `AppSupportStoreTests` pass.

Commit message: `feat: add native command queue`.

### Task 2: Native Host Command Drain

**Files:**
- Modify: `apps/macos/Sources/ZacksBarNativeHost/main.swift`

- [x] **Step 1: Wire queued commands into host output**

After `store.appendEvent(message)`, call `try store.drainCommands()` and write each command to stdout before the normal ack.

- [x] **Step 2: Run Swift tests**

Run: `swift test`
Expected: all Swift tests pass.

Commit message: `feat: send queued commands from native host`.

### Task 3: Browser Service Worker Command Handling

**Files:**
- Modify: `extensions/chrome/src/background/service_worker.js`
- Add: `extensions/chrome/test/service_worker.test.js`

- [x] **Step 1: Write failing service worker tests**

Create a VM-based test that stubs `chrome.runtime.connectNative`, captures the native port message listener, dispatches `{ type: "extension.reload" }`, and asserts `chrome.runtime.reload()` was called once. Also assert existing `tab.open` still creates a tab.

- [x] **Step 2: Run JavaScript tests and verify failure**

Run: `npm test`
Expected: service worker tests fail because `extension.reload` is not handled.

- [x] **Step 3: Implement command handler**

Extract `handleNativeMessage(message)` in `service_worker.js`. Keep `tab.open` behavior and add `extension.reload` behavior.

- [x] **Step 4: Run JavaScript tests and commit**

Run: `npm test`
Expected: all JavaScript and protocol tests pass.

Commit message: `feat: reload companion extension on command`.

### Task 4: Setup Assistant Status and Action

**Files:**
- Modify: `apps/macos/Sources/ZacksBarCore/SetupChecklist.swift`
- Modify: `apps/macos/Tests/ZacksBarCoreTests/SetupChecklistTests.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/AppModel.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/SetupAssistantWindowController.swift`
- Modify: `apps/macos/Tests/ZacksBarAppTests/AppModelNotificationTests.swift`

- [x] **Step 1: Write failing setup checklist tests**

Add tests for `Browser Companion` values:
- `waiting` when no health ping exists.
- `0.1.0` ready when latest health payload version equals expected.
- `reload 0.0.9 -> 0.1.0` missing when latest health payload version differs.

- [x] **Step 2: Run Swift tests and verify failure**

Run: `swift test --filter SetupChecklistTests`
Expected: failure because the `Browser Companion` row does not exist.

- [x] **Step 3: Implement checklist row**

Add an `expectedCompanionVersion` parameter defaulting to `"0.1.0"` to `makeSetupChecklist`. Read `latestHealth.payload["version"]?.stringValue` and add the row after `Latest Browser State`.

- [x] **Step 4: Add app model reload command test**

Test that `AppModel.requestBrowserCompanionReload()` writes one `extension.reload` command to the store command queue.

- [x] **Step 5: Implement app model and UI action**

Add `AppModel.requestBrowserCompanionReload()`. Add a `Reload Browser Extension` button to `SetupAssistantWindowController` that queues the command, updates status text, and refreshes the checklist.

- [x] **Step 6: Run Swift tests and commit**

Run: `swift test`
Expected: all Swift tests pass.

Commit message: `feat: show companion version and queue reload`.

### Task 5: Documentation and Verification

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/development-smoke-test.md`
- Modify: `docs/install.md`
- Modify: `docs/troubleshooting.md`
- Modify: `docs/superpowers/plans/2026-06-26-browser-companion-reload.md`

- [x] **Step 1: Update docs**

Document that Setup Assistant shows `Browser Companion`, and that `Reload Browser Extension` queues an `extension.reload` command for the next browser connection.

- [x] **Step 2: Run full verification**

Run:

```bash
npm test
cd apps/macos
swift test
swift build
cd ../..
git status --short
git ls-files | rg 'prory|wxsports|native-events|native-commands|latest-state|apps/macos/\\.build' || true
```

Expected:
- JavaScript tests pass.
- Swift tests pass.
- Swift build succeeds.
- `git status --short` only shows intended source/doc changes before commit and is clean after commit.
- Sensitive tracked-file check prints nothing.

- [x] **Step 3: Commit docs and merge**

Commit message: `docs: document browser companion reload`.

Merge into `main`, push `main`, remove the worktree, and delete the feature branch.
