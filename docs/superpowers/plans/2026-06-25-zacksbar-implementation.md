# ZacksBar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete v1 product skeleton for ZacksBar: Swift macOS menu bar app, Chrome MV3 companion extension, Native Messaging host, shared protocol, setup health, diagnostics, tests, and CI.

**Architecture:** The Chrome content script reads ydmap booking page state and sends normalized messages to the MV3 service worker. The service worker talks to a Swift Native Messaging host over Chrome's official stdio protocol. The host and visible macOS menu bar app share state through a local Application Support event/command store so the UI can display live status and send browser commands without using a localhost bridge.

**Tech Stack:** Swift 5.9+, AppKit/SwiftUI for macOS, Swift Package Manager, Chrome Manifest V3, plain JavaScript with Node built-in tests for extension logic, JSON schemas for protocol contracts, GitHub Actions.

---

## Scope Check

This spec spans multiple subsystems. This plan intentionally starts with a vertical product skeleton because the highest risk is cross-process integration: page -> extension -> native host -> macOS UI. After this plan is complete, future feature work can split into smaller plans for parser hardening, UI polish, Sparkle, Chrome Web Store packaging, and additional venue support.

## File Structure

Create these top-level areas:

```text
zacksbar/
  apps/macos/
    Package.swift
    Sources/ZacksBarApp/
    Sources/ZacksBarCore/
    Sources/ZacksBarNativeHost/
    Tests/ZacksBarCoreTests/
    Tests/ZacksBarNativeHostTests/
  extensions/chrome/
    manifest.json
    src/background/service_worker.js
    src/content/ydmap_content.js
    src/lib/protocol.js
    test/
  packages/protocol/
    schemas/native-message.schema.json
    schemas/availability-updated.schema.json
    fixtures/
  scripts/
    validate-protocol.mjs
    install-native-host.sh
  docs/
    architecture.md
    install.md
    troubleshooting.md
    privacy.md
    contributing.md
  .github/workflows/
    ci.yml
```

Responsibility boundaries:

- `packages/protocol`: message schemas and fixture examples shared by Swift and extension tests.
- `extensions/chrome/src/content`: ydmap page inspection and safe prefill helpers only.
- `extensions/chrome/src/background`: Native Messaging connection, tab routing, health messages.
- `apps/macos/Sources/ZacksBarCore`: rules, alert de-duplication, redaction, setup health, local store.
- `apps/macos/Sources/ZacksBarNativeHost`: Chrome stdio framing and event/command bridge.
- `apps/macos/Sources/ZacksBarApp`: menu bar and settings window.

## Task 1: Repository Foundation And Protocol Schemas

**Files:**
- Create: `package.json`
- Create: `scripts/validate-protocol.mjs`
- Create: `packages/protocol/schemas/native-message.schema.json`
- Create: `packages/protocol/schemas/availability-updated.schema.json`
- Create: `packages/protocol/fixtures/availability.updated.json`
- Create: `packages/protocol/fixtures/captcha.detected.json`

- [ ] **Step 1: Create root Node test script**

Create `package.json`:

```json
{
  "name": "zacksbar",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test extensions/chrome/test/*.test.js && node scripts/validate-protocol.mjs",
    "test:protocol": "node scripts/validate-protocol.mjs"
  },
  "engines": {
    "node": ">=20"
  }
}
```

- [ ] **Step 2: Define the base Native Messaging schema**

Create `packages/protocol/schemas/native-message.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://zacksbar.dev/schemas/native-message.schema.json",
  "title": "ZacksBar Native Message",
  "type": "object",
  "required": ["schemaVersion", "messageId", "type", "sentAt", "source", "payload"],
  "additionalProperties": false,
  "properties": {
    "schemaVersion": { "type": "integer", "minimum": 1 },
    "messageId": { "type": "string", "minLength": 1 },
    "type": {
      "type": "string",
      "enum": [
        "page.snapshot",
        "availability.updated",
        "captcha.detected",
        "rule.createDraft",
        "rule.match",
        "tab.open",
        "tab.prefill",
        "health.ping",
        "diagnostics.export"
      ]
    },
    "sentAt": { "type": "string", "format": "date-time" },
    "source": {
      "type": "string",
      "enum": ["content-script", "service-worker", "native-host", "mac-app"]
    },
    "payload": { "type": "object" }
  }
}
```

- [ ] **Step 3: Define availability payload schema**

Create `packages/protocol/schemas/availability-updated.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://zacksbar.dev/schemas/availability-updated.schema.json",
  "title": "Availability Updated Payload",
  "type": "object",
  "required": ["venue", "pageUrl", "dateLabel", "courts", "slots"],
  "additionalProperties": false,
  "properties": {
    "venue": { "type": "string", "minLength": 1 },
    "pageUrl": { "type": "string", "minLength": 1 },
    "dateLabel": { "type": "string", "minLength": 1 },
    "courts": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "name"],
        "additionalProperties": false,
        "properties": {
          "id": { "type": "string", "minLength": 1 },
          "name": { "type": "string", "minLength": 1 }
        }
      }
    },
    "slots": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["courtId", "start", "end", "available"],
        "additionalProperties": false,
        "properties": {
          "courtId": { "type": "string", "minLength": 1 },
          "start": { "type": "string", "pattern": "^[0-2][0-9]:[0-5][0-9]$" },
          "end": { "type": "string", "pattern": "^[0-2][0-9]:[0-5][0-9]$" },
          "available": { "type": "boolean" }
        }
      }
    }
  }
}
```

