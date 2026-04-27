# `ExWaha.Api.Presence`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/api/presence.ex#L1)

WAHA presence endpoints.

# `set`

```elixir
@spec set(ExWaha.Providers.Waha.Account.t(), :online | :offline) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

# `start_typing`

```elixir
@spec start_typing(
  ExWaha.Providers.Waha.Account.t(),
  ExWaha.Recipient.t() | String.t()
) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

# `stop_typing`

```elixir
@spec stop_typing(
  ExWaha.Providers.Waha.Account.t(),
  ExWaha.Recipient.t() | String.t()
) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
