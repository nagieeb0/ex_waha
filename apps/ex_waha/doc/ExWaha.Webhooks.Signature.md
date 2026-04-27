# `ExWaha.Webhooks.Signature`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/webhooks/signature.ex#L1)

HMAC signature verification for webhook payloads.

  * WAHA — `HMAC-SHA512(body, secret)` hex digest in the `X-Webhook-Hmac` header.
  * Meta — `sha256=` + `HMAC-SHA256(body, app_secret)` hex digest in the
    `X-Hub-Signature-256` header.

Constant-time comparison via `:crypto.hash_equals/2` to prevent timing
attacks. Raw request body must be preserved (Plug strips it by default —
use a `body_reader` to capture).

# `verify_meta_sha256`

```elixir
@spec verify_meta_sha256(binary(), nil | String.t(), String.t()) :: boolean()
```

# `verify_sha512`

```elixir
@spec verify_sha512(binary(), nil | String.t(), String.t()) :: boolean()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
