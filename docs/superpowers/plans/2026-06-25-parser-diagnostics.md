# Parser Diagnostics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add parser diagnostics to make real ydmap smoke testing debuggable.

**Architecture:** Chrome content script emits deduped `parser.diagnostics`; Swift core persists and summarizes the latest parser diagnostics; diagnostics/setup surfaces display the key parser state.

**Tech Stack:** Chrome MV3 JavaScript, Node test runner, Swift Package Manager, XCTest.

---

### Task 1: Content Script Parser Diagnostics

**Files:**
- Modify: `extensions/chrome/src/content/ydmap_content.js`
- Modify: `extensions/chrome/test/ydmap_content.test.js`

- [ ] Write failing tests for parser diagnostics on empty and populated Vue pages.
- [ ] Run `npm test` and verify tests fail because parser diagnostics APIs do not exist.
- [ ] Implement `buildParserDiagnosticsPayload`, `buildParserDiagnosticsMessage`, and deduped `inspectCurrentPage` sending.
- [ ] Run `npm test` and verify all JS/protocol tests pass.
- [ ] Commit with `feat: emit parser diagnostics from content script`.

### Task 2: Persist Parser Diagnostics

**Files:**
- Modify: `apps/macos/Sources/ZacksBarCore/AppSupportStore.swift`
- Modify: `apps/macos/Tests/ZacksBarCoreTests/AppSupportStoreTests.swift`

- [ ] Write failing Swift test that appends `parser.diagnostics` and reads it from latest state.
- [ ] Run `swift test` and verify failure.
- [ ] Add `latestParserDiagnostics` to `LatestAppState` and update persistence.
- [ ] Run `swift test`.
- [ ] Commit with `feat: persist latest parser diagnostics`.

### Task 3: Display Parser Diagnostics

**Files:**
- Modify: `apps/macos/Sources/ZacksBarCore/DiagnosticReport.swift`
- Modify: `apps/macos/Sources/ZacksBarCore/SetupChecklist.swift`
- Modify: `apps/macos/Sources/ZacksBarCore/MenuState.swift`
- Modify: `apps/macos/Tests/ZacksBarCoreTests/DiagnosticReportTests.swift`
- Modify: `apps/macos/Tests/ZacksBarCoreTests/SetupChecklistTests.swift`
- Modify: `apps/macos/Tests/ZacksBarCoreTests/MenuStateTests.swift`

- [ ] Write failing Swift tests for parser diagnostics rows and setup checklist parser step.
- [ ] Run `swift test` and verify failure.
- [ ] Implement parser diagnostics rows, setup step, and menu fallback.
- [ ] Run `swift test` and `swift build`.
- [ ] Commit with `feat: surface parser diagnostics in setup and diagnostics`.

### Task 4: Documentation And Verification

**Files:**
- Modify: `docs/development-smoke-test.md`
- Modify: `docs/troubleshooting.md`
- Modify: `README.md`

- [ ] Document parser diagnostics and real browser smoke-test interpretation.
- [ ] Run `npm test`.
- [ ] Run `swift test` in `apps/macos`.
- [ ] Run `swift build` in `apps/macos`.
- [ ] Confirm no ignored local reference files or runtime/build artifacts are tracked with `git ls-files | rg 'prory|wxsports|native-events|native-commands|latest-state|apps/macos/\\.build'`.
- [ ] Commit with `docs: document parser diagnostics`.