- [ ] **Step 4: Add protocol fixtures**

Create `packages/protocol/fixtures/availability.updated.json`:

```json
{
  "schemaVersion": 1,
  "messageId": "fixture-availability-1",
  "type": "availability.updated",
  "sentAt": "2026-06-25T12:00:00Z",
  "source": "content-script",
  "payload": {
    "venue": "bawtt tennis",
    "pageUrl": "https://bawtt.ydmap.cn/booking/schedule/example",
    "dateLabel": "latest",
    "courts": [
      { "id": "court-1", "name": "1号场" },
      { "id": "court-5", "name": "5号场" }
    ],
    "slots": [
      { "courtId": "court-1", "start": "19:00", "end": "20:00", "available": true },
      { "courtId": "court-1", "start": "20:00", "end": "21:00", "available": true },
      { "courtId": "court-5", "start": "19:00", "end": "20:00", "available": false }
    ]
  }
}
```

Create `packages/protocol/fixtures/captcha.detected.json`:

```json
{
  "schemaVersion": 1,
  "messageId": "fixture-captcha-1",
  "type": "captcha.detected",
  "sentAt": "2026-06-25T12:01:00Z",
  "source": "content-script",
  "payload": {
    "pageUrl": "https://bawtt.ydmap.cn/booking/service/example",
    "reason": "aliyun-slider",
    "textEvidence": "请完成滑动验证"
  }
}
```

- [ ] **Step 5: Add schema validation script**

Create `scripts/validate-protocol.mjs`:

```js
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import assert from 'node:assert/strict';

const root = new URL('..', import.meta.url).pathname;
const fixturesDir = join(root, 'packages/protocol/fixtures');
const requiredBaseKeys = ['schemaVersion', 'messageId', 'type', 'sentAt', 'source', 'payload'];
const allowedTypes = new Set([
  'page.snapshot',
  'availability.updated',
  'captcha.detected',
  'rule.createDraft',
  'rule.match',
  'tab.open',
  'tab.prefill',
  'health.ping',
  'diagnostics.export'
]);

function readJson(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}

function validateBaseMessage(message, file) {
  for (const key of requiredBaseKeys) {
    assert.ok(Object.hasOwn(message, key), `${file} missing ${key}`);
  }
  assert.equal(message.schemaVersion, 1, `${file} schemaVersion must be 1`);
  assert.equal(typeof message.messageId, 'string', `${file} messageId must be string`);
  assert.ok(allowedTypes.has(message.type), `${file} type ${message.type} is not allowed`);
  assert.doesNotThrow(() => new Date(message.sentAt).toISOString(), `${file} sentAt must be ISO date`);
  assert.equal(typeof message.payload, 'object', `${file} payload must be object`);
}

for (const file of readdirSync(fixturesDir).filter((name) => name.endsWith('.json'))) {
  validateBaseMessage(readJson(join(fixturesDir, file)), file);
}

console.log('Protocol fixtures valid');
```

- [ ] **Step 6: Run protocol validation**

Run:

```bash
npm run test:protocol
```

Expected:

```text
Protocol fixtures valid
```

- [ ] **Step 7: Commit foundation**

Run:

```bash
git add package.json scripts/validate-protocol.mjs packages/protocol
git commit -m "feat: add protocol schemas and fixtures"
```

## Task 2: Chrome Extension Parser And Messaging Skeleton

**Files:**
- Create: `extensions/chrome/manifest.json`
- Create: `extensions/chrome/src/lib/protocol.js`
- Create: `extensions/chrome/src/content/ydmap_content.js`
- Create: `extensions/chrome/src/background/service_worker.js`
- Create: `extensions/chrome/test/ydmap_content.test.js`

- [ ] **Step 1: Write content parser tests**

Create `extensions/chrome/test/ydmap_content.test.js`:

```js
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('../src/content/ydmap_content.js', import.meta.url), 'utf8');
const sandbox = {
  console,
  setInterval() {},
  location: { href: 'https://bawtt.ydmap.cn/booking/schedule/example' }
};
sandbox.globalThis = sandbox;
vm.createContext(sandbox);
vm.runInContext(source, sandbox);

const {
  detectCaptchaFromText,
  normalizeAvailability,
  selectContinuousRange
} = sandbox.ZacksBarContent;

test('detectCaptchaFromText detects slider captcha copy', () => {
  assert.equal(detectCaptchaFromText('请完成滑动验证后继续'), true);
  assert.equal(detectCaptchaFromText('普通订场页面'), false);
});

test('normalizeAvailability converts grid data to protocol payload', () => {
  const payload = normalizeAvailability({
    venue: 'bawtt tennis',
    pageUrl: 'https://bawtt.ydmap.cn/booking/schedule/example?token=secret',
    dateLabel: 'latest',
    courts: [{ id: 'court-1', name: '1号场' }],
    rows: [
      [{ courtId: 'court-1', start: '19:00', end: '20:00', available: true }],
      [{ courtId: 'court-1', start: '20:00', end: '21:00', available: true }]
    ]
  });

  assert.equal(payload.pageUrl, 'https://bawtt.ydmap.cn/booking/schedule/example');
  assert.equal(payload.slots.length, 2);
  assert.equal(payload.slots[0].available, true);
});

test('selectContinuousRange finds adjacent available slots', () => {
  const slots = [
    { courtId: 'court-1', start: '19:00', end: '20:00', available: true },
    { courtId: 'court-1', start: '20:00', end: '21:00', available: true },
    { courtId: 'court-2', start: '19:00', end: '20:00', available: true }
  ];

  assert.deepEqual(selectContinuousRange(slots, '19:00', '21:00'), [
    { courtId: 'court-1', start: '19:00', end: '20:00', available: true },
    { courtId: 'court-1', start: '20:00', end: '21:00', available: true }
  ]);
});
```

