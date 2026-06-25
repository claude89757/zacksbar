# ZacksBar Architecture

ZacksBar is built as a native macOS menu bar app with a small Chrome companion extension. The browser stays responsible for reading ydmap pages that already run in the user's logged-in Chrome session. The macOS app stays responsible for local state, notifications, rule matching, setup health, and future native UI.

```mermaid
flowchart LR
    page["ydmap booking page"] --> content["Chrome content script"]
    content --> worker["Extension service worker"]
    worker --> native["Chrome Native Messaging"]
    native --> host["ZacksBar native host"]
    host --> core["ZacksBar core"]
    core --> app["macOS menu bar app"]
```

## Components

`extensions/chrome`
: Chrome MV3 extension. It injects a content script on supported ydmap booking pages, detects captcha text, reads ydmap Vue schedule state from `rows`, `platformInColumns`, and `isAvailableStatic(cell)`, normalizes court availability snapshots, dedupes unchanged snapshots, and forwards protocol messages to the native host.

`apps/macos/Sources/ZacksBarNativeHost`
: Command-line native host entrypoint used by Chrome Native Messaging. It reads length-prefixed JSON messages from stdin and writes length-prefixed JSON responses to stdout.

`apps/macos/Sources/ZacksBarCore`
: Shared Swift package code for message framing, app support storage paths, latest state persistence, menu state summarization, watch-rule matching, notification decisions, privacy redaction, and native host manifest generation.

`apps/macos/Sources/ZacksBarApp`
: Swift menu bar app skeleton. It owns the status item, menu model, latest-state refresh action, setup/diagnostic entry points, alert settings UI, macOS notification delivery, and future native settings UI.

`packages/protocol`
: JSON schemas and fixtures for messages exchanged between Chrome and the native side.

## Message Flow

1. The content script inspects supported booking pages on a polling interval.
2. Captcha-like page text emits `captcha.detected`.
3. Page parser health emits deduped `parser.diagnostics`.
4. Ready ydmap Vue schedule state emits deduped `availability.updated`.
5. The service worker adds tab context and forwards the message through `chrome.runtime.connectNative`.
6. The native host decodes the Chrome Native Messaging frame, appends `native-events.jsonl`, and updates `latest-state.json`.
7. The menu bar app reads `latest-state.json` at launch and on Refresh to update status and evaluate notification rules.

## Notifications

The macOS app uses `UserNotifications` for user-facing alerts. Core computes pending notifications from `LatestAppState`, current watch rules, and session-level delivered notification IDs. The app delivers each pending notification once per app session.

- `captcha.detected` triggers `ZacksBar needs captcha`.
- A matching continuous watch-rule range triggers `Court available`.
- Parser diagnostics stay diagnostic-only.

Notification clicks are handled inside the macOS app. When a notification contains an action URL, ZacksBar opens it with Chrome by bundle identifier (`com.google.Chrome`), falling back to the user's default browser if Chrome is unavailable.

## Watch Rules

The app currently supports one primary availability watch rule. Users edit it from `Alert Settings...` in the menu bar app. The user-facing rule includes start time, end time, and optional court keywords. Empty court keywords match any court.

Rules are persisted in `watch-rules.json` under Application Support. If the file is missing, ZacksBar uses the default 19:00-21:00 rule. The stored Codable model still contains a compatibility `dateMode` field, but the settings UI does not expose it.

## Local State

The native host writes local app state under:

```text
~/Library/Application Support/ZacksBar/
```

Important files:

- `native-events.jsonl`: append-only event log for diagnostics.
- `latest-state.json`: compact latest availability/captcha/health snapshot for the menu app.
- `watch-rules.json`: local availability alert settings.

These files are local runtime data and must not be committed.

## Protocol Rules

- Every message uses `schemaVersion`, `messageId`, `type`, `sentAt`, `source`, and `payload`.
- Browser messages must avoid credentials, cookies, and raw query strings.
- URLs are redacted before leaving the content script and redacted again on the native side as defense in depth.
- Schema fixtures are tested with `npm test`.

## Upgrade Model

ZacksBar should support two upgrade tracks:

- App upgrade: future signed macOS releases can update the native app, native host, docs, and bundled extension assets.
- Extension/script upgrade: the production path is the Chrome companion extension. Tampermonkey scripts are treated as migration references, not as the long-term runtime. Future import helpers may read an existing userscript only after explicit user approval.

The native host manifest is installed locally because Chrome requires it. It points Chrome to the native host executable and whitelists the local extension ID.
