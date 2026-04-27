# `ExWahaNative.Account`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.2.0/lib/ex_waha_native/account.ex#L1)

An account on the native (whatsmeow) provider.

Unlike `ExWaha.Providers.Waha.Account` there is no remote server URL;
the Go binary runs locally inside the BEAM node. Sessions are identified
by their `session_name`.

# `t`

```elixir
@type t() :: %ExWahaNative.Account{
  bridge: GenServer.name(),
  session: String.t(),
  store: nil | {:sqlite, String.t()} | {:postgres, keyword()}
}
```

# `new`

```elixir
@spec new(keyword()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