- [ ] **Step 2: Run parser tests and verify failure**

Run:

```bash
npm test
```

Expected: FAIL because `extensions/chrome/src/content/ydmap_content.js` does not exist.

- [ ] **Step 3: Implement protocol helpers**

Create `extensions/chrome/src/lib/protocol.js`:

```js
export const SCHEMA_VERSION = 1;

export function createMessage(type, payload, source = 'content-script') {
  return {
    schemaVersion: SCHEMA_VERSION,
    messageId: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
    type,
    sentAt: new Date().toISOString(),
    source,
    payload
  };
}

export function redactUrl(rawUrl) {
  try {
    const url = new URL(rawUrl);
    url.search = '';
    url.hash = '';
    return url.toString();
  } catch {
    return String(rawUrl).split('?')[0].split('#')[0];
  }
}
```

- [ ] **Step 4: Implement ydmap content helpers**

Create `extensions/chrome/src/content/ydmap_content.js`:

```js
(function installZacksBarContent(global) {
  const CAPTCHA_PATTERN = /拖动滑块|向右滑动|请完成.{0,6}验证|完成验证|滑动验证|按住左边滑块/;
  const SCHEMA_VERSION = 1;

  function redactUrl(rawUrl) {
    try {
      const url = new URL(rawUrl);
      url.search = '';
      url.hash = '';
      return url.toString();
    } catch {
      return String(rawUrl).split('?')[0].split('#')[0];
    }
  }

  function createMessage(type, payload, source = 'content-script') {
    return {
      schemaVersion: SCHEMA_VERSION,
      messageId: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
      type,
      sentAt: new Date().toISOString(),
      source,
      payload
    };
  }

  function detectCaptchaFromText(text) {
    return CAPTCHA_PATTERN.test(text || '');
  }

  function normalizeAvailability({ venue, pageUrl, dateLabel, courts, rows }) {
    return {
      venue: venue || 'unknown ydmap venue',
      pageUrl: redactUrl(pageUrl || global.location?.href || ''),
      dateLabel: dateLabel || 'latest',
      courts: Array.isArray(courts) ? courts.map((court) => ({
        id: String(court.id),
        name: String(court.name)
      })) : [],
      slots: Array.isArray(rows)
        ? rows.flat().filter(Boolean).map((slot) => ({
            courtId: String(slot.courtId),
            start: String(slot.start),
            end: String(slot.end),
            available: Boolean(slot.available)
          }))
        : []
    };
  }

  function selectContinuousRange(slots, start, end) {
    const byCourt = new Map();
    for (const slot of slots.filter((candidate) => candidate.available)) {
      const group = byCourt.get(slot.courtId) || [];
      group.push(slot);
      byCourt.set(slot.courtId, group);
    }

    for (const group of byCourt.values()) {
      const sorted = group.slice().sort((a, b) => a.start.localeCompare(b.start));
      const selected = [];
      let cursor = start;
      for (const slot of sorted) {
        if (slot.start === cursor) {
          selected.push(slot);
          cursor = slot.end;
        }
        if (cursor === end) return selected;
      }
    }

    return [];
  }

  function buildAvailabilityMessage(snapshot) {
    return createMessage('availability.updated', normalizeAvailability(snapshot), 'content-script');
  }

  function buildCaptchaMessage(pageUrl, textEvidence) {
    return createMessage('captcha.detected', {
      pageUrl: redactUrl(pageUrl),
      reason: 'captcha-text-match',
      textEvidence: String(textEvidence || '').slice(0, 80)
    }, 'content-script');
  }

  function inspectCurrentPage() {
    const bodyText = global.document?.body?.innerText || '';
    if (detectCaptchaFromText(bodyText)) {
      global.chrome.runtime.sendMessage(buildCaptchaMessage(global.location.href, bodyText));
    }
  }

  global.ZacksBarContent = {
    detectCaptchaFromText,
    normalizeAvailability,
    selectContinuousRange,
    buildAvailabilityMessage,
    buildCaptchaMessage,
    inspectCurrentPage
  };

  if (global.chrome?.runtime && global.document) {
    global.setInterval(inspectCurrentPage, 1500);
    inspectCurrentPage();
  }
})(globalThis);
```

- [ ] **Step 5: Add MV3 manifest**

Create `extensions/chrome/manifest.json`:

