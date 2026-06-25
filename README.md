# ZacksBar

ZacksBar is a macOS menu bar product for monitoring ydmap tennis court availability from Chrome and alerting the user when manual attention is needed.

The v1 architecture is:

```text
ydmap booking page
  -> Chrome MV3 content script
  -> Chrome extension service worker
  -> Chrome Native Messaging
  -> ZacksBar Native Host
  -> Swift macOS menu bar app
```

This repository currently contains the product skeleton plus the first live pipeline: the Chrome companion can read ydmap Vue schedule state, emit deduped parser/availability/captcha events, the native host can persist latest local state, and the menu bar app can display, diagnose, and notify on that state.

## Scope

- Native macOS menu bar app built with Swift.
- Chrome MV3 companion extension.
- Chrome Native Messaging bridge.
- ydmap tennis court availability monitoring.
- Captcha and availability alerts.
- Semi-automated page opening and prefill only.

ZacksBar does not submit reservations, bypass captcha, store credentials, or modify local Tampermonkey scripts.

## Development

Run JavaScript and protocol checks:

```bash
npm test
```

Run Swift checks:

```bash
cd apps/macos
swift test
swift build
```

Load the Chrome extension from `extensions/chrome`, start `ZacksBarApp`, then open `Setup Assistant...` from the menu bar item. Paste the Chrome extension ID and choose `Install Native Host`. The setup assistant also shows the loaded browser companion version and can queue a `Reload Browser Extension` command for the next Chrome native messaging connection.

The app asks macOS for notification permission on launch. Captcha notifications and matching availability notifications include the latest supported ydmap page URL; clicking the notification opens it in Chrome when Chrome is installed.

Use `Alert Settings...` from the menu bar item to change the primary availability alert rule. `Use Current Page` fills Start and End from the latest parsed page state, then Save stores the rule locally and applies it.

The script remains available as a development fallback:

```bash
./scripts/install-native-host.sh "$(pwd)/apps/macos/.build/debug/zacksbar-native-host" "<chrome-extension-id>"
```

See [docs/development-smoke-test.md](docs/development-smoke-test.md) for the full local smoke test.

Local native state is written under:

```text
~/Library/Application Support/ZacksBar/
```

Important local files include `latest-state.json` for browser state, `watch-rules.json` for alert settings, and `native-commands.jsonl` for short-lived queued browser commands. Use `Settings and diagnostics...` from the menu bar item to inspect local bridge state and copy a report for bug reports.

## Documentation

- [Architecture](docs/architecture.md)
- [Install](docs/install.md)
- [Privacy](docs/privacy.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Contributing](docs/contributing.md)

## Design

See [docs/superpowers/specs/2026-06-25-zacksbar-design.md](docs/superpowers/specs/2026-06-25-zacksbar-design.md).

## License

MIT
