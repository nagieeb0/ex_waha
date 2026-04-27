# `ExWaha.Api.Groups`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/api/groups.ex#L1)

WAHA group endpoints.

# `add_participants`

```elixir
@spec add_participants(ExWaha.Providers.Waha.Account.t(), String.t(), [String.t()]) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

# `create`

```elixir
@spec create(ExWaha.Providers.Waha.Account.t(), String.t(), [String.t()]) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

# `get`

```elixir
@spec get(ExWaha.Providers.Waha.Account.t(), String.t()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

# `leave`

```elixir
@spec leave(ExWaha.Providers.Waha.Account.t(), String.t()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

# `list`

```elixir
@spec list(ExWaha.Providers.Waha.Account.t()) ::
  {:ok, [map()]} | {:error, ExWaha.Error.t()}
```

# `remove_participants`

```elixir
@spec remove_participants(ExWaha.Providers.Waha.Account.t(), String.t(), [String.t()]) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
