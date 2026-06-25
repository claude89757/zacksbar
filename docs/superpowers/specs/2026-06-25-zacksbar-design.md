# ZacksBar Design Spec

Date: 2026-06-25
Status: Approved for implementation planning

## Product Summary

ZacksBar is a macOS menu bar app for monitoring ydmap tennis court availability from Chrome and notifying the user when manual attention is needed. It replaces the current Tampermonkey-based workflow with a product-grade architecture built from a native macOS app, a Chrome MV3 companion extension, and Chrome Native Messaging.

The v1 product scope is ydmap tennis court monitoring only. The app provides low-friction watch rule creation, captcha alerts, availability alerts, diagnostic tooling, and a durable project structure for future upgrades.

## Locked Architecture

The final architecture is:

```text
ydmap booking page
  -> Chrome MV3 content script
  -> Chrome extension service worker
  -> Chrome Native Messaging
  -> ZacksBar Native Host
  -> Swift macOS menu bar app
```

### Component Responsibilities

The Chrome content script runs on `https://*.ydmap.cn/booking/*`. It reads page state, Vue component data, court grids, available slots, selected date, selected courts, and captcha state. It may perform semi-automated page actions such as opening a page, switching date, and preselecting a target court/time. It must not submit an order or bypass captcha.

The Chrome extension service worker is the browser-side coordinator. It receives messages from content scripts, manages tab actions, reports extension health and version, and forwards messages to the native host through Chrome Native Messaging.

The Native Messaging host follows Chrome's JSON-over-stdio protocol. It is the stable bridge between the extension and the macOS app. The host name is `com.zacksbar.native`.

The Swift macOS app owns the menu bar UI, watch rules, notifications, logs, diagnostics, local persistence, update status, and Native Messaging manifest installation checks.

### Explicit Non-Goals

ZacksBar v1 does not use Tampermonkey as a production component. The existing `wxsports/tennis_grabber.user.js` is reference material only for migrating ydmap page parsing and captcha detection logic.

ZacksBar v1 does not use a localhost bridge between browser and app.

ZacksBar v1 does not automatically submit reservations, bypass captcha, store credentials, read payment information, or transmit cookies.

## Product Naming

Product name: `ZacksBar`

GitHub repository: `zacksbar`

macOS app: `ZacksBar.app`

Chrome extension: `ZacksBar Companion`

Native Messaging host: `com.zacksbar.native`

## User Experience

The product uses a menu bar first experience with a dedicated settings and diagnostics window.

### Menu Bar States

The status item has four states:

- Normal monitoring: shows a simple icon and the latest sync time.
- Availability found: highlights the icon and emits an availability notification.
- Captcha required: shows the highest-priority visual state and emits a notification that can open the relevant Chrome tab.
- Connection issue: shows that the extension, native host, Chrome tab, or ydmap page is not connected.

### Menu Structure

The menu bar dropdown is optimized for high-frequency actions:

```text
ZacksBar
Status: Monitoring · synced 2 minutes ago

Alerts
- Captcha required · Open page
- 19:00-21:00 available · Prefill

Watching
- Tomorrow 19:00-21:00 · courts 1/5/7 preferred
- Weekend 09:00-11:00 · any court

Actions
- Open booking page
- Create watch rule from current page
- Pause monitoring for 30 minutes
- Settings and diagnostics...
```

### Dedicated Window

The app window contains:

- Overview: connection status, current ydmap page, latest polling result, and latest alerts.
- Watch Rules: rule list, auto-detected suggestions, and rule editing.
- Setup: Chrome extension status, Native Messaging host status, notification permission, and launch-at-login status.
- Diagnostics: app logs, extension health, message chain status, page snapshots, and version data.
- Updates: macOS app version, extension version, and compatibility state.

## Watch Rules

v1 supports multiple watch rules. A rule contains:

- Venue source, automatically detected from the current ydmap page.
- Date mode: tomorrow, latest bookable date, weekend, or specific date.
- One or more time ranges, such as `19:00-21:00`.
- Court preference: any court, selected court names, or keyword-based preference.
- Notification methods: system notification, sound, and menu bar highlight.
- Assist behavior: notify only, open page, or open and prefill.

### Low-Input Rule Creation

The default creation path avoids manual data entry:

1. The user opens a ydmap booking page in Chrome.
2. The extension reports venue, available dates, time grid, court columns, and current page selection.
3. The user chooses `Create watch rule from current page` from ZacksBar.
4. ZacksBar creates a rule draft:
   - Date defaults to latest bookable date.
   - Time defaults to the selected range on the page, or `19:00-21:00` when nothing is selected.
   - Court preference defaults to any court.
   - Existing page-level court choices are imported when available.
