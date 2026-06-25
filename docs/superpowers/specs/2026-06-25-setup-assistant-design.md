# Setup Assistant Design

## Goal

Reduce first-run setup friction. Users should be able to load the Chrome extension manually, paste its extension ID once, install the native host manifest from ZacksBar, and immediately see setup health.

## Scope

- Add Swift core native host manifest installer.
- Validate Chrome extension IDs before writing manifest files.
- Add a setup checklist model that reports extension ID, native host executable, manifest, and latest state health.
- Add a native AppKit setup assistant window opened from the menu.
- Keep diagnostics available from the setup window.

Out of scope:

- Automatically installing the Chrome extension.
- Reading Chrome private preferences to discover extension IDs.
- Modifying Chrome profile files.
- Codesigned release packaging.
- Watch-rule setup UX.

## Setup Flow

1. User opens `Setup Assistant...` from the menu.
2. Window shows a short checklist:
   - Chrome extension loaded.
   - Extension ID entered.
   - Native host executable found.
   - Native host manifest installed.
   - Latest browser state received.
3. User pastes the Chrome extension ID from `chrome://extensions`.
4. User clicks `Install Native Host`.
5. ZacksBar writes `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.zacksbar.native.json`.
6. User reloads ydmap page and clicks Refresh.

## User Experience

The window is a quiet macOS utility surface. It should avoid long instructional prose and focus on state, actions, and copyable paths. The assistant can open `chrome://extensions` and `docs/development-smoke-test.md` later, but this iteration only needs functional install and refresh.

## Testing

- Unit tests validate extension ID format.
- Unit tests validate manifest writing and allowed origin.
- Unit tests validate setup checklist states before and after manifest/latest state exist.
- `swift build` verifies AppKit setup window compiles.