```json
{
  "manifest_version": 3,
  "name": "ZacksBar Companion",
  "version": "0.1.0",
  "description": "Connects ydmap tennis court pages to ZacksBar.",
  "permissions": ["nativeMessaging", "tabs", "storage"],
  "host_permissions": ["https://*.ydmap.cn/booking/*"],
  "background": {
    "service_worker": "src/background/service_worker.js",
    "type": "module"
  },
  "content_scripts": [
    {
      "matches": ["https://*.ydmap.cn/booking/*"],
      "js": ["src/content/ydmap_content.js"],
      "run_at": "document_idle"
    }
  ]
}
```

- [ ] **Step 6: Add service worker Native Messaging bridge**

Create `extensions/chrome/src/background/service_worker.js`:

```js
import { createMessage } from '../lib/protocol.js';

const HOST_NAME = 'com.zacksbar.native';
let nativePort = null;

function connectNativeHost() {
  if (nativePort) return nativePort;
  nativePort = chrome.runtime.connectNative(HOST_NAME);
  nativePort.onDisconnect.addListener(() => {
    nativePort = null;
  });
  nativePort.onMessage.addListener((message) => {
    if (message.type === 'tab.open' && message.payload?.url) {
      chrome.tabs.create({ url: message.payload.url });
    }
  });
  nativePort.postMessage(createMessage('health.ping', {
    component: 'zacksbar-companion',
    version: chrome.runtime.getManifest().version
  }, 'service-worker'));
  return nativePort;
}

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  const port = connectNativeHost();
  port.postMessage({
    ...message,
    payload: {
      ...(message.payload || {}),
      tabId: sender.tab?.id || null
    }
  });
  sendResponse({ ok: true });
  return true;
});

chrome.runtime.onInstalled.addListener(() => {
  connectNativeHost();
});
```

- [ ] **Step 7: Run extension tests**

Run:

```bash
npm test
```

Expected:

```text
Protocol fixtures valid
```

Node's test runner also reports three passing parser tests.

- [ ] **Step 8: Commit extension skeleton**

Run:

```bash
git add extensions/chrome package.json scripts/validate-protocol.mjs packages/protocol
git commit -m "feat: add chrome companion skeleton"
```

## Task 3: Swift Core And Native Host Framing

**Files:**
- Create: `apps/macos/Package.swift`
- Create: `apps/macos/Sources/ZacksBarCore/NativeMessage.swift`
- Create: `apps/macos/Sources/ZacksBarCore/AppSupportStore.swift`
- Create: `apps/macos/Sources/ZacksBarNativeHost/main.swift`
- Create: `apps/macos/Tests/ZacksBarCoreTests/NativeMessageTests.swift`

- [ ] **Step 1: Create failing Swift protocol test**

Create `apps/macos/Tests/ZacksBarCoreTests/NativeMessageTests.swift`:

```swift
import XCTest
@testable import ZacksBarCore

final class NativeMessageTests: XCTestCase {
    func testDecodesAvailabilityMessage() throws {
        let json = """
        {
          "schemaVersion": 1,
          "messageId": "test-1",
          "type": "availability.updated",
          "sentAt": "2026-06-25T12:00:00Z",
          "source": "content-script",
          "payload": {"venue":"bawtt tennis"}
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder.zacksBar.decode(NativeMessage.self, from: json)
        XCTAssertEqual(message.schemaVersion, 1)
        XCTAssertEqual(message.type, "availability.updated")
        XCTAssertEqual(message.payload["venue"]?.stringValue, "bawtt tennis")
    }
}
```

- [ ] **Step 2: Run Swift tests and verify failure**

Run:

```bash
cd apps/macos
swift test
```

Expected: FAIL because `Package.swift` and `ZacksBarCore` do not exist.

- [ ] **Step 3: Create Swift package**

Create `apps/macos/Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZacksBar",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "ZacksBarCore", targets: ["ZacksBarCore"]),
        .executable(name: "zacksbar-native-host", targets: ["ZacksBarNativeHost"]),
        .executable(name: "ZacksBarApp", targets: ["ZacksBarApp"])
    ],
    targets: [
        .target(name: "ZacksBarCore"),
        .executableTarget(name: "ZacksBarNativeHost", dependencies: ["ZacksBarCore"]),
        .executableTarget(name: "ZacksBarApp", dependencies: ["ZacksBarCore"]),
        .testTarget(name: "ZacksBarCoreTests", dependencies: ["ZacksBarCore"]),
        .testTarget(name: "ZacksBarNativeHostTests", dependencies: ["ZacksBarNativeHost", "ZacksBarCore"])
    ]
)
```

- [ ] **Step 4: Implement NativeMessage model**

Create `apps/macos/Sources/ZacksBarCore/NativeMessage.swift`:

```swift
import Foundation

public struct NativeMessage: Codable, Equatable {
    public var schemaVersion: Int
    public var messageId: String
    public var type: String
    public var sentAt: Date
    public var source: String
    public var payload: [String: JSONValue]

    public init(schemaVersion: Int, messageId: String, type: String, sentAt: Date, source: String, payload: [String: JSONValue]) {
        self.schemaVersion = schemaVersion
        self.messageId = messageId
        self.type = type
        self.sentAt = sentAt
        self.source = source
        self.payload = payload
    }
}

public enum JSONValue: Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            self = .array(try container.decode([JSONValue].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

public extension JSONDecoder {
    static var zacksBar: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

public extension JSONEncoder {
    static var zacksBar: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
```

