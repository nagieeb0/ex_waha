# `ExWaha.Api.Chats`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/api/chats.ex#L1)

WAHA chat endpoints.

# `archive`

```elixir
@spec archive(ExWaha.Providers.Waha.Account.t(), ExWaha.Recipient.t() | String.t()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

# `delete`

```elixir
@spec delete(ExWaha.Providers.Waha.Account.t(), ExWaha.Recipient.t() | String.t()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

# `list`

```elixir
@spec list(
  ExWaha.Providers.Waha.Account.t(),
  keyword()
) :: {:ok, [map()]} | {:error, ExWaha.Error.t()}
```

# `messages`

```elixir
@spec messages(
  ExWaha.Providers.Waha.Account.t(),
  ExWaha.Recipient.t() | String.t(),
  keyword()
) ::
  {:ok, [map()]} | {:error, ExWaha.Error.t()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
