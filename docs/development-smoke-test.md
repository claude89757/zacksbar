# Development Smoke Test

Use this checklist after changing the Chrome extension, native host, protocol schemas, latest-state persistence, diagnostics, or menu bar app skeleton.

## 1. Run Automated Checks

```bash
npm test
cd apps/macos
swift test
swift build
```

Expected result:

- JavaScript parser and polling tests pass.
- Protocol fixtures validate against JSON schemas.
- Swift core tests pass, including latest-state persistence, diagnostics, and menu-state summarization.
- `ZacksBarApp` and `zacksbar-native-host` build.

## 2. Load The Chrome Extension

1. Open `chrome://extensions`.
2. Enable Developer mode.
3. Choose Load unpacked.
4. Select `extensions/chrome`.
5. Copy the extension ID.

## 3. Install Native Host Manifest

From the repository root:

```bash
./scripts/install-native-host.sh "$(pwd)/apps/macos/.build/debug/zacksbar-native-host" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
```

Replace the placeholder value with the unpacked extension ID from Chrome.

## 4. Start The App

```bash
cd apps/macos
swift run ZacksBarApp
```

Expected result:

- A `Z` menu bar item appears.
- The menu shows app status, setup actions, Refresh, and `Settings and diagnostics...`.

## 5. Exercise Browser Messaging

1. Open a supported ydmap booking page in Chrome.
2. Reload the page after the extension is installed.
3. Wait for the content script polling interval to inspect the page.
4. Confirm local latest state exists:

   ```bash
   cat "$HOME/Library/Application Support/ZacksBar/latest-state.json"
   ```

5. Click Refresh in the ZacksBar menu.
6. If availability was parsed, confirm the menu shows `Monitoring <date>` and an availability alert.
7. If a captcha appears, confirm the menu reports manual attention.

## 6. Check Diagnostics

1. Open `Settings and diagnostics...` from the ZacksBar menu.
2. Confirm the window shows:
   - Application Support path.
   - Latest State status.
   - Native Events status.
   - Native Host Manifest status.
   - Latest Message.
3. Click Refresh after reloading the ydmap page.
4. Click Copy Report and paste it into a text editor to confirm it includes the same rows.

## 7. Inspect Boundaries

Before considering the smoke test complete, confirm:

- No credentials or cookies are written to repo files.
- URLs in fixtures and logs do not contain query strings with private identifiers.
- The app does not bypass captcha or submit a booking automatically.
- `latest-state.json` remains local runtime data and is not tracked by Git.
