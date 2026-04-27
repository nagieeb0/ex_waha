# `ExWaha.Provider`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/provider.ex#L1)

Behaviour every WhatsApp provider implements.

The facade (`ExWaha`) dispatches by inspecting the account struct's module's
`provider/0` callback (set via `use ExWaha.Provider, ...`) — but in practice
we keep it explicit by pattern-matching on the account struct in `dispatch/2`.

# `account`

```elixir
@type account() :: struct()
```

# `recipient`

```elixir
@type recipient() :: ExWaha.Recipient.t() | String.t()
```

# `result`

```elixir
@type result(t) :: {:ok, t} | {:error, ExWaha.Error.t()}
```

# `parse_event`

```elixir
@callback parse_event(account(), map()) ::
  {:ok, [ExWaha.Webhooks.Event.t()]} | {:error, term()}
```

# `send_media`
*optional* 

```elixir
@callback send_media(account(), recipient(), map(), keyword()) :: result(map())
```

# `send_template`
*optional* 

```elixir
@callback send_template(account(), recipient(), String.t(), keyword()) :: result(map())
```

# `send_text`

```elixir
@callback send_text(account(), recipient(), String.t(), keyword()) :: result(map())
```

# `verify_signature`

```elixir
@callback verify_signature(account(), binary(), [{String.t(), String.t()}]) :: boolean()
```

# `provider_for!`

```elixir
@spec provider_for!(account()) :: module()
```

Look up the provider module for an account struct.

# `send_media`

```elixir
@spec send_media(account(), recipient(), map(), keyword()) :: result(map())
```

# `send_template`

```elixir
@spec send_template(account(), recipient(), String.t(), keyword()) :: result(map())
```

# `send_text`

```elixir
@spec send_text(account(), recipient(), String.t(), keyword()) :: result(map())
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
