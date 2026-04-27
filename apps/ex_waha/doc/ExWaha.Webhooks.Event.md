# `ExWaha.Webhooks.Event`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/webhooks/event.ex#L1)

Normalized webhook event.

WAHA and Meta send wildly different payloads — this struct is the lowest
common denominator that downstream code (handlers, LiveViews, Oban jobs)
works with. The raw provider payload is preserved for advanced cases.

# `kind`

```elixir
@type kind() ::
  :message
  | :message_ack
  | :message_reaction
  | :session_status
  | :group_update
  | :presence
  | :unknown
```

# `t`

```elixir
@type t() :: %ExWaha.Webhooks.Event{
  ack_status: nil | atom(),
  body: nil | String.t(),
  chat_id: nil | String.t(),
  from: nil | String.t(),
  kind: kind(),
  media: nil | map(),
  provider: :waha | :meta,
  raw: map(),
  session: nil | String.t(),
  timestamp: nil | DateTime.t(),
  to: nil | String.t()
}
```

# `from_meta`

```elixir
@spec from_meta(map()) :: [t()]
```

# `from_waha`

```elixir
@spec from_waha(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