- [ ] **Step 5: Add Application Support event store**

Create `apps/macos/Sources/ZacksBarCore/AppSupportStore.swift`:

```swift
import Foundation

public final class AppSupportStore {
    public let directory: URL
    public let eventsFile: URL
    public let commandsFile: URL

    public init(fileManager: FileManager = .default) throws {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        directory = base.appendingPathComponent("ZacksBar", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        eventsFile = directory.appendingPathComponent("native-events.jsonl")
        commandsFile = directory.appendingPathComponent("native-commands.jsonl")
    }

    public init(directory: URL, fileManager: FileManager = .default) throws {
        self.directory = directory
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        eventsFile = directory.appendingPathComponent("native-events.jsonl")
        commandsFile = directory.appendingPathComponent("native-commands.jsonl")
    }

    public func appendEvent(_ message: NativeMessage) throws {
        let data = try JSONEncoder.zacksBar.encode(message)
        try appendLine(data, to: eventsFile)
    }

    private func appendLine(_ data: Data, to file: URL) throws {
        if !FileManager.default.fileExists(atPath: file.path) {
            FileManager.default.createFile(atPath: file.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: file)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
        try handle.write(contentsOf: Data([0x0A]))
    }
}
```

- [ ] **Step 6: Implement Native Messaging host framing**

Create `apps/macos/Sources/ZacksBarNativeHost/main.swift`:

```swift
import Foundation
import ZacksBarCore

func readExactBytes(_ count: Int, from handle: FileHandle) throws -> Data? {
    var data = Data()
    while data.count < count {
        let chunk = try handle.read(upToCount: count - data.count) ?? Data()
        if chunk.isEmpty { return data.isEmpty ? nil : data }
        data.append(chunk)
    }
    return data
}

func readNativeMessage(from handle: FileHandle) throws -> NativeMessage? {
    guard let lengthData = try readExactBytes(4, from: handle) else { return nil }
    let bytes = [UInt8](lengthData)
    let length = UInt32(bytes[0])
        | (UInt32(bytes[1]) << 8)
        | (UInt32(bytes[2]) << 16)
        | (UInt32(bytes[3]) << 24)
    guard let body = try readExactBytes(Int(length), from: handle) else { return nil }
    return try JSONDecoder.zacksBar.decode(NativeMessage.self, from: body)
}

func writeNativeMessage(_ message: NativeMessage, to handle: FileHandle) throws {
    let body = try JSONEncoder.zacksBar.encode(message)
    var length = UInt32(body.count).littleEndian
    let lengthData = Data(bytes: &length, count: 4)
    try handle.write(contentsOf: lengthData)
    try handle.write(contentsOf: body)
}

let input = FileHandle.standardInput
let output = FileHandle.standardOutput
let store = try AppSupportStore()

while let message = try readNativeMessage(from: input) {
    try store.appendEvent(message)
    let ack = NativeMessage(
        schemaVersion: 1,
        messageId: "ack-\(message.messageId)",
        type: "health.ping",
        sentAt: Date(),
        source: "native-host",
        payload: ["receivedType": .string(message.type)]
    )
    try writeNativeMessage(ack, to: output)
}
```

- [ ] **Step 7: Run Swift tests**

Run:

```bash
cd apps/macos
swift test
```

Expected: PASS for `NativeMessageTests`.

- [ ] **Step 8: Commit Swift core and native host**

Run:

```bash
git add apps/macos
git commit -m "feat: add swift core and native host"
```

## Task 4: Rule Matching And Privacy Redaction

**Files:**
- Create: `apps/macos/Sources/ZacksBarCore/WatchRule.swift`
- Create: `apps/macos/Sources/ZacksBarCore/PrivacyRedactor.swift`
- Create: `apps/macos/Tests/ZacksBarCoreTests/WatchRuleTests.swift`
- Create: `apps/macos/Tests/ZacksBarCoreTests/PrivacyRedactorTests.swift`

- [ ] **Step 1: Add failing rule and redaction tests**

Create `apps/macos/Tests/ZacksBarCoreTests/WatchRuleTests.swift`:

```swift
import XCTest
@testable import ZacksBarCore

final class WatchRuleTests: XCTestCase {
    func testMatchesContinuousAvailableRangeOnPreferredCourt() {
        let rule = WatchRule(id: "rule-1", dateMode: .latestBookable, start: "19:00", end: "21:00", courtKeywords: ["1号"])
        let result = rule.match(slots: [
            AvailabilitySlot(courtId: "court-1", courtName: "1号场", start: "19:00", end: "20:00", available: true),
            AvailabilitySlot(courtId: "court-1", courtName: "1号场", start: "20:00", end: "21:00", available: true),
            AvailabilitySlot(courtId: "court-2", courtName: "2号场", start: "19:00", end: "20:00", available: true)
        ])

        XCTAssertEqual(result?.courtName, "1号场")
        XCTAssertEqual(result?.slots.count, 2)
    }
}
```

Create `apps/macos/Tests/ZacksBarCoreTests/PrivacyRedactorTests.swift`:

