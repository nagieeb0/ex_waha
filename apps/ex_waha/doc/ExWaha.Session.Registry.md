# `ExWaha.Session.Registry`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/session/registry.ex#L1)

Process registry for `ExWaha.Session.Server` instances.

Registry key is a stable `{provider, account_key}` tuple so the same logical
account always resolves to the same server — even across restarts.

# `key`

```elixir
@spec key(struct()) :: term()
```

# `lookup`

```elixir
@spec lookup(struct()) :: {:ok, pid()} | :error
```

# `via`

```elixir
@spec via(struct()) :: {:via, Registry, {module(), term()}}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
