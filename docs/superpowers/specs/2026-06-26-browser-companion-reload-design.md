# Browser Companion Reload Design

## Goal

Make local browser-side upgrades visible and easier for users during development builds. ZacksBar should detect the loaded Chrome companion version, show whether the browser side is connected, and let the macOS app request a browser extension reload.

## Scope

This iteration targets the existing Chrome MV3 companion extension. It does not modify Tampermonkey storage, bypass Chrome extension permissions, or implement signed production auto-update. Tampermonkey remains a migration reference only.

## User Experience

The Setup Assistant shows a `Browser Companion` row. When the latest browser health ping contains the expected companion version, the row is ready. When the browser has not connected, it remains missing. When the browser reports another version, the row tells the user to reload the companion.

The Setup Assistant also exposes `Reload Browser Extension`. Clicking it queues an `extension.reload` command locally. The next browser-to-native message drains that queue and sends the command back to the service worker. The service worker reloads the unpacked extension through `chrome.runtime.reload()`.

## Architecture

`ZacksBarCore` owns a small command queue stored in `native-commands.jsonl`. Commands use the existing `NativeMessage` envelope with `type = "extension.reload"`. `AppModel` queues the reload command. `ZacksBarNativeHost` appends inbound events, drains pending commands, writes command frames to Chrome, and then writes the normal health ack.

`extensions/chrome/src/background/service_worker.js` handles host messages. It already handles `tab.open`; this iteration adds `extension.reload`. The service worker health ping continues to include `component` and `version`, and the setup checklist uses `latestHealth.payload.version` for the companion status.

## Error Handling

If no browser connection exists, the queued command remains in `native-commands.jsonl` until the next inbound native message. If the queue file is missing or empty, the native host sends only its normal ack. If the command file contains malformed JSON lines, the queue reader skips those lines rather than blocking all later valid commands.

## Testing

Core tests cover queue append/drain behavior and malformed line handling. Setup checklist tests cover missing, matching, and mismatched companion versions. JavaScript tests cover service worker handling for `extension.reload` without needing a real Chrome runtime. Full verification remains `npm test`, `swift test`, `swift build`, `git status`, and the tracked sensitive-file check.
