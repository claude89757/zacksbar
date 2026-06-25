# Privacy

ZacksBar is designed around local monitoring. It should work with the user's existing Chrome session without collecting account credentials or automating final booking submission.

## Data ZacksBar Handles

- Supported ydmap booking page URLs after query strings and fragments are removed.
- Venue labels, court labels, date labels, and normalized availability slots.
- Captcha detection signals used to prompt the user to solve the captcha manually.
- Local watch rules configured by the user.
- Local setup health and diagnostic state.

## Data ZacksBar Must Not Handle

- ydmap passwords, cookies, session tokens, payment data, or government IDs.
- Raw booking-page query strings when they may contain identifiers.
- Captcha bypass data or third-party captcha-solving output.
- Final reservation submission without a direct user action.

## Local Storage

Swift core stores app support data under the user's Application Support directory. Development builds do not create cloud sync or remote telemetry. Future releases should keep telemetry opt-in and documented before adding it.

## Browser Boundary

The Chrome extension reads only supported ydmap booking pages declared in `extensions/chrome/manifest.json`. It communicates with the app through Chrome Native Messaging using the host name `com.zacksbar.native`.

## Automation Boundary

ZacksBar may open a page, focus a tab, switch date views, and preselect user-requested context where the page permits it. It must not bypass captcha, submit a booking, or hide meaningful manual confirmation steps.
