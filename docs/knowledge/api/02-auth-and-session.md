# 认证与会话 API

LinuxDo 使用 Discourse 的 Cookie 会话认证。官方登录流程运行在网页中；第三方客户端通常应通过浏览器或 WebView 完成登录、Cloudflare challenge、OAuth、PassKey 等交互，然后把得到的站点 Cookie 同步给程序化 HTTP 客户端。

## 1. 当前会话

```http
GET /session/current.json
```

用于验证当前 Cookie 是否对应一个有效登录用户。

### Query Parameters

| 参数 | 类型 | 必填 | 说明 |
|---|---|---:|---|
| `_` | integer | 否 | 防缓存时间戳 |

### Request

```http
GET https://linux.do/session/current.json
Accept: application/json, text/javascript, */*; q=0.01
Cookie: _t=...; _forum_session=...
```

This endpoint does not require a CSRF token.

### Response

Authenticated response:

```json
{
  "current_user": {
    "id": 12345,
    "username": "example",
    "name": "Example User",
    "avatar_template": "/user_avatar/linux.do/example/{size}/1.png",
    "trust_level": 2
  }
}
```

Unauthenticated or invalid sessions can appear as:

- `404`
- `401` / `403`
- `200` with no `current_user`
- A structured error body such as `{"error_type":"not_logged_in"}`

Recommended normalization:

| Result | Meaning |
|---|---|
| `current_user` object exists | Session is valid |
| `404`, `not_logged_in`, or no `current_user` | Session is invalid |
| Network failure, Cloudflare challenge, timeout | Session state is inconclusive; do not destructively log out based on this result alone |

## 2. Conservative Session Probe

Use `GET /session/current.json` as the authority before clearing local session state.

Recommended policy:

- Treat `not_logged_in` and `401/403` responses with `discourse-logged-out` as strong invalid-session signals.
- Treat successful responses that include `discourse-logged-out` as weak signals.
- Do not log out solely because of `BAD CSRF`, ordinary `403 invalid_access`, a Cloudflare challenge, or a transient network error.
- Fold concurrent probes so multiple failing requests trigger only one session verification.
- Keep `cf_clearance` when clearing a user session; it is a Cloudflare clearance cookie, not a Discourse identity cookie.

This is a client policy recommendation. The backend authority remains the `/session/current.json` response.

## 3. CSRF Token

```http
GET /session/csrf
```

Fetches a CSRF token suitable for mutating Discourse requests.

### Request

```http
GET https://linux.do/session/csrf
Accept: application/json, text/javascript, */*; q=0.01
Cookie: _forum_session=...; _t=...
```

### Response

```json
{
  "csrf": "xxxxxxxxxxxxxxxxxxxx"
}
```

### Strategy

| Case | Recommended handling |
|---|---|
| Bootstrap HTML has `<meta name="csrf-token">` | Cache that token |
| No cached token before a mutating request | Fetch `/session/csrf` |
| `403` body contains `BAD CSRF` | Clear cached token, fetch a new token, retry the original request once |
| `/session/csrf` succeeds but response includes `discourse-logged-out` | Keep the token but verify session separately before destructive logout |

## 4. Logout

```http
DELETE /session/{username}
```

Logs out the current Discourse session on the server.

### Path Parameters

| 参数 | 类型 | 必填 | 说明 |
|---|---|---:|---|
| `username` | string | 是 | 当前登录用户名 |

### Request

```http
DELETE https://linux.do/session/example
X-CSRF-Token: <csrf token>
Cookie: _t=...; _forum_session=...
```

### Response

Discourse logout responses vary by server version and plugin state. Clients should treat any `2xx` response as successful logout and then clear local identity cookies such as `_t` and `_forum_session`. Preserve unrelated cookies such as `cf_clearance` unless the user requested a full site-data reset.

## 5. Login Boundary

Login itself is not a stable JSON API contract for third-party clients. The robust path is:

1. Open the Discourse login URL in a browser-capable context.
2. Let the server handle password login, OAuth, PassKey, hCaptcha, and Cloudflare challenge pages.
3. After navigation indicates a logged-in state, copy cookies for `https://linux.do` into the HTTP client cookie store.
4. Validate with `GET /session/current.json`.
5. Fetch CSRF before mutating requests.

See [../discourse-webview-login-guide.md](../discourse-webview-login-guide.md) for the stack-neutral browser-login protocol notes.