5. The user confirms or lightly edits the draft.

## Alerts

Captcha alerts have highest priority. The alert includes an `Open page` action that focuses the Chrome tab containing the captcha challenge.

Availability alerts trigger when a rule matches an available continuous time range. Each rule has a cooldown/de-duplication window to prevent repeated alerts from every poll cycle.

Connection alerts are low priority and only fire after sustained disconnection.

Users can pause all monitoring, pause a specific rule, or silence a rule for the rest of the day.

## Semi-Automated Assistance Boundary

ZacksBar can open the correct booking page, focus the existing tab, switch dates, and preselect the target court/time range.

ZacksBar cannot click final order submission, cannot solve captcha, cannot bypass page protections, and cannot perform payment-related actions.

## Installation And Upgrade

### Installation Flow

1. User installs `ZacksBar.app`.
2. First launch opens Setup Health.
3. The app checks notification permission, launch-at-login preference, Native Messaging manifest installation, and Chrome extension connectivity.
4. The app installs or refreshes the user-level Native Messaging manifest:
   `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.zacksbar.native.json`
5. The user installs `ZacksBar Companion`.
6. The extension connects to the native host and reports health/version.
7. Setup shows connected status. Monitoring begins after the user opens a supported ydmap page.

### Upgrade Flow

The macOS app is published through GitHub Releases and should later support Sparkle-based automatic updates.

The Chrome extension is published through the Chrome Web Store. During development, it may be installed as an unpacked extension.

App upgrades refresh the Native Messaging manifest so its `path` points to the current host binary inside the app bundle.

Extension upgrades are handled by Chrome. The app detects extension version and compatibility and prompts when the browser-side component is too old.

Native Messaging messages include `schemaVersion` and `capabilities` to allow short-term app/extension version skew.

ZacksBar does not modify local Tampermonkey scripts. Migration documentation explains how to disable legacy userscripts.

## Diagnostics

Setup Health checks:

- macOS app running
- notification permission
- launch-at-login preference
- Native Messaging manifest presence and path
- native host executable presence and permission
- Chrome extension installed and connected
- supported ydmap tab detected

Message Inspector stores the latest 200 messages with type, timestamp, latency, source, and outcome. Payloads are redacted.

Page Snapshot exports a sanitized read-only representation of detected ydmap page structure, court grid metadata, and captcha indicators. It must not include cookies, account data, payment data, or raw personal information.

Export Diagnostics creates a zip containing app logs, extension log summary, version data, manifest path, health check results, and sanitized page structure.

Privacy Guard redacts URL query strings, phone numbers, names, order numbers, tokens, and similar sensitive fields before display or export.

## Message Protocol

All Native Messaging messages are JSON. Every message includes:

- `schemaVersion`
- `messageId`
- `type`
- `sentAt`
- `source`
- `payload`

Core message types:

- `page.snapshot`
- `availability.updated`
- `captcha.detected`
- `rule.createDraft`
- `rule.match`
- `tab.open`
- `tab.prefill`
- `health.ping`
- `diagnostics.export`

## Testing Strategy

Swift unit tests cover rule matching, alert de-duplication, protocol parsing, manifest generation, privacy redaction, and setup health checks.

Extension unit tests cover ydmap grid parsing, captcha detection, message serialization, tab command handling, and schema compatibility.

Integration tests use a mock native host and sanitized ydmap DOM/state fixtures.

Manual QA covers real Chrome installation, extension connection, ydmap monitoring, captcha alerting, page focus, and prefill flow.

Safety QA verifies that the product cannot submit reservations, bypass captcha, save credentials, or leak sensitive data in diagnostics.

## Repository Structure

```text
zacksbar/
  apps/macos/              # Swift menu bar app
  extensions/chrome/       # Chrome MV3 companion extension
  native-host/             # Native Messaging host shim and installer resources
  packages/protocol/       # Shared JSON schemas and fixtures
  fixtures/ydmap/          # Sanitized DOM/state fixtures
  docs/
    architecture.md
    install.md
    troubleshooting.md
    privacy.md
    contributing.md
  scripts/
  .github/workflows/
```

## Open Source Notes

The repository must not include local credentials, proxy notes, private server details, or personal browser data. `wxsports/prory.md` is explicitly excluded from source control.

Suggested license: MIT.

Suggested CI:

- Swift build/test
- Chrome extension lint/package
- protocol schema validation
- release artifact checks

Suggested release artifacts:

- `.dmg` for `ZacksBar.app`
- Chrome extension zip for development/testing
- checksums
- release notes

## Next Step

After this spec is reviewed, create a detailed implementation plan for the complete product skeleton and then scaffold the open-source repository.
