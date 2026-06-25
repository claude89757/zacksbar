# Contributing

ZacksBar is a Swift macOS app plus Chrome MV3 extension. Keep changes small, testable, and aligned with the privacy and automation boundaries documented in this repository.

## Prerequisites

- macOS with Xcode command line tools.
- Swift package manager from the installed Xcode toolchain.
- Node.js 20 or newer.
- Chrome for local extension testing.

## Repository Layout

- `apps/macos`: Swift package containing the menu bar app, shared core, and native host.
- `extensions/chrome`: Chrome companion extension.
- `packages/protocol`: JSON schemas and fixtures shared across the browser/native boundary.
- `scripts`: local development and install helpers.
- `docs`: architecture, setup, privacy, and troubleshooting notes.

## Development Checks

```bash
npm test
cd apps/macos
swift test
swift build
```

Run the relevant subset while iterating, then run all checks before opening a pull request.

## Change Guidelines

- Add or update protocol fixtures when changing message shapes.
- Keep content-script parsing defensive because ydmap markup can change.
- Redact URLs and identifiers before data crosses process boundaries.
- Do not add credential storage, captcha bypassing, or automatic final booking submission.
- Prefer native macOS APIs for menu bar, notification, and setup flows.

## Release Direction

Future releases should package the macOS app, native host, and extension assets together. The extension ID and native host manifest installation flow must remain explicit and diagnosable.