```swift
import XCTest
@testable import ZacksBarCore

final class PrivacyRedactorTests: XCTestCase {
    func testRedactsQueryPhoneAndOrderNumber() {
        let input = "https://example.com/path?token=abc 13800138000 order 202606250001"
        let output = PrivacyRedactor.redact(input)
        XCTAssertFalse(output.contains("token=abc"))
        XCTAssertFalse(output.contains("13800138000"))
        XCTAssertFalse(output.contains("202606250001"))
    }
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
cd apps/macos
swift test
```

Expected: FAIL because `WatchRule`, `AvailabilitySlot`, and `PrivacyRedactor` do not exist.

- [ ] **Step 3: Implement watch rule matching**

Create `apps/macos/Sources/ZacksBarCore/WatchRule.swift`:

```swift
import Foundation

public enum DateMode: String, Codable, Equatable {
    case tomorrow
    case latestBookable
    case weekend
    case specific
}

public struct AvailabilitySlot: Codable, Equatable {
    public var courtId: String
    public var courtName: String
    public var start: String
    public var end: String
    public var available: Bool

    public init(courtId: String, courtName: String, start: String, end: String, available: Bool) {
        self.courtId = courtId
        self.courtName = courtName
        self.start = start
        self.end = end
        self.available = available
    }
}

public struct RuleMatch: Equatable {
    public var ruleId: String
    public var courtName: String
    public var slots: [AvailabilitySlot]
}

public struct WatchRule: Codable, Equatable, Identifiable {
    public var id: String
    public var dateMode: DateMode
    public var start: String
    public var end: String
    public var courtKeywords: [String]

    public init(id: String, dateMode: DateMode, start: String, end: String, courtKeywords: [String]) {
        self.id = id
        self.dateMode = dateMode
        self.start = start
        self.end = end
        self.courtKeywords = courtKeywords
    }

    public func match(slots: [AvailabilitySlot]) -> RuleMatch? {
        let availableSlots = slots.filter { slot in
            slot.available && (courtKeywords.isEmpty || courtKeywords.contains { slot.courtName.contains($0) })
        }
        let groups = Dictionary(grouping: availableSlots, by: \.courtId)

        for group in groups.values {
            let sorted = group.sorted { $0.start < $1.start }
            var selected: [AvailabilitySlot] = []
            var cursor = start
            for slot in sorted {
                if slot.start == cursor {
                    selected.append(slot)
                    cursor = slot.end
                }
                if cursor == end, let courtName = selected.first?.courtName {
                    return RuleMatch(ruleId: id, courtName: courtName, slots: selected)
                }
            }
        }

        return nil
    }
}
```

- [ ] **Step 4: Implement privacy redactor**

Create `apps/macos/Sources/ZacksBarCore/PrivacyRedactor.swift`:

```swift
import Foundation

public enum PrivacyRedactor {
    public static func redact(_ input: String) -> String {
        var output = input
        output = output.replacingOccurrences(of: #"https?://[^\s\?]+(?:\?[^\s]+)?"#, with: "[redacted-url]", options: .regularExpression)
        output = output.replacingOccurrences(of: #"\b1[3-9]\d{9}\b"#, with: "[redacted-phone]", options: .regularExpression)
        output = output.replacingOccurrences(of: #"\b\d{10,}\b"#, with: "[redacted-number]", options: .regularExpression)
        return output
    }
}
```

- [ ] **Step 5: Run tests**

Run:

```bash
cd apps/macos
swift test
```

Expected: PASS for native message, rule matching, and redaction tests.

- [ ] **Step 6: Commit rule and privacy core**

Run:

```bash
git add apps/macos/Sources/ZacksBarCore apps/macos/Tests/ZacksBarCoreTests
git commit -m "feat: add watch rules and privacy redaction"
```

## Task 5: macOS Menu Bar App Skeleton

**Files:**
- Create: `apps/macos/Sources/ZacksBarApp/main.swift`
- Create: `apps/macos/Sources/ZacksBarApp/AppModel.swift`
- Create: `apps/macos/Sources/ZacksBarApp/MenuController.swift`

- [ ] **Step 1: Create app model**

Create `apps/macos/Sources/ZacksBarApp/AppModel.swift`:

```swift
import Foundation
import ZacksBarCore

@MainActor
final class AppModel: ObservableObject {
    @Published var statusText: String = "Waiting for Chrome"
    @Published var latestAlert: String?
    @Published var rules: [WatchRule] = [
        WatchRule(id: "default-evening", dateMode: .latestBookable, start: "19:00", end: "21:00", courtKeywords: [])
    ]

    func handle(message: NativeMessage) {
        switch message.type {
        case "availability.updated":
            statusText = "Monitoring"
            latestAlert = "Availability synced"
        case "captcha.detected":
            statusText = "Captcha required"
            latestAlert = "Open captcha page"
        case "health.ping":
            statusText = "Connected"
        default:
            statusText = "Received \(message.type)"
        }
    }
}
```

- [ ] **Step 2: Create menu controller**

Create `apps/macos/Sources/ZacksBarApp/MenuController.swift`:

```swift
import AppKit

@MainActor
final class MenuController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let model: AppModel

    init(model: AppModel) {
        self.model = model
        statusItem.button?.title = "ZB"
        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "ZacksBar", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Status: \(model.statusText)", action: nil, keyEquivalent: ""))
        if let latestAlert = model.latestAlert {
            menu.addItem(NSMenuItem(title: "Alert: \(latestAlert)", action: nil, keyEquivalent: ""))
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Create watch rule from current page", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Pause monitoring for 30 minutes", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings and diagnostics...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
}
```

