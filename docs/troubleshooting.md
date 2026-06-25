# Troubleshooting

## Start With Diagnostics

Open `Settings and diagnostics...` from the ZacksBar menu.

Check these rows first:

- `Native Host Manifest`: should show a byte size, not `missing`.
- `Latest State`: should show a byte size after Chrome sends a supported message.
- `Native Events`: should show a byte size after any native message arrives.
- `Latest Message`: should be `health.ping`, `parser.diagnostics`, `availability.updated`, or `captcha.detected`.
- `Parser Vue Root`: should be `found` after the ydmap app mounts.
- `Parser Table`: should be `found` on a supported booking schedule page.
- `Parser Slots`: should be greater than `0` after schedule data loads.

Use Copy Report when sharing an issue. The report includes local paths and status labels, but not cookies or credentials.

## Chrome Cannot Connect To Native Host

Open `Setup Assistant...`, paste the extension ID from `chrome://extensions`, and choose `Install Native Host`.

Then check that the native host manifest exists:

```bash
ls "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.zacksbar.native.json"
```

Script fallback:

```bash
./scripts/install-native-host.sh "$(pwd)/apps/macos/.build/debug/zacksbar-native-host" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
```

The extension ID must be the unpacked extension ID shown by Chrome. Chrome Native Messaging rejects all other origins.

## Native Host Path Is Wrong

Build the Swift package and reinstall the manifest with the absolute host path:

```bash
cd apps/macos
swift build
cd ../..
./scripts/install-native-host.sh "$(pwd)/apps/macos/.build/debug/zacksbar-native-host" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
```

## Captcha Alerts Do Not Appear

- Confirm the ydmap page URL matches the extension host permissions in `extensions/chrome/manifest.json`.
- Confirm the companion extension is enabled in `chrome://extensions`.
- Reload the ydmap booking page after loading or updating the extension.
- Confirm Chrome can connect to `com.zacksbar.native`.
- Confirm macOS notification permission is enabled for ZacksBar in System Settings.
- Open diagnostics and confirm `Latest Message` is `captcha.detected`.

## Availability Alerts Do Not Match

- Verify the watch rule date and time range use the same labels as the parsed page snapshot.
- Prefer continuous time ranges that match slot boundaries shown on the ydmap page.
- The current default watch rule is 19:00-21:00 on the latest bookable day.
- Open diagnostics and confirm `Latest Message` is `availability.updated`.
- If `Latest Message` is only `parser.diagnostics`, check `Parser Table`, `Parser Rows`, and `Parser Slots` to see where parsing stopped.
- Inspect `~/Library/Application Support/ZacksBar/latest-state.json` if the menu status does not match the page.

## Notification Click Does Not Open Chrome

- Confirm the notification included a page URL by checking `latest-state.json` for `payload.pageUrl`.
- Confirm Google Chrome is installed. ZacksBar targets Chrome by bundle identifier and falls back to the default browser if Chrome is unavailable.
- If no browser opens, quit and restart `ZacksBarApp` so it can become the notification center delegate again.

## Tests

Run the JavaScript and Swift test suites before reporting a bug:

```bash
npm test
cd apps/macos
swift test
swift build
```
