# Development Smoke Test

Use this checklist after changing the Chrome extension, native host, protocol schemas, or menu bar app skeleton.

## 1. Run Automated Checks

```bash
npm test
cd apps/macos
swift test
swift build
```

Expected result:

- JavaScript parser tests pass.
- Protocol fixtures validate against JSON schemas.
- Swift core tests pass.
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
- The menu shows app status and setup actions.

## 5. Exercise Browser Messaging

1. Open a supported ydmap booking page in Chrome.
2. Reload the page after the extension is installed.
3. If a captcha appears, confirm ZacksBar reports manual attention.
4. Confirm the app can offer a jump action back to the relevant browser page as that flow is implemented.

## 6. Inspect Boundaries

Before considering the smoke test complete, confirm:

- No credentials or cookies are written to repo files.
- URLs in fixtures and logs do not contain query strings with private identifiers.
- The app does not bypass captcha or submit a booking automatically.
