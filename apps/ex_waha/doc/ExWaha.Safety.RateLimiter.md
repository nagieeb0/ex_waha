# `ExWaha.Safety.RateLimiter`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/safety/rate_limiter.ex#L1)

Pure token-bucket rate limiter.

This module is data-only — caller threads the bucket through state. The
per-session `ExWaha.Session.Server` keeps one bucket per WhatsApp account.

Why per-account: WhatsApp's rate limits are tracked per phone number, not
per server. A global limiter would either over-throttle small tenants or
under-throttle big ones.

# `t`

```elixir
@type t() :: %ExWaha.Safety.RateLimiter{
  capacity: pos_integer(),
  last_refill: integer(),
  refill_per_second: float(),
  tokens: float()
}
```

# `new`

```elixir
@spec new(pos_integer(), float()) :: t()
```

# `resize`

```elixir
@spec resize(t(), pos_integer(), float()) :: t()
```

# `take`

```elixir
@spec take(t(), pos_integer()) :: {:ok, t()} | {:error, non_neg_integer(), t()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
