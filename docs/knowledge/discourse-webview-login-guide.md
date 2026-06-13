# Discourse Browser Login Guide

LinuxDo authentication is browser-oriented Discourse authentication. A client
should not reimplement the login form as a private JSON API. Use a browser-capable
surface, let Discourse and its identity providers complete the flow, then share
the resulting cookies with the programmatic HTTP client.

## 1. Goals

The login boundary must produce:

- Valid cookies for `https://linux.do`, especially `_t` and `_forum_session`
- Any Cloudflare clearance cookie such as `cf_clearance`
- A browser-compatible user agent for subsequent requests
- A current user verified by `GET /session/current.json` or bootstrap HTML
- A CSRF token from bootstrap HTML or `GET /session/csrf`

## 2. Why Browser Login

Discourse login can include:

- Password login
- Email login links
- OAuth providers
- WebAuthn / PassKey
- hCaptcha / Turnstile
- Cloudflare challenge pages
- Server-side form and route changes

Treating the official browser flow as the authoritative login surface keeps clients resilient to server-side changes.

## 3. Cookie Stores

A typical client has two cookie stores:

| Store | Owner | Purpose |
|---|---|---|
| Browser/WebView cookie store | Browser-capable login surface | Receives cookies from HTML login, OAuth, PassKey, and Cloudflare |
| HTTP client cookie store | Programmatic API layer | Sends cookies for JSON API, uploads, MessageBus, and bootstrap |

Required synchronization:

- Browser to HTTP after successful login.
- Browser to HTTP after Cloudflare challenge completion.
- HTTP to browser before opening login/challenge pages if the HTTP layer has fresher cookies.

Preserve cookie attributes where available: domain, path, expiry, Secure,
HttpOnly, and SameSite. If a platform exposes only name/value cookies, treat the
result as lower confidence and verify with `/session/current.json`.

## 4. Login Flow

1. Open `https://linux.do/login` or the target Discourse URL in a browser-capable surface.
2. Let the user complete the official login flow.
3. Wait until the page indicates an authenticated state or session cookies appear.
4. Copy cookies for `https://linux.do` into the HTTP client cookie store.
5. Request `GET /session/current.json` or parse authenticated bootstrap HTML.
6. If a current user is returned, treat login as successful.
7. Fetch or cache CSRF before the first mutating request.

Do not treat a single navigation URL as sufficient proof of login. The durable proof is a valid current-user response with the synchronized cookies.

## 5. Email Login Links And Deep Links

Email login links should be opened in the same browser-capable login surface when possible. If the operating system delivers a deep link to the app:

1. Validate that the URL belongs to the expected Discourse host.
2. Load it in the login browser surface.
3. Synchronize cookies after the flow completes.
4. Verify with `/session/current.json`.

## 6. CSRF After Login

After login, obtain CSRF from one of:

- Bootstrap HTML `<meta name="csrf-token">`
- `GET /session/csrf`

Use `X-CSRF-Token` on mutating Discourse requests. If a request returns `BAD CSRF`, refresh the token and retry once.

## 7. Cloudflare Challenge

Cloudflare challenge responses are not Discourse API errors. They indicate that a browser-capable challenge flow is required.

Recommended handling:

1. Detect challenge HTML or Cloudflare headers on a foreground request.
2. Open a browser-capable surface on the challenged URL or `https://linux.do/challenge`.
3. Let the user complete the challenge.
4. Copy `cf_clearance` and related cookies into the HTTP client cookie store.
5. Retry the original foreground request once if it is still relevant.

Background or long-polling requests should not steal focus for a challenge page. They should fail softly or wait for a later foreground challenge completion.

## 8. Session Validation And Logout

Use `/session/current.json` as the authority for current login state.

Recommended invalidation policy:

- Strong signals: `not_logged_in`, `401/403` with `discourse-logged-out`
- Weak signals: successful responses with `discourse-logged-out`
- Inconclusive: network failures, timeouts, Cloudflare challenge, ordinary `403 invalid_access`

Before clearing local identity state, validate strong/accumulated weak signals with `/session/current.json` when possible. Preserve `cf_clearance` across ordinary logout.

## 9. Cookie Replay Before Browser Flows

Before opening a browser login, challenge, or account page, replay current HTTP
cookies into the browser cookie store when possible. This avoids presenting a
stale anonymous browser session while the API layer is still logged in.

Replay source priority:

1. Raw `Set-Cookie` entries captured from HTTP responses.
2. Structured cookie records stored by the HTTP client.
3. Name/value fallback records, only when no richer attributes are available.

## 10. Security Requirements

- Store credentials only in platform-secure storage if the product supports autofill.
- Never log `_t`, `_forum_session`, `cf_clearance`, CSRF, OAuth `code`, or OAuth `state`.
- Restrict cookie synchronization to trusted LinuxDo origins.
- Reject deep links that do not match the expected scheme, host, and path family.
- Keep browser login separate from arbitrary untrusted web browsing.

## 11. Platform-Owned Details

The exact APIs for reading browser cookies, writing cookies back, handling
WebAuthn, or opening challenge pages differ by operating system and runtime.
Those details belong in implementation documentation. The backend-visible
contract remains:

1. Complete login/challenge in a browser-capable surface.
2. Synchronize cookies for `https://linux.do`.
3. Verify current user via Discourse session APIs.
4. Use CSRF for mutating requests.
