# ZacksBar

ZacksBar is a macOS menu bar product for monitoring ydmap tennis court availability from Chrome and alerting the user when manual attention is needed.

The planned v1 architecture is:

```text
ydmap booking page
  -> Chrome MV3 content script
  -> Chrome extension service worker
  -> Chrome Native Messaging
  -> ZacksBar Native Host
  -> Swift macOS menu bar app
```

The initial repository currently contains the approved product design spec. Implementation planning and scaffolding will follow after review.

## Scope

- Native macOS menu bar app built with Swift.
- Chrome MV3 companion extension.
- Chrome Native Messaging bridge.
- ydmap tennis court availability monitoring.
- Captcha and availability alerts.
- Semi-automated page opening and prefill only.

ZacksBar does not submit reservations, bypass captcha, store credentials, or modify local Tampermonkey scripts.

## Design

See [docs/superpowers/specs/2026-06-25-zacksbar-design.md](docs/superpowers/specs/2026-06-25-zacksbar-design.md).

## License

MIT
