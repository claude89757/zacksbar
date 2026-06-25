# Setup Assistant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a native setup assistant that installs the Chrome Native Messaging manifest and shows first-run setup health.

**Architecture:** Swift core owns validation, manifest installation, and setup checklist state. The AppKit app owns a small window for extension ID input, install, refresh, and diagnostics.

**Tech Stack:** Swift Package Manager, AppKit, XCTest.

---

### Task 1: Native Host Installer Core

**Files:**
- Create: `apps/macos/Sources/ZacksBarCore/NativeHostInstaller.swift`
- Create: `apps/macos/Tests/ZacksBarCoreTests/NativeHostInstallerTests.swift`

- [ ] Write failing tests for valid/invalid Chrome extension IDs and manifest installation output.
- [ ] Run `swift test` in `apps/macos` and verify tests fail because installer APIs do not exist.
- [ ] Implement `ChromeExtensionID`, `NativeHostInstaller`, and manifest writing.
- [ ] Run `swift test` and verify all Swift tests pass.
- [ ] Commit with `feat: add native host installer core`.

### Task 2: Setup Checklist Core

**Files:**
- Create: `apps/macos/Sources/ZacksBarCore/SetupChecklist.swift`
- Create: `apps/macos/Tests/ZacksBarCoreTests/SetupChecklistTests.swift`

- [ ] Write failing tests for setup checklist rows with missing manifest and with installed manifest/latest state.
- [ ] Run `swift test` and verify tests fail because checklist APIs do not exist.
- [ ] Implement `SetupChecklist`, `SetupStep`, and `AppSupportStore.makeSetupChecklist(...)`.
- [ ] Run `swift test` and verify all Swift tests pass.
- [ ] Commit with `feat: add setup checklist model`.

### Task 3: AppKit Setup Assistant Window

**Files:**
- Create: `apps/macos/Sources/ZacksBarApp/SetupAssistantWindowController.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/AppModel.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/MenuController.swift`

- [ ] Implement `AppModel.installNativeHost(extensionID:)` and `AppModel.makeSetupChecklist(extensionID:)`.
- [ ] Implement a native setup assistant window with extension ID field, checklist rows, Install Native Host, Refresh, and Open Diagnostics.
- [ ] Add `Setup Assistant...` menu item.
- [ ] Run `swift build` and `swift test`.
- [ ] Commit with `feat: add setup assistant window`.

### Task 4: Documentation And Verification

**Files:**
- Modify: `README.md`
- Modify: `docs/install.md`
- Modify: `docs/development-smoke-test.md`
- Modify: `docs/troubleshooting.md`

- [ ] Document setup assistant flow.
- [ ] Run `npm test`.
- [ ] Run `swift test` in `apps/macos`.
- [ ] Run `swift build` in `apps/macos`.
- [ ] Confirm no ignored local reference files or runtime/build artifacts are tracked with `git ls-files | rg 'prory|wxsports|native-events|native-commands|latest-state|apps/macos/\\.build'`.
- [ ] Commit with `docs: document setup assistant`.
