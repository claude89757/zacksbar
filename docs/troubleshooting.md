# Troubleshooting

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
- Use the diagnostic view once available to compare the latest parsed snapshot with the configured rule.

## Tests

Run the JavaScript and Swift test suites before reporting a bug:

```bash
npm test
cd apps/macos
swift test
swift build
```
