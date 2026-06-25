# Development Smoke Test

Use this checklist after changing the Chrome extension, parser diagnostics, native host, protocol schemas, latest-state persistence, notifications, setup assistant, diagnostics, or menu bar app skeleton.

## 1. Run Automated Checks

```bash
npm test
cd apps/macos
swift test
swift build
```

Expected result:

- JavaScript parser, parser diagnostics, and polling tests pass.
- Protocol fixtures validate against JSON schemas.
- Swift tests pass, including latest-state persistence, setup checklist, diagnostics, menu-state summarization, notification decisions, and app notification routing.
- `ZacksBarApp` and `zacksbar-native-host` build.

## 2. Load The Chrome Extension

1. Open `chrome://extensions`.
2. Enable Developer mode.
3. Choose Load unpacked.
4. Select `extensions/chrome`.
5. Copy the extension ID.

## 3. Start The App

```bash
cd apps/macos
swift run ZacksBarApp
```

Expected result:

- A `Z` menu bar item appears.
- macOS may ask for notification permission; allow it for local alert testing.
- The menu shows app status, `Setup Assistant...`, Refresh, and `Settings and diagnostics...`.

## 4. Run Setup Assistant

1. Open `Setup Assistant...`.
2. Paste the unpacked Chrome extension ID.
3. Click `Install Native Host`.
4. Click Refresh.
5. Confirm:
   - Chrome Extension ID is the pasted value.
   - Native Host Executable is `ready`.
   - Native Host Manifest is `installed`.

Script fallback:

```bash
./scripts/install-native-host.sh "$(pwd)/apps/macos/.build/debug/zacksbar-native-host" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
```

## 5. Exercise Browser Messaging

1. Open a supported ydmap booking page in Chrome.
2. Reload the page after the extension is installed.
3. Wait for the content script polling interval to inspect the page.
4. Confirm local latest state exists:

   ```bash
   cat "$HOME/Library/Application Support/ZacksBar/latest-state.json"
   ```

5. Click Refresh in the ZacksBar menu.
6. Open `Setup Assistant...` and confirm `Parser Diagnostics` changes from `waiting` to a slot count after the page is inspected.
7. If availability was parsed, confirm the menu shows `Monitoring <date>` and an availability alert.
8. If the default 19:00-21:00 watch rule matches a continuous available range, confirm macOS shows a `Court available` notification.
9. If a captcha appears, confirm the menu reports manual attention and macOS shows a `ZacksBar needs captcha` notification.
10. Click a notification with a page URL and confirm it opens the ydmap page in Chrome when Chrome is installed.

## 6. Check Diagnostics

1. Open `Settings and diagnostics...` from the ZacksBar menu.
2. Confirm the window shows:
   - Application Support path.
   - Latest State status.
   - Native Events status.
   - Native Host Manifest status.
   - Latest Message.
   - Parser Vue Root.
   - Parser Table.
   - Parser Rows.
   - Parser Slots.
   - Parser Available Slots.
3. Click Refresh after reloading the ydmap page.
4. Click Copy Report and paste it into a text editor to confirm it includes the same rows.

Parser row interpretation:

- `Parser Vue Root: missing`: the ydmap app has not mounted yet, or the page is outside the supported app shell.
- `Parser Table: missing`: Vue mounted, but the known schedule table component was not found.
- `Parser Rows: 0` or `Parser Slots: 0`: table was found, but schedule data has not loaded or ydmap markup/runtime changed.
- `Parser Available Slots: 0`: parsing worked, but no slots are currently available.

## 7. Inspect Boundaries

Before considering the smoke test complete, confirm:

- No credentials or cookies are written to repo files.
- URLs in fixtures and logs do not contain query strings with private identifiers.
- The app does not bypass captcha or submit a booking automatically.
- `latest-state.json` remains local runtime data and is not tracked by Git.