- [ ] **Step 3: Create AppKit entry point**

Create `apps/macos/Sources/ZacksBarApp/main.swift`:

```swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel!
    private var menuController: MenuController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        model = AppModel()
        menuController = MenuController(model: model)
        NSApp.setActivationPolicy(.accessory)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 4: Build app executable**

Run:

```bash
cd apps/macos
swift build
```

Expected: PASS and builds `ZacksBarApp` plus `zacksbar-native-host`.

- [ ] **Step 5: Commit menu bar skeleton**

Run:

```bash
git add apps/macos/Sources/ZacksBarApp apps/macos/Package.swift
git commit -m "feat: add menu bar app skeleton"
```

## Task 6: Native Host Manifest Installer And Setup Health

**Files:**
- Create: `apps/macos/Sources/ZacksBarCore/NativeHostManifest.swift`
- Create: `apps/macos/Tests/ZacksBarCoreTests/NativeHostManifestTests.swift`
- Create: `scripts/install-native-host.sh`
- Create: `docs/install.md`

- [ ] **Step 1: Add failing manifest test**

Create `apps/macos/Tests/ZacksBarCoreTests/NativeHostManifestTests.swift`:

```swift
import XCTest
@testable import ZacksBarCore

final class NativeHostManifestTests: XCTestCase {
    func testManifestUsesExpectedHostNameAndAbsolutePath() throws {
        let manifest = NativeHostManifest(
            path: "/Applications/ZacksBar.app/Contents/MacOS/zacksbar-native-host",
            allowedOrigins: ["chrome-extension://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/"]
        )
        let data = try JSONEncoder().encode(manifest)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("com.zacksbar.native"))
        XCTAssertTrue(json.contains("/Applications/ZacksBar.app/Contents/MacOS/zacksbar-native-host"))
        XCTAssertTrue(json.contains("chrome-extension://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/"))
    }
}
```

- [ ] **Step 2: Run manifest test and verify failure**

Run:

```bash
cd apps/macos
swift test
```

Expected: FAIL because `NativeHostManifest` does not exist.

- [ ] **Step 3: Implement manifest model**

Create `apps/macos/Sources/ZacksBarCore/NativeHostManifest.swift`:

```swift
import Foundation

public struct NativeHostManifest: Codable, Equatable {
    public let name: String
    public let description: String
    public let path: String
    public let type: String
    public let allowedOrigins: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case path
        case type
        case allowedOrigins = "allowed_origins"
    }

    public init(path: String, allowedOrigins: [String]) {
        self.name = "com.zacksbar.native"
        self.description = "ZacksBar Native Messaging Host"
        self.path = path
        self.type = "stdio"
        self.allowedOrigins = allowedOrigins
    }
}
```

- [ ] **Step 4: Create development install script**

Create `scripts/install-native-host.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

HOST_NAME="com.zacksbar.native"
TARGET_DIR="${HOME}/Library/Application Support/Google/Chrome/NativeMessagingHosts"
HOST_PATH="${1:-$(pwd)/apps/macos/.build/debug/zacksbar-native-host}"
EXTENSION_ID="${2:-}"
MANIFEST_PATH="${TARGET_DIR}/${HOST_NAME}.json"

if [[ -z "${EXTENSION_ID}" ]]; then
  echo "Usage: $0 /absolute/path/to/zacksbar-native-host chrome_extension_id" >&2
  exit 64
fi

mkdir -p "${TARGET_DIR}"
cat > "${MANIFEST_PATH}" <<JSON
{
  "name": "${HOST_NAME}",
  "description": "ZacksBar Native Messaging Host",
  "path": "${HOST_PATH}",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://${EXTENSION_ID}/"]
}
JSON

echo "Installed ${MANIFEST_PATH}"
```

Run:

```bash
chmod +x scripts/install-native-host.sh
```

- [ ] **Step 5: Document install flow**

Create `docs/install.md`:

```markdown
# Install ZacksBar Development Build

1. Build the macOS package:

   ```bash
   cd apps/macos
   swift build
   ```

2. Load `extensions/chrome` as an unpacked extension in `chrome://extensions`.

3. Copy the unpacked extension ID from Chrome.

4. Install the native host manifest:

   ```bash
   ./scripts/install-native-host.sh "$(pwd)/apps/macos/.build/debug/zacksbar-native-host" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
   ```

5. Open a supported ydmap booking page.

6. Run the app:

   ```bash
   cd apps/macos
   swift run ZacksBarApp
   ```
```

- [ ] **Step 6: Run tests**

Run:

```bash
cd apps/macos
swift test
```

Expected: PASS including manifest tests.

- [ ] **Step 7: Commit install and setup skeleton**

Run:

```bash
git add apps/macos/Sources/ZacksBarCore apps/macos/Tests/ZacksBarCoreTests scripts/install-native-host.sh docs/install.md
git commit -m "feat: add native host install support"
```

## Task 7: Diagnostics, Privacy Docs, And CI

**Files:**
- Create: `docs/architecture.md`
- Create: `docs/privacy.md`
- Create: `docs/troubleshooting.md`
- Create: `docs/contributing.md`
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create architecture document**

Create `docs/architecture.md`:

```markdown
# Architecture

