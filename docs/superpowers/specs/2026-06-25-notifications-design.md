# Notification Alerts Design

## Goal

Add the first production notification loop for ZacksBar: captcha events and matching available tennis slots should produce macOS notifications without spamming the user.

## Scope

This iteration implements notification decision logic, notification delivery, and browser opening from notification clicks. It does not add the full watch-rule settings UI yet. The app continues to use the existing default watch rule for 19:00-21:00 on the latest bookable day.

## Approach

Core owns pure notification decisions. Given a `LatestAppState`, watch rules, and the notification IDs already delivered in the current app session, Core returns zero or more `PendingNotification` values. The app layer owns macOS delivery through `UserNotifications` and browser opening through `NSWorkspace`.

This keeps notification behavior testable without macOS UI APIs and leaves the delivery mechanism replaceable for later signed release work.

## Notification Rules

Captcha notification:

- Trigger when `latestMessageType` is `captcha.detected` and `latestCaptcha` exists.
- Title: `ZacksBar needs captcha`.
- Body: `Open Chrome to finish verification.`
- Action URL: `payload.pageUrl`, if present and non-empty.
- Dedupe key: `captcha:<messageId>`.

Availability notification:

- Trigger when `latestAvailability` contains a continuous match for any watch rule.
- Title: `Court available`.
- Body includes court name, time range, and venue/date when present.
- Action URL: `payload.pageUrl`, if present and non-empty.
- Dedupe key: `availability:<messageId>:<ruleId>:<courtName>:<firstStart>-<lastEnd>`.

Non-matches do not notify. Parser diagnostics do not notify in this iteration; they stay diagnostic-only.

## Browser Opening

When a notification has an action URL, the app handles the notification click locally and opens the URL immediately. It first targets the installed Chrome application by bundle identifier (`com.google.Chrome`), then falls back to the user's default browser if Chrome is unavailable.

If no browser URL exists, the notification still appears, but clicking it has no page to open.

## UX Behavior

At launch and on manual Refresh, the app evaluates latest state once. When native messages are handled in-process later, the same evaluation path runs after the menu state updates.

The user should see:

- a captcha notification only once per captcha message;
- an availability notification only once per matched rule/message/range;
- menu text unchanged except for future refreshes showing current status.

## Privacy

Notifications avoid raw URLs, credentials, cookies, and query strings in visible text. The action URL uses the already-redacted page URL emitted by the content script.

## Testing

Core tests cover captcha decisions, availability decisions, non-matches, and dedupe behavior. App delivery is wired behind protocols so it can be tested without sending real macOS notifications or opening a real browser.
