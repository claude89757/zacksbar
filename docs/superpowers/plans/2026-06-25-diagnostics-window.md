# Diagnostics Window Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a native diagnostics window that helps users and developers verify Chrome/native/menu bar integration.

**Architecture:** Swift core owns the diagnostic report model and plain-text export. The AppKit menu app owns a small window controller that renders the report and exposes Refresh/Copy actions.

**Tech Stack:** Swift Package Manager, AppKit, XCTest.

---

### Task 1: Core Diagnostic Report

**Files:**
- Create: `apps/macos/Sources/ZacksBarCore/DiagnosticReport.swift`
- Create: `apps/macos/Tests/ZacksBarCoreTests/DiagnosticReportTests.swift`

- [ ] Write a failing Swift test that builds a report for an empty temp store and verifies missing latest state and manifest status.
- [ ] Run `swift test` in `apps/macos` and verify the test fails because `DiagnosticReport` does not exist.
- [ ] Implement `DiagnosticReport`, `DiagnosticRow`, and `AppSupportStore.makeDiagnosticReport(nativeHostManifestPath:)`.
- [ ] Run `swift test` and verify all Swift tests pass.
- [ ] Commit with `feat: add diagnostic report model`.

### Task 2: Latest-State Diagnostics

**Files:**
- Modify: `apps/macos/Tests/ZacksBarCoreTests/DiagnosticReportTests.swift`
- Modify: `apps/macos/Sources/ZacksBarCore/DiagnosticReport.swift`

- [ ] Write a failing Swift test that appends an availability message, builds a report, and verifies latest message/status/plain text.
- [ ] Run `swift test` and verify the new test fails.
- [ ] Implement latest state summarization and `plainText`.
- [ ] Run `swift test` and verify all Swift tests pass.
- [ ] Commit with `feat: summarize latest state diagnostics`.

### Task 3: AppKit Diagnostics Window

**Files:**
- Create: `apps/macos/Sources/ZacksBarApp/DiagnosticsWindowController.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/MenuController.swift`
- Modify: `apps/macos/Sources/ZacksBarApp/AppModel.swift`

- [ ] Implement `AppModel.makeDiagnosticReport()`.
- [ ] Implement `DiagnosticsWindowController` with report rows, Refresh, and Copy Report.
- [ ] Wire `Settings and diagnostics...` menu item to open the window.
- [ ] Run `swift build` and `swift test`.
- [ ] Commit with `feat: add diagnostics window`.

### Task 4: Documentation And Final Verification

**Files:**
- Modify: `README.md`
- Modify: `docs/development-smoke-test.md`
- Modify: `docs/troubleshooting.md`

- [ ] Document the diagnostics window and Copy Report flow.
- [ ] Run `npm test`.
- [ ] Run `swift test` in `apps/macos`.
- [ ] Run `swift build` in `apps/macos`.
- [ ] Confirm no ignored local reference files or runtime/build artifacts are tracked with `git ls-files | rg 'prory|wxsports|native-events|native-commands|latest-state|apps/macos/\\.build'`.
- [ ] Commit with `docs: document diagnostics window`.
