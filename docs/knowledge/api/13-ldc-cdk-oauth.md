# LDC、CDK OAuth 与 LDC 打赏 API

LDC Credit and CDK use the same OAuth-style browser authorization shape, but their `user-info` payloads are different. The authorization page itself is hosted through `connect.linux.do`.

## 1. LDC OAuth

Base URL: `https://credit.linux.do`

### 1.1 Get Authorization URL

```http
GET https://credit.linux.do/api/v1/oauth/login
```

Response:

```json
{
  "data": "https://connect.linux.do/oauth2/authorize?..."
}
```

### 1.2 Load Authorization Page

```http
GET <authorization_url>
```

The response is HTML. Parse the approval link:

```html
<a href="/oauth2/approve/...">Approve</a>
```

### 1.3 Approve Authorization

```http
GET https://connect.linux.do/oauth2/approve/...
```

The successful response is a redirect. Read `code` and `state` from the `Location` URL.

### 1.4 OAuth Callback

```http
POST https://credit.linux.do/api/v1/oauth/callback
Content-Type: application/x-www-form-urlencoded
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---:|---|
| `code` | string | 是 | Authorization code from redirect |
| `state` | string | 是 | State from redirect |

### 1.5 User Info

```http
GET https://credit.linux.do/api/v1/oauth/user-info
```

Response:

```json
{
  "data": {
    "id": 1,
    "username": "example",
    "nickname": "昵称",
    "trust_level": 2,
    "avatar_url": "https://...",
    "total_receive": "100",
    "total_payment": "50",
    "total_transfer": "10",
    "total_community": "5",
    "community_balance": "3",
    "available_balance": "42",
    "pay_score": 80,
    "is_pay_key": false,
    "is_admin": false,
    "remain_quota": "100",
    "pay_level": 1,
    "daily_limit": 50,
    "gamification_score": 1234
  }
}
```

`401` or `403` means the OAuth authorization is expired or invalid.

### 1.6 Logout

```http
GET https://credit.linux.do/api/v1/oauth/logout
```

## 2. CDK OAuth

Base URL: `https://cdk.linux.do`

The OAuth flow is symmetric to LDC:

| Step | Endpoint |
|---|---|
| Get authorization URL | `GET https://cdk.linux.do/api/v1/oauth/login` |
| OAuth callback | `POST https://cdk.linux.do/api/v1/oauth/callback` |
| User info | `GET https://cdk.linux.do/api/v1/oauth/user-info` |
| Logout | `GET https://cdk.linux.do/api/v1/oauth/logout` |

CDK `user-info` response:

```json
{
  "data": {
    "id": 1,
    "username": "example",
    "nickname": "昵称",
    "trust_level": 2,
    "avatar_url": "https://...",
    "score": 100
  }
}
```

Do not reuse the LDC balance/payment fields for CDK. Only the OAuth flow shape is shared.

## 3. Connect HTML Stats

```http
GET https://connect.linux.do/
```

The Connect landing page can expose HTML cards and trust-level statistics. This is an HTML scraping surface, not a JSON API. Clients that implement it should treat CSS selectors as unstable and gracefully handle missing fields.

Observed useful selectors include:

| Selector | Meaning |
|---|---|
| `div.card` | Summary cards |
| `.tl3-ring` | Trust-level progress ring |
| `.tl3-bar-item` | Trust-level requirement bars |

## 4. LDC Reward

```http
POST https://credit.linux.do/epay/pay/distribute
Content-Type: application/json
Authorization: Basic <base64(client_id:client_secret)>
```

### Request Body

| 字段 | 类型 | 必填 | 说明 |
|---|---|---:|---|
| `user_id` | integer | 是 | Reward recipient user id |
| `username` | string | 是 | Reward recipient username |
| `amount` | number | 是 | Reward amount |
| `out_trade_no` | string | 是 | Client-generated unique trade number |
| `remark` | string | 否 | Optional remark |

`out_trade_no` must be unique for the merchant/client. A robust format should include the topic/post identity, timestamp, and random suffix.

### Response

Success-like response:

```json
{
  "data": {
    "trade_no": "server-trade-no"
  }
}
```

Failure response:

```json
{
  "error_msg": "error message"
}
```

Some failures use `msg` instead of `error_msg`. Clients should treat a response with `data` and no error message as successful, and otherwise surface `error_msg` or `msg`.

`401` indicates invalid Basic authentication credentials.
