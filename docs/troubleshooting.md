# Troubleshooting

## Start With Diagnostics

Open `Settings and diagnostics...` from the ZacksBar menu.

Check these rows first:

- `Native Host Manifest`: should show a byte size, not `missing`.
- `Latest State`: should show a byte size after Chrome sends a supported message.
- `Native Events`: should show a byte size after any native message arrives.
- `Latest Message`: should be `health.ping`, `availability.updated`, or `captcha.detected`.

Use Copy Report when sharing an issue. The report includes local paths and status labels, but not cookies or credentials.

## Chrome Cannot Connect To Native Host

Check that the native host manifest exists:

```bash
ls "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.zacksbar.native.json"
```

Reinstall it with the extension ID from `chrome://extensions`:

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

## Availability Alerts Do Not Match

- Verify the watch rule date and time range use the same labels as the parsed page snapshot.
- Prefer continuous time ranges that match slot boundaries shown on the ydmap page.
- Open diagnostics and confirm `Latest Message` is `availability.updated`.
- Inspect `~/Library/Application Support/ZacksBar/latest-state.json` if the menu status does not match the page.

## Tests

Run the JavaScript and Swift test suites before reporting a bug:

```bash
npm test
cd apps/macos
swift test
swift build
```