ZacksBar connects a supported ydmap tennis booking page to a macOS menu bar app through Chrome's official extension and Native Messaging APIs.

Flow:

```text
ydmap booking page
  -> Chrome MV3 content script
  -> Chrome extension service worker
  -> Chrome Native Messaging
  -> ZacksBar Native Host
  -> ZacksBar macOS app state store
  -> macOS menu bar UI and notifications
```

The extension reads page state and captcha indicators. The native host writes sanitized events to the local Application Support store. The macOS app displays the latest health, alerts, and watch rules.

ZacksBar does not submit reservations or solve captcha.
```

- [ ] **Step 2: Create privacy document**

Create `docs/privacy.md`:

```markdown
# Privacy

ZacksBar stores watch rules, recent health events, and diagnostic logs locally on the user's Mac.

ZacksBar does not store account passwords, cookies, payment data, or captcha answers.

Diagnostic exports redact URL query strings, phone numbers, long order-like numbers, and token-like values before display or export.

Browser-side logic is limited to `https://*.ydmap.cn/booking/*`.
```

- [ ] **Step 3: Create troubleshooting document**

Create `docs/troubleshooting.md`:

```markdown
# Troubleshooting

## Extension cannot connect to native host

Check that the native host manifest exists:

```bash
cat "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.zacksbar.native.json"
```

Verify the `path` points to an executable file and `allowed_origins` contains the Chrome extension ID.

## No page data appears

Open a supported ydmap booking page that matches:

```text
https://*.ydmap.cn/booking/*
```

Reload the page after installing the extension.

## Captcha alert does not appear

Open diagnostics and confirm the content script is connected. The detector currently looks for common slider captcha text such as `请完成滑动验证`.
```

- [ ] **Step 4: Create contributing document**

Create `docs/contributing.md`:

```markdown
# Contributing

Run all checks before submitting changes:

```bash
npm test
cd apps/macos
swift test
swift build
```

Do not commit credentials, cookies, real account data, raw diagnostic exports, or private server notes.

Keep browser automation within the semi-automated boundary: opening pages, focusing tabs, and preselecting fields are allowed; final submission and captcha solving are not allowed.
```

- [ ] **Step 5: Create CI workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  extension-and-protocol:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm test

  swift:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: swift test
        working-directory: apps/macos
      - run: swift build
        working-directory: apps/macos
```

- [ ] **Step 6: Run documentation and CI-equivalent checks locally**

Run:

```bash
npm test
cd apps/macos
swift test
swift build
```

Expected: all commands exit 0.

- [ ] **Step 7: Commit docs and CI**

Run:

```bash
git add docs .github/workflows/ci.yml
git commit -m "docs: add diagnostics docs and ci"
```

## Task 8: End-To-End Development Smoke Test

**Files:**
- Modify: `README.md`
- Create: `docs/development-smoke-test.md`

- [ ] **Step 1: Create smoke test checklist**

Create `docs/development-smoke-test.md`:

```markdown
# Development Smoke Test

This checklist verifies the ZacksBar skeleton end to end.

1. Build Swift targets:

   ```bash
   cd apps/macos
   swift build
   ```

2. Install the native host manifest using the unpacked extension ID:

   ```bash
   ./scripts/install-native-host.sh "$(pwd)/apps/macos/.build/debug/zacksbar-native-host" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
   ```

3. Load `extensions/chrome` in Chrome as an unpacked extension.

4. Run the menu bar app:

   ```bash
   cd apps/macos
   swift run ZacksBarApp
   ```

5. Open a supported ydmap booking page.

6. Confirm `~/Library/Application Support/ZacksBar/native-events.jsonl` receives `health.ping` or page messages.

7. Confirm the menu bar shows a ZB item and can quit cleanly.
```

- [ ] **Step 2: Update README with development commands**

Modify `README.md` so it contains this section:

```markdown
## Development

Run protocol and extension tests:

```bash
npm test
```

Run Swift tests and build:

```bash
cd apps/macos
swift test
swift build
```

See [docs/development-smoke-test.md](docs/development-smoke-test.md) for the end-to-end local checklist.
```

- [ ] **Step 3: Run full verification**

Run:

```bash
npm test
cd apps/macos
swift test
swift build
git status --short
```

Expected:

- `npm test` exits 0.
- `swift test` exits 0.
- `swift build` exits 0.
- `git status --short` shows only expected documentation changes before commit.

- [ ] **Step 4: Commit smoke test docs**

Run:

```bash
git add README.md docs/development-smoke-test.md
git commit -m "docs: add development smoke test"
```

## Final Verification

- [ ] **Step 1: Run all local checks**

Run:

```bash
npm test
cd apps/macos
swift test
swift build
git status --short
```

Expected:

- Node tests pass.
- Swift tests pass.
- Swift build succeeds.
- `git status --short` is clean except for intentional untracked local files such as `wxsports/`.

- [ ] **Step 2: Confirm tracked files exclude sensitive local inputs**

Run:

```bash
git ls-files | rg 'prory|wxsports|native-events|native-commands|\\.superpowers' || true
```

Expected: no output.

- [ ] **Step 3: Push to GitHub**

Run:

```bash
git push origin main
```

Expected: push succeeds and GitHub Actions starts on `main`.
