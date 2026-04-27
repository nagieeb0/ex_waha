# `ExWaha.Recipient`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/recipient.ex#L1)

Normalized recipient handle.

Different providers expect different chat-id formats. This struct captures the
canonical phone number plus an optional WAHA-style chat id, and provides
helpers to render the right shape per provider.

WAHA expects `<digits>@c.us` for users and `<id>@g.us` for groups. Meta Cloud
API expects E.164 digits without `+`.

# `t`

```elixir
@type t() :: %ExWaha.Recipient{
  chat_id: nil | String.t(),
  phone: String.t(),
  type: :user | :group
}
```

# `group`

```elixir
@spec group(String.t()) :: t()
```

Build a group `Recipient` from a WAHA group id.

    iex> ExWaha.Recipient.group("123-456")
    %ExWaha.Recipient{phone: "123-456", chat_id: "123-456@g.us", type: :group}

# `new`

```elixir
@spec new(String.t() | t()) :: t()
```

Build a user `Recipient` from a phone string. Non-digits are stripped.

    iex> ExWaha.Recipient.new("+20 (100) 123-4567")
    %ExWaha.Recipient{phone: "201001234567", chat_id: "201001234567@c.us", type: :user}

Already-built `Recipient` structs pass through unchanged.

# `to_meta`

```elixir
@spec to_meta(t()) :: String.t()
```

Render the recipient as plain digits for the Meta Cloud API.

# `to_waha`

```elixir
@spec to_waha(t()) :: String.t()
```

Render the recipient in WAHA's `<id>@c.us` / `<id>@g.us` format.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
