# `ExWaha.Api.Messages`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/api/messages.ex#L1)

Message-sending endpoints for WAHA.

Note: passing through `ExWaha.SafeSend` is strongly recommended over calling
these directly — the safe layer enforces rate limits, warmup, and jitter.

# `send_location`

```elixir
@spec send_location(
  ExWaha.Providers.Waha.Account.t(),
  ExWaha.Recipient.t() | String.t(),
  map()
) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

# `send_media`

```elixir
@spec send_media(
  ExWaha.Providers.Waha.Account.t(),
  ExWaha.Recipient.t() | String.t(),
  map(),
  keyword()
) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

# `send_seen`

```elixir
@spec send_seen(ExWaha.Providers.Waha.Account.t(), ExWaha.Recipient.t() | String.t()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

# `send_text`

```elixir
@spec send_text(
  ExWaha.Providers.Waha.Account.t(),
  ExWaha.Recipient.t() | String.t(),
  String.t(),
  keyword()
) :: {:ok, map()} | {:error, ExWaha.Error.t()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
