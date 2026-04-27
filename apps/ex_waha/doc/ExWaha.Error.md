# `ExWaha.Error`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/error.ex#L1)

Normalized error returned by every ExWaha call.

Reasons:

  * `:rate_limited` — local token bucket refused the call (back off and retry).
  * `:session_not_started` — provider session is not in a sendable state.
  * `:invalid_recipient` — recipient is not on WhatsApp or wrong format.
  * `:unauthorized` — bad API key / access token.
  * `:forbidden` — likely policy violation (template required, 24h window).
  * `:account_banned` — provider says this number is banned.
  * `:network` — transport failure (timeout, DNS, etc.).
  * `:server_error` — provider returned 5xx.
  * `:unknown` — fallback.

# `reason`

```elixir
@type reason() ::
  :rate_limited
  | :session_not_started
  | :invalid_recipient
  | :unauthorized
  | :forbidden
  | :account_banned
  | :network
  | :server_error
  | :unknown
```

# `t`

```elixir
@type t() :: %ExWaha.Error{
  __exception__: true,
  body: any(),
  message: String.t(),
  reason: reason(),
  retry_after_ms: nil | non_neg_integer(),
  status: nil | non_neg_integer()
}
```

# `from_status`

```elixir
@spec from_status(non_neg_integer(), any()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
